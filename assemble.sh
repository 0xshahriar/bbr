#!/bin/bash
# BBR Assembly Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/bbr.sh"

echo "🔧 Assembling BBR Script..."
echo ""

parts=(
    "bbr_part1_header.sh"
    "bbr_part2_features.sh"
    "bbr_part3_scanning.sh"
    "bbr_part4_discovery.sh"
    "bbr_part5_reports.sh"
    "bbr_part7_utils.sh"
    "bbr_part8_main.sh"
)

missing=0
for part in "${parts[@]}"; do
    if [[ ! -f "$SCRIPT_DIR/$part" ]]; then
        echo "❌ Missing: $part"
        missing=1
    else
        echo "✓ Found: $part"
    fi
done

if [[ $missing -eq 1 ]]; then
    echo ""
    echo "Error: Some parts are missing."
    exit 1
fi

echo ""
echo "📝 Assembling bbr.sh..."

cat "$SCRIPT_DIR/bbr_part1_header.sh" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for part in "${parts[@]:1}"; do
    cat "$SCRIPT_DIR/$part" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

chmod +x "$OUTPUT_FILE"

echo ""
echo "✅ Assembly complete!"
echo ""
echo "📄 Output: $OUTPUT_FILE"
echo "📊 Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "🔢 Lines: $(wc -l < "$OUTPUT_FILE")"
echo ""
echo "🗑️  You can delete part files after assembly:"
echo "   rm bbr_part*.sh"
echo ""
echo "🚀 Keep these files:"
echo "   bbr.sh              (main script)"
echo "   bbr_dashboard.py    (web dashboard)"
echo "   assemble.sh         (reassembly script)"
echo "   config.yaml         (configuration)"
echo ""
echo "🎯 Usage:"
echo "   ./bbr.sh -d example.com -all"
echo "   ./bbr.sh dashboard"