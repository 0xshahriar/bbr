
# Tool installation
install_tool() {
    local tool="$1"
    echo -e "${BLUE}[INFO]${NC} Installing $tool..."

    case "$tool" in
        "gau")
            go install github.com/lc/gau/v2/cmd/gau@latest 2>/dev/null || pip install gau 2>/dev/null
            ;;
        "katana")
            go install github.com/projectdiscovery/katana/cmd/katana@latest 2>/dev/null
            ;;
        "nuclei")
            go install -v github.com/projectdiscovery/nuclei/v1/cmd/nuclei@latest 2>/dev/null
            ;;
        "urlfinder")
            go install github.com/projectdiscovery/urlfinder/cmd/urlfinder@latest 2>/dev/null
            ;;
        "waybackurls")
            go install github.com/tomnomnom/waybackurls@latest 2>/dev/null
            ;;
        "httpx")
            go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null
            ;;
        "naabu")
            go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest 2>/dev/null
            ;;
        "subfinder")
            go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null
            ;;
        "vulnx")
            if [[ ! -d "$HOME/tools/vulnx" ]]; then
                mkdir -p "$HOME/tools"
                git clone https://github.com/anouarbensaad/vulnx.git "$HOME/tools/vulnx" 2>/dev/null
                pip install -r "$HOME/tools/vulnx/requirements.txt" 2>/dev/null
                chmod +x "$HOME/tools/vulnx/vulnx.py"
                ln -sf "$HOME/tools/vulnx/vulnx.py" "$HOME/go/bin/vulnx" 2>/dev/null || cp "$HOME/tools/vulnx/vulnx.py" "$PREFIX/bin/vulnx" 2>/dev/null
            fi
            ;;
        "wpprobe")
            if [[ ! -d "$HOME/tools/wpprobe" ]]; then
                mkdir -p "$HOME/tools"
                git clone https://github.com/Chocapikk/wpprobe.git "$HOME/tools/wpprobe" 2>/dev/null
                cd "$HOME/tools/wpprobe" && go build -o wpprobe 2>/dev/null
                cp "$HOME/tools/wpprobe/wpprobe" "$HOME/go/bin/" 2>/dev/null || cp "$HOME/tools/wpprobe/wpprobe" "$PREFIX/bin/" 2>/dev/null
            fi
            ;;
        "uro")
            pip3 install uro 2>/dev/null
            ;;
        "gf")
            go install github.com/tomnomnom/gf@latest 2>/dev/null
            ;;
        "assetfinder")
            go install github.com/tomnomnom/assetfinder@latest 2>/dev/null
            ;;
        "amass")
            go install -v github.com/owasp-amass/amass/v4/...@master 2>/dev/null || apt install amass -y 2>/dev/null
            ;;
        "dnsx")
            go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>/dev/null
            ;;
        "anew")
            go install -v github.com/tomnomnom/anew@latest 2>/dev/null
            ;;
        "jq")
            apt install jq -y 2>/dev/null || pkg install jq -y 2>/dev/null
            ;;
        "gowitness")
            go install github.com/sensepost/gowitness@latest 2>/dev/null
            ;;
        "alterx")
            go install github.com/projectdiscovery/alterx/cmd/alterx@latest 2>/dev/null
            ;;
        "tlsx")
            go install github.com/projectdiscovery/tlsx/cmd/tlsx@latest 2>/dev/null
            ;;
        "ffuf")
            go install github.com/ffuf/ffuf/v2@latest 2>/dev/null
            ;;
        "feroxbuster")
            if is_termux; then
                local fb_ver=$(curl -sfL https://api.github.com/repos/epi052/feroxbuster/releases/latest | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null || echo "v2.11.0")
                curl -sfL "https://github.com/epi052/feroxbuster/releases/download/${fb_ver}/feroxbuster-aarch64-unknown-linux-musl.tar.gz" | tar xz -C "$PREFIX/bin/" feroxbuster 2>/dev/null && chmod +x "$PREFIX/bin/feroxbuster"
            else
                local fb_ver=$(curl -sfL https://api.github.com/repos/epi052/feroxbuster/releases/latest | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null || echo "v2.11.0")
                curl -sfL "https://github.com/epi052/feroxbuster/releases/download/${fb_ver}/feroxbuster-x86_64-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/go/bin/" feroxbuster 2>/dev/null && chmod +x "$HOME/go/bin/feroxbuster"
            fi
            ;;
        "linkfinder")
            local lf_dest="$HOME/tools/linkfinder"
            local lf_bin
            is_termux && lf_bin="$PREFIX/bin/linkfinder" || lf_bin="$HOME/go/bin/linkfinder"
            if [[ ! -f "$lf_bin" ]]; then
                mkdir -p "$HOME/tools"
                git clone --depth=1 https://github.com/GerbenJavado/LinkFinder.git "$lf_dest" 2>/dev/null
                pip3 install -r "$lf_dest/requirements.txt" 2>/dev/null
                printf "#!/bin/bash\npython3 %s/linkfinder.py \"\$@\"\n" "$lf_dest" > "$lf_bin" && chmod +x "$lf_bin"
            fi
            ;;
        "arjun")
            pip3 install arjun 2>/dev/null
            ;;
        "githound")
            go install github.com/tillson/git-hound@latest 2>/dev/null && mv "$HOME/go/bin/git-hound" "$HOME/go/bin/githound" 2>/dev/null || true
            ;;
        "s3scanner")
            pip3 install s3scanner 2>/dev/null
            ;;
        "cloud_enum")
            if [[ ! -d "$HOME/tools/cloud_enum" ]]; then
                mkdir -p "$HOME/tools"
                git clone --depth=1 https://github.com/initstring/cloud_enum.git "$HOME/tools/cloud_enum" 2>/dev/null
                pip3 install -r "$HOME/tools/cloud_enum/requirements.txt" 2>/dev/null
                printf '#!/bin/bash\npython3 %s/cloud_enum/cloud_enum.py "$@"' "$HOME/tools" > "$HOME/go/bin/cloud_enum" && chmod +x "$HOME/go/bin/cloud_enum"
            fi
            ;;
        "theharvester")
            local th_dest="$HOME/tools/theHarvester"
            local th_bin
            is_termux && th_bin="$PREFIX/bin/theharvester" || th_bin="$HOME/go/bin/theharvester"
            if [[ ! -f "$th_bin" ]]; then
                mkdir -p "$HOME/tools"
                git clone --depth=1 https://github.com/laramies/theHarvester.git "$th_dest" 2>/dev/null
                pip3 install -r "$th_dest/requirements/base.txt" 2>/dev/null
                printf "#!/bin/bash\npython3 %s/theHarvester.py \"\$@\"\n" "$th_dest" > "$th_bin" && chmod +x "$th_bin"
            fi
            ;;
        "trufflehog")
            if is_termux; then
                local th_ver=$(curl -sfL https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//' 2>/dev/null || echo "3.88.1")
                curl -sfL "https://github.com/trufflesecurity/trufflehog/releases/download/v${th_ver}/trufflehog_${th_ver}_linux_arm64.tar.gz" | tar xz -C "$PREFIX/bin/" trufflehog 2>/dev/null
            else
                curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b "$HOME/go/bin" 2>/dev/null
            fi
            ;;
        "go")
            if is_termux; then
                pkg install golang -y 2>/dev/null
            else
                apt install golang-go -y 2>/dev/null
            fi
            ;;
    esac

    hash -r 2>/dev/null || true

    local tool_found=false
    if command -v "$tool" &> /dev/null; then tool_found=true
    elif [[ -f "$HOME/go/bin/$tool" ]]; then tool_found=true
    elif [[ -n "$PREFIX" && -f "$PREFIX/bin/$tool" ]]; then tool_found=true
    elif [[ -f "$HOME/tools/$tool/$tool" ]]; then tool_found=true
    fi

    if [[ "$tool_found" == true ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $tool installed successfully"
        return 0
    else
        echo -e "${RED}[ERROR]${NC} Failed to install $tool"
        return 1
    fi
}

check_and_install_tools() {
    echo -e "${BLUE}[INFO]${NC} Checking tools..."
    local missing_tools=()

    for tool in "${TOOLS[@]}"; do
        if ! check_tool "$tool" && [[ ! -f "$HOME/go/bin/$tool" ]] && [[ ! -f "$PREFIX/bin/$tool" ]]; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} All tools are installed"
        return 0
    fi

    echo -e "${YELLOW}[WARNING]${NC} Missing tools: ${missing_tools[*]}"
    echo -e "${BLUE}[INFO]${NC} Installing missing tools..."

    for tool in "${missing_tools[@]}"; do
        install_tool "$tool"
    done
}

