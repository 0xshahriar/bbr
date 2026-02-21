
run_url_discovery() {
    local input="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/urls.txt"
    local temp_dir="$OUTPUT_DIR/$TARGET_SAFE/temp"

    mkdir -p "$temp_dir"
    check_time_window || return
    progress "Running URL discovery..."
    save_state "URL_DISCOVERY_START"

    cut -d' ' -f1 "$input" | sed 's|https\?://||' | sort -u > "$temp_dir/hosts.txt"

    local proxy_args=$(build_proxy_args)
    local ua=$(get_random_ua)

    if should_run_tool "gau" || should_run_tool "all"; then
        progress "Running gau..."
        cat "$temp_dir/hosts.txt" | gau --threads 5 --timeout 15 $proxy_args 2>/dev/null | sort -u > "$temp_dir/urls_gau.txt" &
    fi

    if should_run_tool "waybackurls" || should_run_tool "all"; then
        progress "Running waybackurls..."
        cat "$temp_dir/hosts.txt" | waybackurls 2>/dev/null | sort -u > "$temp_dir/urls_wayback.txt" &
    fi

    if should_run_tool "katana" || should_run_tool "all"; then
        progress "Running katana..."
        katana -list "$temp_dir/hosts.txt" -silent -t "$RATE_LIMIT_KATANA" \
            -timeout "$TIMEOUT" -jc -H "User-Agent: $ua" $proxy_args 2>/dev/null | sort -u > "$temp_dir/urls_katana.txt" &
    fi

    wait
    add_jitter

    cat "$temp_dir"/urls_*.txt 2>/dev/null | sort -u > "$output"

    if check_tool "uro" && [[ -s "$output" ]]; then
        progress "Filtering URLs with uro..."
        cat "$output" | uro > "$temp_dir/filtered.txt"
        mv "$temp_dir/filtered.txt" "$output"
    fi

    if check_tool "gf" && [[ -s "$output" ]]; then
        progress "Running gf patterns..."
        mkdir -p "$OUTPUT_DIR/$TARGET_SAFE/gf"

        if [[ ! -d "$HOME/.gf" || -z "$(ls -A "$HOME/.gf" 2>/dev/null)" ]]; then
            log_info "Installing gf patterns from tomnomnom/gf..."
            local gf_src="$HOME/go/pkg/mod/github.com/tomnomnom/gf@*/examples"
            mkdir -p "$HOME/.gf"
            for d in $HOME/go/pkg/mod/github.com/tomnomnom/gf*/examples; do
                [[ -d "$d" ]] && cp "$d"/*.json "$HOME/.gf/" 2>/dev/null
            done
            if [[ -z "$(ls -A "$HOME/.gf" 2>/dev/null)" ]]; then
                git clone --depth=1 https://github.com/tomnomnom/gf /tmp/gf_src 2>/dev/null \
                    && cp /tmp/gf_src/examples/*.json "$HOME/.gf/" 2>/dev/null \
                    && rm -rf /tmp/gf_src
            fi
        fi

        local gf_found=0
        for pattern in xss sqli ssrf lfi rce redirect idor debug-pages s3-buckets; do
            local gf_out="$OUTPUT_DIR/$TARGET_SAFE/gf/${pattern}.txt"
            gf "$pattern" < "$output" > "$gf_out" 2>/dev/null
            local cnt=$(wc -l < "$gf_out" 2>/dev/null || echo 0)
            if [[ $cnt -gt 0 ]]; then
                log_success "gf $pattern: $cnt matches"
                gf_found=$((gf_found + cnt))
            else
                rm -f "$gf_out"
            fi
        done
        [[ $gf_found -eq 0 ]] && log_warning "gf: no pattern matches found in collected URLs"
    fi

    apply_filters "$output" "$output"

    local count=$(wc -l < "$output" 2>/dev/null || echo "0")
    log_success "Found $count unique URLs"
    save_state "URL_DISCOVERY_DONE"
    rm -rf "$temp_dir"
}

run_smart_scan() {
    local input="$1"

    if [[ -s "$OUTPUT_DIR/$TARGET_SAFE/wp_hosts.txt" ]]; then
        if should_run_tool "wpprobe" || [[ -z "$TECH_FILTER" || "$TECH_FILTER" == *"wordpress"* ]]; then
            progress "WordPress detected! Running wpprobe..."
            local wp_output="$OUTPUT_DIR/$TARGET_SAFE/wordpress_scan.txt"

            while read url; do
                local clean_url=$(echo "$url" | cut -d' ' -f1)
                wpprobe scan "$clean_url" 2>/dev/null >> "$wp_output"
            done < "$OUTPUT_DIR/$TARGET_SAFE/wp_hosts.txt"

            log_success "WordPress scan complete"
            send_notification "WordPress vulnerabilities found for $TARGET" "medium"
        fi
    fi

    if [[ -s "$OUTPUT_DIR/$TARGET_SAFE/graphql_hosts.txt" ]]; then
        if [[ -z "$TECH_FILTER" || "$TECH_FILTER" == *"graphql"* ]]; then
            progress "GraphQL detected! Running introspection checks..."
            local gql_output="$OUTPUT_DIR/$TARGET_SAFE/graphql_scan.txt"

            while read url; do
                local clean_url=$(echo "$url" | cut -d' ' -f1)
                curl -s -X POST "$clean_url" \
                    -H "Content-Type: application/json" \
                    -d '{"query":"{__schema{types{name}}}"}' 2>/dev/null | jq . 2>/dev/null >> "$gql_output"
            done < "$OUTPUT_DIR/$TARGET_SAFE/graphql_hosts.txt"

            log_success "GraphQL introspection check complete"
        fi
    fi
}

run_secret_scan() {
    local input="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/secrets.txt"

    if ! should_run_tool "trufflehog"; then
        return
    fi

    if ! check_tool "trufflehog"; then
        log_warning "trufflehog not installed, skipping secret scanning"
        return
    fi

    check_time_window || return
    progress "Running secret scanning with trufflehog..."
    save_state "SECRET_SCAN_START"

    cut -d' ' -f1 "$input" | sort -u > "$OUTPUT_DIR/$TARGET_SAFE/secret_targets.txt"

    while read url; do
        echo "Scanning $url..." >> "$output"
        trufflehog filesystem "$url" --json 2>/dev/null >> "$output" || true
    done < "$OUTPUT_DIR/$TARGET_SAFE/secret_targets.txt"

    local count
    count=$(grep -c "RawV2" "$output" 2>/dev/null || true)
    count=$(echo "$count" | tr -cd '0-9' | head -c 10)
    count=${count:-0}
    if [[ $count -gt 0 ]]; then
        log_success "Found $count potential secrets"
        send_notification "WARNING: Found $count potential secrets exposed on $TARGET" "high"
    else
        log_info "No secrets found"
    fi

    save_state "SECRET_SCAN_DONE"
}

run_screenshots() {
    local input="$1"

    if ! should_run_tool "gowitness"; then
        return
    fi

    if ! check_tool "gowitness"; then
        log_warning "gowitness not installed, skipping screenshots"
        return
    fi

    check_time_window || return
    progress "Capturing screenshots with gowitness..."
    save_state "SCREENSHOT_START"

    local screenshot_dir="$OUTPUT_DIR/$TARGET_SAFE/screenshots"

    cut -d' ' -f1 "$input" | sort -u > "$OUTPUT_DIR/$TARGET_SAFE/screenshot_targets.txt"

    gowitness file -f "$OUTPUT_DIR/$TARGET_SAFE/screenshot_targets.txt" \
        -P "$screenshot_dir" --threads 5 2>/dev/null || true

    log_success "Screenshots saved to $screenshot_dir"
    save_state "SCREENSHOT_DONE"
}