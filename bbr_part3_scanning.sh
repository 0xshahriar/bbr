
# FIXED: Compact vertical progress bar - single line at bottom
_nuclei_progress_bar() {
    local pipe="$1"
    local last_pct=-1

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue

        # Parse only what we need
        local pct=$(echo "$line" | grep -o '"percent":"[^"]*"' | cut -d'"' -f4 | cut -d'.' -f1)
        local req=$(echo "$line" | grep -o '"requests":"[^"]*"' | cut -d'"' -f4)
        local rps=$(echo "$line" | grep -o '"rps":"[^"]*"' | cut -d'"' -f4)
        local matched=$(echo "$line" | grep -o '"matched":"[^"]*"' | cut -d'"' -f4)
        local templates=$(echo "$line" | grep -o '"templates":"[^"]*"' | cut -d'"' -f4)

        pct=${pct:-0}
        req=${req:-0}
        rps=${rps:-0}
        matched=${matched:-0}
        templates=${templates:-0}

        # Only update on percentage change
        if [[ "$pct" != "$last_pct" ]]; then
            last_pct="$pct"
            # Print compact single-line status (overwrites same line)
            printf "\r\033[K\033[1;36m[nuclei]\033[0m \033[1m%3s%%\033[0m │ \033[33m%6s\033[0m req │ \033[32m%3s\033[0m rps │ \033[31m%3s\033[0m matches │ %s tpl"                 "$pct" "$req" "$rps" "$matched" "$templates" >&2
        fi
    done < "$pipe"

    # Final newline
    printf "\n" >&2
}

# FIXED: run_nuclei with proper output separation
run_nuclei() {
    local input="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/nuclei.txt"
    local output_json="$OUTPUT_DIR/$TARGET_SAFE/nuclei.json"

    if ! should_run_tool "nuclei"; then
        return
    fi

    check_time_window || return
    progress "Running nuclei scan..."
    save_state "NUCLEI_START"

    # Update templates if needed
    if [[ ! -f "$HOME/.nuclei-last-update" ]] || [[ $(find "$HOME/.nuclei-last-update" -mtime +7 2>/dev/null) ]]; then
        log_info "Updating nuclei templates..."
        nuclei -ut -silent 2>/dev/null
        touch "$HOME/.nuclei-last-update"
    fi

    cut -d' ' -f1 "$input" | sort -u > "$OUTPUT_DIR/$TARGET_SAFE/nuclei_targets.txt"

    local proxy_args=$(build_proxy_args)

    # Create temp files
    local temp_output=$(mktemp)
    local temp_json=$(mktemp)

    # CRITICAL FIX: Strict output separation
    if [[ -t 2 ]]; then
        # Interactive mode - show compact progress
        local stats_pipe
        local _tmpdir="${TMPDIR:-${PREFIX:+$PREFIX/tmp}}"
        _tmpdir="${_tmpdir:-/tmp}"
        mkdir -p "$_tmpdir" 2>/dev/null || true
        stats_pipe=$(mktemp -u "${_tmpdir}/bbr_nuclei_stats_XXXXXX")
        mkfifo "$stats_pipe"

        _nuclei_progress_bar "$stats_pipe" &
        local bar_pid=$!

        # FIX: Redirect stdout to /dev/null to prevent ANY output mixing
        # Only -o and -jsonl files get the output
        nuclei -l "$OUTPUT_DIR/$TARGET_SAFE/nuclei_targets.txt" \
            -rl "$RATE_LIMIT_NUCLEI" -timeout "$TIMEOUT" \
            -severity critical,high,medium,low,info \
            -silent \
            -no-color \
            -stats-json \
            -o "$temp_output" \
            -jsonl -o "$temp_json" \
            $proxy_args 2>"$stats_pipe" >/dev/null

        # Cleanup
        exec 3>"$stats_pipe" && exec 3>&- 2>/dev/null || true
        wait "$bar_pid" 2>/dev/null || true
        rm -f "$stats_pipe"
    else
        # Non-interactive - silent mode
        log_info "Running nuclei in background mode..."
        nuclei -l "$OUTPUT_DIR/$TARGET_SAFE/nuclei_targets.txt" \
            -rl "$RATE_LIMIT_NUCLEI" -timeout "$TIMEOUT" \
            -severity critical,high,medium,low,info \
            -silent \
            -no-color \
            -o "$temp_output" \
            -jsonl -o "$temp_json" \
            $proxy_args 2>/dev/null >/dev/null
    fi

    # Atomic move
    mv "$temp_output" "$output" 2>/dev/null || touch "$output"
    mv "$temp_json" "$output_json" 2>/dev/null || touch "$output_json"

    # Summary
    if [[ -s "$output_json" ]]; then
        local critical=$(grep -c '"severity":"critical"' "$output_json" 2>/dev/null || echo "0")
        local high_c=$(grep -c '"severity":"high"' "$output_json" 2>/dev/null || echo "0")
        local medium=$(grep -c '"severity":"medium"' "$output_json" 2>/dev/null || echo "0")

        METRICS_FINDINGS=${METRICS_FINDINGS:-0}
        METRICS_FINDINGS=$((METRICS_FINDINGS + critical + high_c + medium))

        log_success "Nuclei scan complete: $critical critical, $high_c high, $medium medium"

        if [[ $critical -gt 0 ]]; then
            send_notification "CRITICAL: Found $critical critical vulnerabilities on $TARGET!" "critical"
        fi
        if [[ $high_c -gt 0 ]]; then
            send_notification "HIGH: Found $high_c high severity vulnerabilities on $TARGET" "high"
        fi
    else
        log_info "No vulnerabilities found by nuclei"
    fi

    save_state "NUCLEI_DONE"
}