setup_env() {
    echo -e "${BLUE}[INFO]${NC} Setting up environment..."
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$HOME/go/bin"
    mkdir -p "$STATE_DIR"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$BASELINE_DIR"

    if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
        export PATH="$PATH:$HOME/go/bin"
        echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.bashrc
    fi

    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}[WARNING]${NC} Go not found. Installing..."
        install_tool "go"
    fi

    echo -e "${GREEN}[SUCCESS]${NC} Environment setup complete"
    echo ""
}

# FIXED: Updated start_dashboard to use external Python file or embedded version
start_dashboard() {
    local port="${1:-3000}"
    local output_dir="$(realpath "$OUTPUT_DIR")"

    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found. Cannot start dashboard."
        exit 1
    fi

    # Check if standalone dashboard exists
    if [[ -f "${BASH_SOURCE%/*}/bbr_dashboard.py" ]]; then
        log_info "Using standalone dashboard..."
        python3 "${BASH_SOURCE%/*}/bbr_dashboard.py" "$output_dir" "$port"
    else
        log_info "Starting BBR Interactive Dashboard on port $port..."
        log_success "Dashboard running at http://localhost:$port"
        log_info "Press Ctrl+C to stop"

        # Fallback to embedded minimal dashboard
        python3 - "$output_dir" "$port" << 'PYSERVER_EOF'
import sys, os, json, http.server, urllib.parse, time, re
OUTPUT_DIR = sys.argv[1]
PORT = int(sys.argv[2])

def strip_ansi(text):
    if not text: return text
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def read_file(path):
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            return [strip_ansi(l.rstrip()) for l in f if l.strip()]
    except: return []

def parse_nuclei(path):
    vulns = []
    try:
        with open(path, 'r') as f:
            for line in f:
                try:
                    obj = json.loads(line.strip())
                    info = obj.get('info', {})
                    vulns.append({'severity': info.get('severity', 'info'), 'name': info.get('name', obj.get('template-id', '')), 'url': obj.get('matched-at', ''), 'template': obj.get('template-id', '')})
                except: pass
    except: pass
    return vulns

def get_targets():
    try: return sorted([d for d in os.listdir(OUTPUT_DIR) if os.path.isdir(os.path.join(OUTPUT_DIR, d)) and not d.startswith('.')])
    except: return []

def get_data(target):
    td = os.path.join(OUTPUT_DIR, target)
    subdomains = read_file(os.path.join(td, 'subdomains.txt'))
    alive = read_file(os.path.join(td, 'alive.txt'))
    urls = read_file(os.path.join(td, 'urls.txt'))
    vulns = parse_nuclei(os.path.join(td, 'nuclei.json'))
    severity = {'critical': 0, 'high': 0, 'medium': 0, 'low': 0, 'info': 0}
    for v in vulns:
        s = v.get('severity', 'info').lower()
        if s in severity: severity[s] += 1
    return {'summary': {'subdomains': len(subdomains), 'alive': len(alive), 'urls': len(urls), 'vulnerabilities': len(vulns), 'severity': severity}, 'subdomains': subdomains[:100], 'alive': alive[:50], 'urls': urls[:50], 'vulns': vulns[:50]}

HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><title>BBR Dashboard</title><script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script><style>body{font-family:sans-serif;background:#1a1a2e;color:#fff;padding:20px;max-width:1400px;margin:0 auto}.header{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;padding:20px;background:#16213e;border-radius:10px}.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:15px;margin-bottom:20px}.stat{background:#0f3460;padding:15px;border-radius:8px;text-align:center}.stat h3{margin:0 0 10px;color:#e94560}.stat .num{font-size:2rem;font-weight:bold}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(400px,1fr));gap:20px}.card{background:#16213e;padding:20px;border-radius:10px}.card h2{color:#e94560;margin-top:0}pre{background:#0f3460;padding:10px;border-radius:5px;overflow:auto;max-height:300px;font-size:12px}.badge{display:inline-block;padding:3px 8px;border-radius:3px;font-size:12px;margin-right:5px}.badge-critical{background:#ff0044}.badge-high{background:#ff8800}.badge-medium{background:#00ff88;color:#000}.badge-low{background:#0088ff}</style></head><body><div class="header"><div><h1>🔍 BBR Dashboard</h1><p>Cyber Reconnaissance</p></div><div><select id="target" onchange="load()"></select><button onclick="refresh()" style="margin-left:10px;padding:8px 16px;background:#e94560;border:none;color:#fff;border-radius:5px;cursor:pointer">Refresh</button></div></div><div class="stats"><div class="stat"><h3>Subdomains</h3><div class="num" id="s-sub">-</div></div><div class="stat"><h3>Alive</h3><div class="num" id="s-alive">-</div></div><div class="stat"><h3>URLs</h3><div class="num" id="s-urls">-</div></div><div class="stat"><h3>Vulns</h3><div class="num" id="s-vulns">-</div></div><div class="stat"><h3>Critical</h3><div class="num" id="s-crit" style="color:#ff0044">-</div></div><div class="stat"><h3>High</h3><div class="num" id="s-high" style="color:#ff8800">-</div></div></div><div class="grid"><div class="card"><h2>📊 Severity Distribution</h2><canvas id="chart"></canvas></div><div class="card"><h2>🐛 Vulnerabilities</h2><div id="vulns"></div></div><div class="card"><h2>🌐 Alive Hosts</h2><pre id="hosts"></pre></div><div class="card"><h2>📋 Subdomains</h2><pre id="subs"></pre></div></div><script>let chart=null;async function getTargets(){const r=await fetch('/api/targets');return r.json()}async function getData(t){const r=await fetch('/api/data?target='+t);return r.json()}function updateUI(d){document.getElementById('s-sub').textContent=d.summary.subdomains;document.getElementById('s-alive').textContent=d.summary.alive;document.getElementById('s-urls').textContent=d.summary.urls;document.getElementById('s-vulns').textContent=d.summary.vulnerabilities;document.getElementById('s-crit').textContent=d.summary.severity.critical;document.getElementById('s-high').textContent=d.summary.severity.high;const ctx=document.getElementById('chart').getContext('2d');if(chart)chart.destroy();chart=new Chart(ctx,{type:'doughnut',data:{labels:['Critical','High','Medium','Low','Info'],datasets:[{data:[d.summary.severity.critical,d.summary.severity.high,d.summary.severity.medium,d.summary.severity.low,d.summary.severity.info],backgroundColor:['#ff0044','#ff8800','#00ff88','#0088ff','#666']}]},options:{plugins:{legend:{labels:{color:'#fff'}}}}});document.getElementById('vulns').innerHTML=d.vulns.map(v=>'<div style="margin-bottom:10px;padding:10px;background:#0f3460;border-radius:5px"><span class="badge badge-'+v.severity+'">'+v.severity+'</span><strong>'+v.name+'</strong><br><small>'+v.url+'</small></div>').join('');document.getElementById('hosts').textContent=d.alive.join('\n');document.getElementById('subs').textContent=d.subdomains.join('\n')}async function load(){const t=document.getElementById('target').value;if(!t)return;const d=await getData(t);updateUI(d)}async function refresh(){await load()}async function init(){const targets=await getTargets();const sel=document.getElementById('target');sel.innerHTML=targets.map(t=>'<option value="'+t+'">'+t+'</option>').join('');if(targets.length>0)await load()}init();setInterval(refresh,30000)</script></body></html>"""

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def send_json(self, data, code=200):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)
        if parsed.path == '/api/targets':
            self.send_json(get_targets())
        elif parsed.path == '/api/data':
            target = params.get('target', [''])[0]
            if not target: self.send_json({'error': 'missing target'}, 400); return
            self.send_json(get_data(target))
        elif parsed.path in ['/', '/index.html']:
            body = HTML.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()

http.server.HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
PYSERVER_EOF
    fi
}

