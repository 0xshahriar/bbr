#!/bin/bash

################################################################################
#                                                                              #
#   BBR - Bug Bounty Reconnaissance Tool v1.0                                  #
#   Author: 0xShahriar                                                         #
#   Description: Advanced automated reconnaissance with smart scanning         #
#                                                                              #
################################################################################

# Version
BBR_VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# FIX: Initialize metrics variables to prevent arithmetic errors
METRICS_REQUESTS=0
METRICS_FINDINGS=0

# Configuration
OUTPUT_DIR="output"
LOG_DIR=""
TARGET=""
TARGET_SAFE=""
SCOPE_FILE=""
SELECTED_TOOLS=()
RATE_LIMIT_HTTPX=50
RATE_LIMIT_NUCLEI=30
RATE_LIMIT_KATANA=20
RATE_LIMIT_NAABU=100
TIMEOUT=30
WEBHOOK_URL=""
WEBHOOK_TYPE=""
CONFIG_FILE=""
RESUME_MODE=false
PROXY_URL=""
USE_TOR=false
OUTPUT_FORMAT="html"
EXCLUDE_PATTERNS=()
TECH_FILTER=""
TIME_WINDOW=""
USER_AGENT_ROTATION=false
REQUEST_JITTER=false
DOH_SERVER=""
CLOUDFLARE_BYPASS=false
DASHBOARD_PORT=3000
METRICS_ENABLED=false
CONTINUOUS_MODE=false
CONTINUOUS_INTERVAL="24h"
DELTA_ALERT=false
AI_FILTERING=false
AI_CONFIDENCE=0.85
MAX_MEMORY=""
MAX_DISK=""
CACHE_TTL="24h"
SMART_RESUME=false
CLOUD_RECON=false
SUPPLY_CHAIN=false
OSINT_MODE=false
DASHBOARD_ENHANCED=false

# State management
STATE_DIR="$HOME/.bbr/state"
CACHE_DIR="$HOME/.bbr/cache"
BASELINE_DIR="$HOME/.bbr/baselines"
STATE_FILE=""

# Metrics
METRICS_START_TIME=""

# Tools array
TOOLS=("gau" "katana" "nuclei" "urlfinder" "waybackurls" "httpx" "naabu" "subfinder" "vulnx" "wpprobe" "uro" "gf" "assetfinder" "amass" "dnsx" "anew" "jq" "trufflehog" "gowitness" "alterx" "tlsx" "ffuf" "feroxbuster" "linkfinder" "arjun" "githound" "s3scanner" "cloud_enum" "theharvester")

# User agents
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
)

# Banner
banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
██████╗ ██████╗ ██████╗ 
██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██████╔╝
██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║  ██║
╚═════╝ ╚═════╝ ╚═╝  ╚═╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}[+] BBR v${BBR_VERSION} - Smart Reconnaissance Tool${NC}"
    echo -e "${YELLOW}[+] Author: 0xShahriar${NC}"
    echo ""
}

# Logging
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [[ -n "$LOG_DIR" && -d "$LOG_DIR" ]]; then
        echo -e "[$timestamp] [$level] $message" >> "$LOG_DIR/bbr.log" 2>/dev/null
    fi
}

log_info() {
    echo ""
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS" "$1"
    echo ""
}

log_warning() {
    echo ""
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING" "$1"
}

log_error() {
    echo ""
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR" "$1"
}

progress() {
    echo ""
    echo -e "${MAGENTA}[*]${NC} $1"
    METRICS_REQUESTS=$((METRICS_REQUESTS + 1))
}

# FIXED: Metrics functions with proper defaults
init_metrics() {
    METRICS_START_TIME=$(date +%s)
    METRICS_REQUESTS=${METRICS_REQUESTS:-0}
    METRICS_FINDINGS=${METRICS_FINDINGS:-0}
}

show_metrics() {
    local end_time=$(date +%s)
    local duration=$((end_time - METRICS_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    # FIX: Ensure variables have default values to prevent arithmetic errors
    local requests=${METRICS_REQUESTS:-0}
    local findings=${METRICS_FINDINGS:-0}

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     SCAN METRICS                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${WHITE}Duration:${NC} ${minutes}m ${seconds}s"
    echo -e "${WHITE}Total Requests:${NC} $requests"
    echo -e "${WHITE}Total Findings:${NC} $findings"
    echo ""
}