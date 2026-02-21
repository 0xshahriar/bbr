
generate_reports() {
    local target="$1"
    case "$OUTPUT_FORMAT" in
        "html") generate_html_report "$target" ;;
        "json") generate_json_report "$target" ;;
        "csv") generate_csv_report "$target" ;;
        "md") generate_markdown_report "$target" ;;
        "all")
            generate_html_report "$target"
            generate_json_report "$target"
            generate_csv_report "$target"
            generate_markdown_report "$target"
            ;;
    esac
}

generate_html_report() {
    local target="$1"
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"
    local report="$target_dir/report.html"

    progress "Generating HTML report..."

    local subdomains=$(wc -l < "$target_dir/subdomains.txt" 2>/dev/null || echo "0")
    local alive=$(wc -l < "$target_dir/alive.txt" 2>/dev/null || echo "0")
    local ports=$(wc -l < "$target_dir/ports.txt" 2>/dev/null || echo "0")
    local urls=$(wc -l < "$target_dir/urls.txt" 2>/dev/null || echo "0")

    local nuclei_critical=$(grep -c "critical" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")
    local nuclei_high=$(grep -c "high" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")
    local nuclei_medium=$(grep -c "medium" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")
    local nuclei_low=$(grep -c "low" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")

    cat > "$report" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>BBR Report - $target</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #eaeaea; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #e94560; text-align: center; }
        .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 30px 0; }
        .card { background: rgba(255,255,255,0.05); padding: 20px; border-radius: 10px; text-align: center; }
        .card h3 { color: #e94560; margin-bottom: 10px; }
        .card .number { font-size: 2em; font-weight: bold; }
        .severity-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 20px 0; }
        .severity-box { padding: 15px; border-radius: 8px; text-align: center; }
        .critical { background: #ff416c; }
        .high { background: #f2994a; }
        .medium { background: #56ab2f; }
        .low { background: #2193b0; }
        .section { background: rgba(255,255,255,0.03); padding: 20px; margin: 20px 0; border-radius: 10px; }
        .section h2 { color: #e94560; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 10px; }
        pre { background: rgba(0,0,0,0.3); padding: 15px; border-radius: 5px; overflow-x: auto; max-height: 300px; }
        .screenshot-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 15px; }
        .screenshot-item img { width: 100%; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 BBR Report v${BBR_VERSION}</h1>
        <p style="text-align: center; color: #666;">Target: <strong>$target</strong> | Generated: $(date)</p>

        <div class="summary-grid">
            <div class="card"><h3>Subdomains</h3><div class="number">$subdomains</div></div>
            <div class="card"><h3>Alive Hosts</h3><div class="number">$alive</div></div>
            <div class="card"><h3>Open Ports</h3><div class="number">$ports</div></div>
            <div class="card"><h3>URLs</h3><div class="number">$urls</div></div>
        </div>

        <div class="section">
            <h2>🚨 Vulnerability Summary</h2>
            <div class="severity-grid">
                <div class="severity-box critical"><strong>$nuclei_critical</strong><br>Critical</div>
                <div class="severity-box high"><strong>$nuclei_high</strong><br>High</div>
                <div class="severity-box medium"><strong>$nuclei_medium</strong><br>Medium</div>
                <div class="severity-box low"><strong>$nuclei_low</strong><br>Low</div>
            </div>
        </div>
EOF

    if [[ -s "$target_dir/subdomains.txt" ]]; then
        { printf '<div class="section"><h2>📋 Subdomains</h2><pre>'; cat "$target_dir/subdomains.txt" | head -50 | sed 's/</\&lt;/g; s/>/\&gt;/g'; printf '</pre></div>\n'; } >> "$report"
    fi

    if [[ -s "$target_dir/alive.txt" ]]; then
        { printf '<div class="section"><h2>🌐 Alive Hosts</h2><pre>'; cat "$target_dir/alive.txt" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/</\&lt;/g; s/>/\&gt;/g'; printf '</pre></div>\n'; } >> "$report"
    fi

    if [[ -s "$target_dir/ports.txt" ]]; then
        { printf '<div class="section"><h2>🔌 Open Ports</h2><pre>'; cat "$target_dir/ports.txt" | sed 's/</\&lt;/g; s/>/\&gt;/g'; printf '</pre></div>\n'; } >> "$report"
    fi

    if [[ -s "$target_dir/urls.txt" ]]; then
        { printf '<div class="section"><h2>🔗 URLs</h2><pre>'; cat "$target_dir/urls.txt" | head -100 | sed 's/</\&lt;/g; s/>/\&gt;/g'; printf '</pre></div>\n'; } >> "$report"
    fi

    if [[ -s "$target_dir/nuclei.txt" ]]; then
        { printf '<div class="section"><h2>⚠️ Vulnerabilities</h2><pre>'; cat "$target_dir/nuclei.txt" | sed 's/</\&lt;/g; s/>/\&gt;/g'; printf '</pre></div>\n'; } >> "$report"
    fi

    if [[ -s "$target_dir/secrets.txt" ]]; then
        { printf '<div class="section"><h2>🔑 Secrets</h2><pre>'; cat "$target_dir/secrets.txt" | sed 's/</\&lt;/g; s/>/\&gt;/g'; printf '</pre></div>\n'; } >> "$report"
    fi

    if [[ -d "$target_dir/screenshots" && $(ls -1 "$target_dir/screenshots" 2>/dev/null | wc -l) -gt 0 ]]; then
        printf '<div class="section"><h2>📸 Screenshots</h2><div class="screenshot-grid">\n' >> "$report"
        for img in "$target_dir/screenshots"/*.png; do
            [[ -f "$img" ]] && printf '<div class="screenshot-item"><img src="screenshots/%s"></div>\n' "$(basename "$img")" >> "$report"
        done
        echo "</div></div>" >> "$report"
    fi

    printf '<p style="text-align: center; color: #666; margin-top: 30px;">Generated by BBR v%s - Author: 0xShahriar</p></div></body></html>\n' "${BBR_VERSION}" >> "$report"

    log_success "HTML report: $report"
}

generate_json_report() {
    local target="$1"
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"
    local report="$target_dir/report.json"

    progress "Generating JSON report..."

    cat > "$report" << EOF
{
  "tool": "BBR",
  "version": "${BBR_VERSION}",
  "target": "$target",
  "timestamp": "$(date -Iseconds)",
  "summary": {
    "subdomains": $(wc -l < "$target_dir/subdomains.txt" 2>/dev/null || echo "0"),
    "alive_hosts": $(wc -l < "$target_dir/alive.txt" 2>/dev/null || echo "0"),
    "open_ports": $(wc -l < "$target_dir/ports.txt" 2>/dev/null || echo "0"),
    "urls": $(wc -l < "$target_dir/urls.txt" 2>/dev/null || echo "0"),
    "vulnerabilities": {
      "critical": $(grep -c "critical" "$target_dir/nuclei.txt" 2>/dev/null || echo "0"),
      "high": $(grep -c "high" "$target_dir/nuclei.txt" 2>/dev/null || echo "0"),
      "medium": $(grep -c "medium" "$target_dir/nuclei.txt" 2>/dev/null || echo "0"),
      "low": $(grep -c "low" "$target_dir/nuclei.txt" 2>/dev/null || echo "0")
    }
  }
}
EOF
    log_success "JSON report: $report"
}

generate_csv_report() {
    local target="$1"
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"
    local report="$target_dir/report.csv"

    progress "Generating CSV report..."

    echo "Category,Item,Details" > "$report"

    while read subdomain; do
        [[ -n "$subdomain" ]] && echo "Subdomain,$subdomain," >> "$report"
    done < "$target_dir/subdomains.txt" 2>/dev/null

    while read host; do
        [[ -n "$host" ]] && echo "Alive Host,,$host" >> "$report"
    done < "$target_dir/alive.txt" 2>/dev/null

    while read vuln; do
        if [[ -n "$vuln" ]]; then
            local severity=$(echo "$vuln" | awk '{print $2}')
            local template=$(echo "$vuln" | awk '{print $3}')
            local url=$(echo "$vuln" | awk '{print $4}')
            echo "Vulnerability,$severity,$template,$url" >> "$report"
        fi
    done < "$target_dir/nuclei.txt" 2>/dev/null

    log_success "CSV report: $report"
}

generate_markdown_report() {
    local target="$1"
    local target_dir="$OUTPUT_DIR/$TARGET_SAFE"
    local report="$target_dir/report.md"

    progress "Generating Markdown report..."

    cat > "$report" << EOF
# BBR Reconnaissance Report

**Target:** $target  
**Date:** $(date)  
**Version:** ${BBR_VERSION}

## Summary

| Metric | Count |
|--------|-------|
| Subdomains | $(wc -l < "$target_dir/subdomains.txt" 2>/dev/null || echo "0") |
| Alive Hosts | $(wc -l < "$target_dir/alive.txt" 2>/dev/null || echo "0") |
| Open Ports | $(wc -l < "$target_dir/ports.txt" 2>/dev/null || echo "0") |
| URLs | $(wc -l < "$target_dir/urls.txt" 2>/dev/null || echo "0") |

## Vulnerabilities

| Severity | Count |
|----------|-------|
| Critical | $(grep -c "critical" "$target_dir/nuclei.txt" 2>/dev/null || echo "0") |
| High | $(grep -c "high" "$target_dir/nuclei.txt" 2>/dev/null || echo "0") |
| Medium | $(grep -c "medium" "$target_dir/nuclei.txt" 2>/dev/null || echo "0") |
| Low | $(grep -c "low" "$target_dir/nuclei.txt" 2>/dev/null || echo "0") |

## Subdomains

\`\`\`
$(cat "$target_dir/subdomains.txt" 2>/dev/null | head -20)
\`\`\`

## Vulnerability Details

\`\`\`
$(cat "$target_dir/nuclei.txt" 2>/dev/null | head -30)
\`\`\`

---
*Generated by BBR v${BBR_VERSION} - Author: 0xShahriar*
EOF
    log_success "Markdown report: $report"
}