show_help() {
    cat << EOF
BBR v${BBR_VERSION} - Bug Bounty Reconnaissance Tool

Usage: ./bbr.sh [OPTIONS] [COMMAND]

Commands:
    dashboard [port]            Start web dashboard (default: 3000)

Options:
    -d, --domain <domain>       Single target domain
    -f, --file <file>           Scope file with multiple domains
    -all                        Run all tools (default)
    -o, --output <format>       Output format: html, json, csv, md (default: html)

Configuration:
    --config <file>             Load configuration from YAML file
    --resume                    Resume interrupted scan

Network Options:
    --proxy <url>               Use proxy (socks5://host:port or http://host:port)
    --tor                       Use Tor network (127.0.0.1:9050)
    --doh <server>              Use DNS over HTTPS
    --cf-bypass                 Enable Cloudflare bypass techniques

Stealth Options:
    --ua-rotate                 Rotate User-Agent strings
    --jitter                    Add random delays between requests
    --window <start-end>        Scan only during time window (e.g., 09:00-17:00)

Filtering:
    --exclude <pattern>         Exclude pattern (can be used multiple times)
    --tech-filter <tech>        Only scan specific tech (wordpress,joomla,graphql)

v1.0 Features:
    --continuous                Enable continuous monitoring mode
    --interval <duration>       Set check interval (1h, 6h, 24h, 7d)
    --delta-alert               Alert only on new findings
    --cloud-recon               Enable cloud reconnaissance
    --supply-chain              Enable supply chain scanning
    --osint                     Enable OSINT collection
    --ai-filter                 Enable AI-powered noise reduction
    --max-memory <size>         Max memory usage (e.g., 4G)
    --max-disk <size>           Max disk usage (e.g., 50G)
    --smart-resume              Enable smart resume capability

Other:
    --metrics                   Show detailed metrics after scan
    -h, --help                  Show this help message

Examples:
    ./bbr.sh -d example.com -all
    ./bbr.sh -f scope.txt -all -o json
    ./bbr.sh -d example.com -all --config bbr.yaml --resume
    ./bbr.sh -d example.com -all --proxy socks5://127.0.0.1:9050
    ./bbr.sh -d example.com -all --tech-filter wordpress --exclude "*.dev.*"
    ./bbr.sh -d example.com --continuous --interval 24h --delta-alert
EOF
}

load_config() {
    local config_file="${1:-$HOME/.bbr/config.yaml}"
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from $config_file"
        while IFS=':' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            case "$key" in
                "rate_limit_httpx") RATE_LIMIT_HTTPX="$value" ;;
                "rate_limit_nuclei") RATE_LIMIT_NUCLEI="$value" ;;
                "rate_limit_katana") RATE_LIMIT_KATANA="$value" ;;
                "rate_limit_naabu") RATE_LIMIT_NAABU="$value" ;;
                "slack_webhook") WEBHOOK_URL="$value"; WEBHOOK_TYPE="slack" ;;
                "discord_webhook") WEBHOOK_URL="$value"; WEBHOOK_TYPE="discord" ;;
                "proxy_url") PROXY_URL="$value" ;;
                "user_agent_rotation") [[ "$value" == "true" ]] && USER_AGENT_ROTATION=true ;;
                "request_jitter") [[ "$value" == "true" ]] && REQUEST_JITTER=true ;;
                "doh_server") DOH_SERVER="$value" ;;
                "cloudflare_bypass") [[ "$value" == "true" ]] && CLOUDFLARE_BYPASS=true ;;
                "metrics_enabled") [[ "$value" == "true" ]] && METRICS_ENABLED=true ;;
                "dashboard_port") DASHBOARD_PORT="$value" ;;
                "continuous_mode") [[ "$value" == "true" ]] && CONTINUOUS_MODE=true ;;
                "continuous_interval") CONTINUOUS_INTERVAL="$value" ;;
                "delta_alert") [[ "$value" == "true" ]] && DELTA_ALERT=true ;;
                "cloud_recon") [[ "$value" == "true" ]] && CLOUD_RECON=true ;;
                "supply_chain") [[ "$value" == "true" ]] && SUPPLY_CHAIN=true ;;
                "osint") [[ "$value" == "true" ]] && OSINT_MODE=true ;;
            esac
        done < "$config_file"
        log_success "Configuration loaded"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--domain) TARGET="$2"; shift 2 ;;
            -f|--file) SCOPE_FILE="$2"; shift 2 ;;
            -all) SELECTED_TOOLS=("all"); shift ;;
            -httpx|-naabu|-katana|-nuclei|-subfinder|-gau|-waybackurls|-urlfinder|-vulnx|-wpprobe|-trufflehog|-gowitness)
                local tool="${1#-}"
                if [[ ! " ${SELECTED_TOOLS[@]} " =~ " ${tool} " ]]; then
                    SELECTED_TOOLS+=("$tool")
                fi
                shift ;;
            --config) CONFIG_FILE="$2"; shift 2 ;;
            --resume) RESUME_MODE=true; shift ;;
            --proxy) PROXY_URL="$2"; shift 2 ;;
            --tor) USE_TOR=true; shift ;;
            -o|--output) OUTPUT_FORMAT="$2"; shift 2 ;;
            --exclude) EXCLUDE_PATTERNS+=("$2"); shift 2 ;;
            --tech-filter) TECH_FILTER="$2"; shift 2 ;;
            --window) TIME_WINDOW="$2"; shift 2 ;;
            --ua-rotate) USER_AGENT_ROTATION=true; shift ;;
            --jitter) REQUEST_JITTER=true; shift ;;
            --doh) DOH_SERVER="$2"; shift 2 ;;
            --cf-bypass) CLOUDFLARE_BYPASS=true; shift ;;
            --metrics) METRICS_ENABLED=true; shift ;;
            dashboard) start_dashboard "$2"; exit 0 ;;
            --rate-limit-httpx) RATE_LIMIT_HTTPX="$2"; shift 2 ;;
            --rate-limit-nuclei) RATE_LIMIT_NUCLEI="$2"; shift 2 ;;
            --rate-limit-katana) RATE_LIMIT_KATANA="$2"; shift 2 ;;
            --rate-limit-naabu) RATE_LIMIT_NAABU="$2"; shift 2 ;;
            --webhook) WEBHOOK_URL="$2"; shift 2 ;;
            --webhook-type) WEBHOOK_TYPE="$2"; shift 2 ;;
            --continuous) CONTINUOUS_MODE=true; shift ;;
            --interval) CONTINUOUS_INTERVAL="$2"; shift 2 ;;
            --delta-alert) DELTA_ALERT=true; shift ;;
            --cloud-recon) CLOUD_RECON=true; shift ;;
            --supply-chain) SUPPLY_CHAIN=true; shift ;;
            --osint) OSINT_MODE=true; shift ;;
            --ai-filter) AI_FILTERING=true; shift ;;
            --max-memory) MAX_MEMORY="$2"; shift 2 ;;
            --max-disk) MAX_DISK="$2"; shift 2 ;;
            --cache-ttl) CACHE_TTL="$2"; shift 2 ;;
            --smart-resume) SMART_RESUME=true; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done

    if [[ -z "$TARGET" && -z "$SCOPE_FILE" ]]; then
        log_error "Please provide a target domain (-d) or scope file (-f)"
        show_help
        exit 1
    fi

    if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        SELECTED_TOOLS=("all")
    fi
}