run_subfinder() {
    local target="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/subdomains.txt"
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"

    check_time_window || return
    progress "Running subfinder..."
    save_state "SUBFINDER_START"

    local proxy_args=$(build_proxy_args)

    subfinder -d "$target" -silent -t 10 -timeout 10 $proxy_args 2>/dev/null \
        | dnsx -silent -a -resp 2>/dev/null \
        | awk '{print $1}' | sort -u > "$target_dir/subdomains_subfinder.txt"

    if check_tool "assetfinder"; then
        assetfinder --subs-only "$target" 2>/dev/null | sort -u > "$target_dir/subdomains_assetfinder.txt"
    fi

    if check_tool "amass" && ! is_termux; then
        amass enum -passive -d "$target" -timeout 5 2>/dev/null | sort -u > "$target_dir/subdomains_amass.txt"
    fi

    cat "$target_dir"/subdomains_*.txt 2>/dev/null | sort -u > "$output"
    apply_filters "$output" "$output"

    local count=$(wc -l < "$output" 2>/dev/null || echo "0")
    log_success "Found $count subdomains"
    save_state "SUBFINDER_DONE"
    send_notification "Subdomain enumeration complete for $target: $count subdomains found"
}

run_httpx() {
    local input="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/alive.txt"

    check_time_window || return
    progress "Running httpx..."
    save_state "HTTPX_START"

    local proxy_args=$(build_proxy_args)
    local ua=$(get_random_ua)

    httpx -l "$input" -silent -t "$RATE_LIMIT_HTTPX" -timeout "$TIMEOUT" \
        -status-code -title -tech-detect -follow-redirects \
        -H "User-Agent: $ua" $proxy_args 2>/dev/null | tee "$output"

    add_jitter

    local count=$(wc -l < "$output" 2>/dev/null || echo "0")
    log_success "Found $count alive hosts"
    save_state "HTTPX_DONE"

    progress "Analyzing technologies..."
    grep -i "wordpress" "$output" > "$OUTPUT_DIR/$TARGET_SAFE/wp_hosts.txt" 2>/dev/null
    grep -i "graphql" "$output" > "$OUTPUT_DIR/$TARGET_SAFE/graphql_hosts.txt" 2>/dev/null
    grep -i "joomla" "$output" > "$OUTPUT_DIR/$TARGET_SAFE/joomla_hosts.txt" 2>/dev/null
}

run_naabu() {
    local input="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/ports.txt"

    check_time_window || return
    progress "Running naabu..."
    save_state "NAABU_START"

    local proxy_args=$(build_proxy_args)

    cut -d' ' -f1 "$input" | sed 's|https\?://||' | sort -u | \
        naabu -silent -rate "$RATE_LIMIT_NAABU" -timeout "$TIMEOUT" $proxy_args 2>/dev/null | tee "$output"

    local count=$(wc -l < "$output" 2>/dev/null || echo "0")
    log_success "Found $count open ports"
    save_state "NAABU_DONE"
}