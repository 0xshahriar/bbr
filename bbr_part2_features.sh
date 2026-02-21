
# ============================================
# BBR v1.0 NEW FUNCTIONS
# ============================================

# Resource management
check_resources() {
    if [[ -n "$MAX_MEMORY" ]]; then
        local current_mem=$(free -m 2>/dev/null | awk 'NR==2{printf "%.0f", $3*100/$2}' || echo "0")
        if [[ $current_mem -gt ${MAX_MEMORY%G}00 ]]; then
            log_warning "Memory usage ${current_mem}% exceeds limit ${MAX_MEMORY}"
            sleep 30
        fi
    fi

    if [[ -n "$MAX_DISK" ]]; then
        local current_disk=$(df -h "$OUTPUT_DIR" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
        if [[ $current_disk -gt ${MAX_DISK%G} ]]; then
            log_warning "Disk usage ${current_disk}% exceeds limit ${MAX_DISK}"
            cleanup_old_data
        fi
    fi
}

cleanup_old_data() {
    log_info "Cleaning up old data..."
    find "$OUTPUT_DIR" -type f -mtime +7 -name "*.txt" -delete 2>/dev/null || true
    find "$OUTPUT_DIR" -type f -mtime +7 -name "*.json" -delete 2>/dev/null || true
    find "$OUTPUT_DIR" -type d -mtime +14 -name "screenshots" -exec rm -rf {} + 2>/dev/null || true
}

# Smart caching
cache_key() {
    echo "$1" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$1"
}

get_cache() {
    local key=$(cache_key "$1")
    local cache_file="$CACHE_DIR/$key"
    if [[ -f "$cache_file" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        local ttl_seconds=$(echo "$CACHE_TTL" | sed 's/h/*3600/; s/m/*60/; s/d/*86400/' | bc 2>/dev/null || echo 86400)
        if [[ $age -lt $ttl_seconds ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

set_cache() {
    local key=$(cache_key "$1")
    mkdir -p "$CACHE_DIR"
    echo "$2" > "$CACHE_DIR/$key"
}

# Delta detection
detect_delta() {
    local current_file="$1"
    local baseline_file="$BASELINE_DIR/${TARGET_SAFE}_$(basename "$current_file")"

    if [[ ! -f "$baseline_file" ]]; then
        mkdir -p "$BASELINE_DIR"
        cp "$current_file" "$baseline_file"
        return 0
    fi

    local new_items=$(comm -13 <(sort "$baseline_file" 2>/dev/null) <(sort "$current_file" 2>/dev/null))
    if [[ -n "$new_items" ]]; then
        echo "$new_items" > "${current_file}.delta"
        cp "$current_file" "$baseline_file"
        return 0
    fi
    return 1
}

# Continuous mode
run_continuous_mode() {
    log_info "Starting continuous reconnaissance mode (Interval: $CONTINUOUS_INTERVAL)"

    while true; do
        log_info "Starting scan cycle at $(date)"

        # Run main reconnaissance
        process_target "$TARGET"

        # Check for deltas
        if [[ "$DELTA_ALERT" == true ]]; then
            check_deltas
        fi

        log_info "Scan cycle complete. Sleeping for $CONTINUOUS_INTERVAL..."
        sleep $(echo "$CONTINUOUS_INTERVAL" | sed 's/h/*3600/; s/m/*60/' | bc 2>/dev/null || echo 86400)
    done
}

check_deltas() {
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"
    local delta_found=false
    local delta_report=""

    for file in subdomains.txt alive.txt nuclei.txt; do
        if [[ -f "$target_dir/$file" ]]; then
            if detect_delta "$target_dir/$file"; then
                if [[ -f "$target_dir/${file}.delta" ]]; then
                    local count=$(wc -l < "$target_dir/${file}.delta" 2>/dev/null || echo "0")
                    delta_report="${delta_report}\nNew $file: $count items"
                    delta_found=true
                fi
            fi
        fi
    done

    if [[ "$delta_found" == true ]]; then
        send_notification "🔄 BBR Delta Alert for $TARGET:$delta_report" "high"
    fi
}

# Cloud reconnaissance
run_cloud_recon() {
    local target="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/cloud_assets.txt"

    progress "Starting cloud reconnaissance..."

    if check_tool "s3scanner"; then
        progress "Scanning for S3 buckets..."
        echo "$target" | s3scanner - >> "$output" 2>/dev/null || true
    fi

    if check_tool "cloud_enum"; then
        progress "Running cloud enumeration..."
        cloud_enum -k "$target" -l "$OUTPUT_DIR/$TARGET_SAFE/cloud_enum.txt" 2>/dev/null || true
    fi

    check_exposed_storage "$target" >> "$output"

    local count=$(wc -l < "$output" 2>/dev/null || echo "0")
    log_success "Found $count cloud assets"
}

check_exposed_storage() {
    local target="$1"
    local patterns=("s3.amazonaws.com" "blob.core.windows.net" "storage.googleapis.com")

    for pattern in "${patterns[@]}"; do
        curl -s "https://$target.$pattern" -I 2>/dev/null | grep -q "200\|403" && echo "Found: $target.$pattern"
    done
}

# Supply chain security
run_supply_chain_scan() {
    local target="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/supply_chain.txt"

    progress "Starting supply chain security scan..."

    if check_tool "githound"; then
        progress "Running GitHound..."
        echo "$target" | githound --dig-files --dig-commits > "$OUTPUT_DIR/$TARGET_SAFE/githound.txt" 2>/dev/null || true
    fi

    check_dependency_confusion "$target" >> "$output"
    check_exposed_configs "$target" >> "$output"

    local count=$(wc -l < "$output" 2>/dev/null || echo "0")
    log_success "Found $count supply chain issues"
}

check_dependency_confusion() {
    local target="$1"
    curl -s "https://registry.npmjs.org/$target" 2>/dev/null | jq -r '.name' 2>/dev/null
    curl -s "https://pypi.org/pypi/$target/json" 2>/dev/null | jq -r '.info.name' 2>/dev/null
}

check_exposed_configs() {
    local target="$1"
    local configs=(".env" "config.json" "secrets.yml" "docker-compose.yml" ".git/config" ".aws/credentials")

    for config in "${configs[@]}"; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "https://$target/$config" 2>/dev/null)
        if [[ "$response" == "200" ]]; then
            echo "Exposed config: $target/$config"
        fi
    done
}

# OSINT
run_osint() {
    local target="$1"
    local output="$OUTPUT_DIR/$TARGET_SAFE/osint.txt"

    progress "Starting OSINT collection..."

    if check_tool "theharvester"; then
        progress "Harvesting emails..."
        theharvester -d "$target" -b all -f "$OUTPUT_DIR/$TARGET_SAFE/harvester" 2>/dev/null || true
    fi

    check_social_media "$target" >> "$output"

    log_success "OSINT collection complete"
}

check_social_media() {
    local target="$1"
    local company=$(echo "$target" | cut -d'.' -f1)

    curl -s "https://www.linkedin.com/company/$company" -I 2>/dev/null | grep -q "200" && echo "LinkedIn: https://linkedin.com/company/$company"
    curl -s "https://twitter.com/$company" -I 2>/dev/null | grep -q "200" && echo "Twitter: https://twitter.com/$company"
}

# Enhanced correlation
generate_correlation() {
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"
    local corr_file="$target_dir/correlation.json"

    progress "Generating advanced correlation data..."

    cat > "$corr_file" << EOF
{
  "tool": "BBR",
  "version": "${BBR_VERSION}",
  "target": "$TARGET",
  "timestamp": "$(date -Iseconds)",
  "attack_surface": {
    "domains": [],
    "technologies": [],
    "cloud_assets": [],
    "exposed_services": []
  },
  "attack_paths": [],
  "risk_score": 0,
  "findings": {
    "critical": [],
    "high": [],
    "medium": [],
    "low": []
  }
}
EOF

    if [[ -s "$target_dir/subdomains.txt" ]]; then
        local domains=$(cat "$target_dir/subdomains.txt" | jq -R -s -c 'split("\n")[:-1]' 2>/dev/null || echo "[]")
        jq --argjson d "$domains" '.attack_surface.domains = $d' "$corr_file" > "$corr_file.tmp" 2>/dev/null && mv "$corr_file.tmp" "$corr_file" || true
    fi

    if [[ -s "$target_dir/nuclei.txt" ]]; then
        local critical=$(grep -c "critical" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")
        local high=$(grep -c "high" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")
        local medium=$(grep -c "medium" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")

        local risk=$((critical * 10 + high * 5 + medium * 2))
        jq --argjson r "$risk" '.risk_score = $r' "$corr_file" > "$corr_file.tmp" 2>/dev/null && mv "$corr_file.tmp" "$corr_file" || true
    fi

    jq '.attack_paths = [
        {
            "path": "subdomain_enumeration -> port_scanning -> service_detection",
            "confidence": 0.95,
            "automation_level": "full"
        }
    ]' "$corr_file" > "$corr_file.tmp" 2>/dev/null && mv "$corr_file.tmp" "$corr_file" || true

    log_success "Advanced correlation data saved to $corr_file"
}