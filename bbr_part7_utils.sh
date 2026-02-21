
# Utility functions
is_termux() {
    if [[ "$PREFIX" == *"com.termux"* ]] || [[ -d "/data/data/com.termux" ]]; then
        return 0
    fi
    return 1
}

get_random_ua() {
    if [[ "$USER_AGENT_ROTATION" == true ]]; then
        local idx=$((RANDOM % ${#USER_AGENTS[@]}))
        echo "${USER_AGENTS[$idx]}"
    else
        echo "BBR-Recon-Tool/1.0"
    fi
}

add_jitter() {
    if [[ "$REQUEST_JITTER" == true ]]; then
        local delay=$((RANDOM % 3 + 1))
        sleep "$delay"
    fi
}

check_time_window() {
    if [[ -n "$TIME_WINDOW" ]]; then
        local current_time=$(date +%H:%M)
        local start_time=$(echo "$TIME_WINDOW" | cut -d'-' -f1)
        local end_time=$(echo "$TIME_WINDOW" | cut -d'-' -f2)
        if [[ "$current_time" < "$start_time" || "$current_time" > "$end_time" ]]; then
            log_warning "Outside scanning window ($TIME_WINDOW). Waiting..."
            sleep 60
            return 1
        fi
    fi
    return 0
}

check_tool() {
    local tool="$1"
    command -v "$tool" &> /dev/null || [[ -f "$HOME/go/bin/$tool" ]] || { [[ -n "$PREFIX" ]] && [[ -f "$PREFIX/bin/$tool" ]]; } || [[ -f "$HOME/tools/$tool/$tool" ]]
}

build_proxy_args() {
    local proxy_args=""
    if [[ "$USE_TOR" == true ]]; then
        proxy_args="-proxy socks5://127.0.0.1:9050"
    elif [[ -n "$PROXY_URL" ]]; then
        proxy_args="-proxy $PROXY_URL"
    fi
    echo "$proxy_args"
}

should_run_tool() {
    local tool="$1"
    if [[ " ${SELECTED_TOOLS[@]} " =~ " all " ]] || [[ " ${SELECTED_TOOLS[@]} " =~ " ${tool} " ]]; then
        return 0
    fi
    return 1
}

apply_filters() {
    local input_file="$1"
    local output_file="$2"

    if [[ "$(realpath "$input_file" 2>/dev/null || echo "$input_file")" != "$(realpath "$output_file" 2>/dev/null || echo "$output_file")" ]]; then
        cp "$input_file" "$output_file"
    fi

    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        grep -v "$pattern" "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
    done

    if [[ -n "$TECH_FILTER" ]]; then
        local tech_pattern=$(echo "$TECH_FILTER" | tr ',' '|')
        grep -iE "$tech_pattern" "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
    fi
}

save_state() {
    local stage="$1"
    if [[ "$RESUME_MODE" == true ]]; then
        echo "STAGE:$stage:$(date +%s)" >> "$STATE_FILE"
    fi
}

load_state() {
    if [[ "$RESUME_MODE" == true && -f "$STATE_FILE" ]]; then
        local last_stage=$(grep "STAGE:" "$STATE_FILE" | tail -1 | cut -d':' -f2)
        echo "$last_stage"
    else
        echo "START"
    fi
}

send_notification() {
    local message="$1"
    local severity="$2"
    [[ -z "$WEBHOOK_URL" ]] && return

    case "$WEBHOOK_TYPE" in
        "slack")
            curl -s -X POST -H 'Content-type: application/json' --data "{"text":"$message"}" "$WEBHOOK_URL" &>/dev/null
            ;;
        "discord")
            local color="3066993"
            [[ "$severity" == "critical" ]] && color="15158332"
            [[ "$severity" == "high" ]] && color="15105570"
            curl -s -X POST -H 'Content-type: application/json' --data "{"embeds":[{"title":"BBR Alert","description":"$message","color":$color}]}" "$WEBHOOK_URL" &>/dev/null
            ;;
    esac
}

init_target() {
    local target="$1"
    TARGET_SAFE=$(echo "$target" | sed 's/[^a-zA-Z0-9.-]/_/g')
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"

    mkdir -p "$target_dir"
    mkdir -p "$target_dir/logs"
    mkdir -p "$target_dir/screenshots"
    mkdir -p "$target_dir/deltas"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$BASELINE_DIR"

    LOG_DIR="$target_dir/logs"
    STATE_FILE="$STATE_DIR/${TARGET_SAFE}_state.log"

    echo "$target" > "$target_dir/target.txt"
    log_info "Initialized target: $target"
}

print_summary() {
    local target="$1"
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    SCAN SUMMARY                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Target:${NC} $target"
    echo -e "${WHITE}Output Directory:${NC} $target_dir"
    echo ""

    [[ -f "$target_dir/subdomains.txt" ]] && echo -e "${BLUE}Subdomains:${NC} $(wc -l < "$target_dir/subdomains.txt" 2>/dev/null || echo 0)"
    [[ -f "$target_dir/alive.txt" ]] && echo -e "${GREEN}Alive Hosts:${NC} $(wc -l < "$target_dir/alive.txt" 2>/dev/null || echo 0)"
    [[ -f "$target_dir/ports.txt" ]] && echo -e "${MAGENTA}Open Ports:${NC} $(wc -l < "$target_dir/ports.txt" 2>/dev/null || echo 0)"
    [[ -f "$target_dir/urls.txt" ]] && echo -e "${CYAN}URLs:${NC} $(wc -l < "$target_dir/urls.txt" 2>/dev/null || echo 0)"

    if [[ -f "$target_dir/nuclei.txt" ]]; then
        echo ""
        echo -e "${RED}Vulnerabilities Found:${NC}"
        echo -e "  Critical: $(grep -c "critical" "$target_dir/nuclei.txt" 2>/dev/null || echo 0)"
        echo -e "  High: $(grep -c "high" "$target_dir/nuclei.txt" 2>/dev/null || echo 0)"
        echo -e "  Medium: $(grep -c "medium" "$target_dir/nuclei.txt" 2>/dev/null || echo 0)"
        echo -e "  Low: $(grep -c "low" "$target_dir/nuclei.txt" 2>/dev/null || echo 0)"
    fi

    echo ""
    echo -e "${YELLOW}Reports:${NC}"
    [[ -f "$target_dir/report.html" ]] && echo -e "  HTML: $target_dir/report.html"
    [[ -f "$target_dir/report.json" ]] && echo -e "  JSON: $target_dir/report.json"
    [[ -f "$target_dir/report.csv" ]] && echo -e "  CSV: $target_dir/report.csv"
    [[ -f "$target_dir/report.md" ]] && echo -e "  Markdown: $target_dir/report.md"
    echo -e "${YELLOW}Logs:${NC} $target_dir/logs/"
    echo ""
    echo -e "${GREEN}[+] Scan completed successfully!${NC}"
    echo ""

    if [[ "$METRICS_ENABLED" == true ]]; then
        show_metrics
    fi
}

process_target() {
    local target="$1"
    TARGET="$target"

    log_info "Starting reconnaissance for: $target"
    send_notification "Starting BBR scan for $target"

    local current_stage=$(load_state)
    log_info "Current stage: $current_stage"

    init_target "$target"

    if [[ "$current_stage" == "START" || "$current_stage" == "SUBFINDER_START" || "$current_stage" == "SUBFINDER_DONE"* ]]; then
        if should_run_tool "subfinder" || should_run_tool "all"; then
            run_subfinder "$target"
        fi
    fi

    if [[ -f "$OUTPUT_DIR/$TARGET_SAFE/subdomains.txt" ]] && (should_run_tool "httpx" || should_run_tool "all"); then
        run_httpx "$OUTPUT_DIR/$TARGET_SAFE/subdomains.txt"
    fi

    if [[ -f "$OUTPUT_DIR/$TARGET_SAFE/alive.txt" ]] && (should_run_tool "naabu" || should_run_tool "all"); then
        run_naabu "$OUTPUT_DIR/$TARGET_SAFE/alive.txt"
    fi

    if [[ -f "$OUTPUT_DIR/$TARGET_SAFE/alive.txt" ]] && (should_run_tool "gau" || should_run_tool "waybackurls" || should_run_tool "katana" || should_run_tool "all"); then
        run_url_discovery "$OUTPUT_DIR/$TARGET_SAFE/alive.txt"
    fi

    if [[ -f "$OUTPUT_DIR/$TARGET_SAFE/alive.txt" ]]; then
        run_smart_scan "$OUTPUT_DIR/$TARGET_SAFE/alive.txt"
    fi

    if [[ -f "$OUTPUT_DIR/$TARGET_SAFE/alive.txt" ]]; then
        if should_run_tool "nuclei" || should_run_tool "all"; then
            run_nuclei "$OUTPUT_DIR/$TARGET_SAFE/alive.txt"
        fi

        if should_run_tool "trufflehog" || should_run_tool "all"; then
            run_secret_scan "$OUTPUT_DIR/$TARGET_SAFE/alive.txt"
        fi

        if should_run_tool "gowitness" || should_run_tool "all"; then
            run_screenshots "$OUTPUT_DIR/$TARGET_SAFE/alive.txt"
        fi
    fi

    if [[ "$CLOUD_RECON" == true ]]; then
        run_cloud_recon "$target"
    fi

    if [[ "$SUPPLY_CHAIN" == true ]]; then
        run_supply_chain_scan "$target"
    fi

    if [[ "$OSINT_MODE" == true ]]; then
        run_osint "$target"
    fi

    generate_correlation
    generate_reports "$target"
    print_summary "$target"

    send_notification "BBR scan completed for $target"

    if [[ "$RESUME_MODE" == true && -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
    fi
}

cleanup() {
    echo ""
    log_warning "Scan interrupted!"
    jobs -p | xargs -r kill 2>/dev/null
    if [[ "$RESUME_MODE" == true ]]; then
        log_info "State saved. Resume with: ./bbr.sh -d $TARGET --resume"
    fi
    exit 130
}