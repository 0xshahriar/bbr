# BBR (Bug Bounty Reconnaissance) v1.0

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/0xShahriar/bbr)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Termux-orange.svg)](https://github.com/0xShahriar/bbr)

> Advanced automated reconnaissance tool for bug bounty hunters and security professionals.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [Integrations](#integrations)
- [Dashboard](#dashboard)
- [Troubleshooting](#troubleshooting)
- [Community](#community)

## Introduction

BBR is a comprehensive reconnaissance automation framework designed for bug bounty hunters, penetration testers, and security researchers. It orchestrates industry-standard tools into a streamlined workflow.

## Features

- ✅ Subdomain enumeration (subfinder, assetfinder, amass)
- ✅ Live host detection (httpx with tech detection)
- ✅ Port scanning (naabu)
- ✅ URL discovery (gau, waybackurls, katana)
- ✅ Vulnerability scanning (nuclei)
- ✅ Secret detection (trufflehog)
- ✅ Cloud reconnaissance (AWS, Azure, GCP)
- ✅ Supply chain security
- ✅ OSINT collection
- ✅ Continuous monitoring with delta detection
- ✅ Web dashboard with real-time updates

## Installation

### Requirements

- Bash 4.0+
- Python 3.7+
- Go 1.18+

### Quick Install

```bash
git clone https://github.com/0xShahriar/bbr.git
cd bbr
chmod +x assemble.sh
./assemble.sh

# Optional: Move to PATH
sudo mv bbr.sh /usr/local/bin/bbr
sudo mv bbr_dashboard.py /usr/local/bin/
```

## Quick Start

```bash
# Basic scan
./bbr.sh -d example.com -all

# With dashboard
./bbr.sh -d example.com -all &
./bbr.sh dashboard
```

## Usage

```bash
# Single domain
./bbr.sh -d example.com -all

# From file
./bbr.sh -f targets.txt -all

# Specific tools
./bbr.sh -d example.com -subfinder -httpx -nuclei

# With config
./bbr.sh -d example.com -all --config config.yaml
```

## Configuration

Copy `config.yaml` to `~/.bbr/config.yaml` and edit:

```yaml
rate_limit_httpx: 50
rate_limit_nuclei: 30
continuous_mode: false
cloud_recon: true
slack_webhook: "https://hooks.slack.com/services/..."
```

See [config.yaml](config.yaml) for all options.

## Integrations

BBR supports notifications via:

- **Slack** - See [docs/slack-integration.md](docs/slack-integration.md)
- **Discord** - See [docs/discord-integration.md](docs/discord-integration.md)
- **Telegram** - See [docs/telegram-integration.md](docs/telegram-integration.md)
- **Email (SMTP)** - Configure in config.yaml

## Dashboard

```bash
./bbr.sh dashboard 3000
# Open http://localhost:3000
```

Features:
- Real-time scan statistics
- Vulnerability breakdown
- Technology detection
- Search and filter
- Mobile responsive

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Arithmetic error | Fixed in v1.0 - variables initialized |
| Nuclei JSON mixing | Fixed in v1.0 - output separated |
| Progress bar too big | Fixed in v1.0 - compact single-line |
| ANSI codes in dashboard | Fixed in v1.0 - auto-stripped |
| Hangs at 98% | Fixed in v1.0 - better cleanup |

## Community

- 💬 Telegram: [@bbr_tool](https://t.me/bbr_tool)
- 💬 Discord: [discord.gg/bbr](https://discord.gg/bbr)
- 🐦 Twitter: [@bbr_tool](https://twitter.com/bbr_tool)

## File Structure

```
bbr/
├── bbr.sh                 # Main script (assembled)
├── bbr_dashboard.py       # Web dashboard
├── config.yaml            # Configuration template
├── assemble.sh            # Assembly script
├── README.md              # This file
├── bbr_part1_header.sh    # Source parts
├── bbr_part2_features.sh
├── bbr_part3_scanning.sh
├── bbr_part4_discovery.sh
├── bbr_part5_reports.sh
├── bbr_part7_utils.sh
├── bbr_part8_main.sh
└── docs/
    ├── slack-integration.md
    ├── discord-integration.md
    └── telegram-integration.md
```

## License

MIT License - see LICENSE file

---

Made with ⚡ by the security community