main() {
    banner
    setup_env
    parse_args "$@"

    if [[ -n "$CONFIG_FILE" ]]; then
        load_config "$CONFIG_FILE"
    else
        load_config
    fi

    check_and_install_tools

    if [[ "$METRICS_ENABLED" == true ]]; then
        init_metrics
    fi

    trap cleanup INT TERM
    check_resources

    if [[ "$CONTINUOUS_MODE" == true ]]; then
        run_continuous_mode
    else
        if [[ -n "$SCOPE_FILE" ]]; then
            if [[ ! -f "$SCOPE_FILE" ]]; then
                log_error "Scope file not found: $SCOPE_FILE"
                exit 1
            fi
            log_info "Processing scope file: $SCOPE_FILE"
            local total=$(grep -v '^#' "$SCOPE_FILE" | grep -v '^$' | wc -l)
            local current=0
            while IFS= read -r domain || [[ -n "$domain" ]]; do
                [[ -z "$domain" || "$domain" =~ ^# ]] && continue
                current=$((current + 1))
                echo ""
                log_info "[$current/$total] Processing: $domain"
                process_target "$domain"
                sleep 2
            done < "$SCOPE_FILE"
        else
            process_target "$TARGET"
        fi
    fi

    log_success "BBR v${BBR_VERSION} execution complete!"
}

main "$@"