#!/usr/bin/env python3
"""
BBR v1.0 Enhanced Dashboard
Cyberpunk-themed, responsive, with ANSI stripping and filtering
"""

import sys
import os
import json
import http.server
import urllib.parse
import time
import re

OUTPUT_DIR = sys.argv[1] if len(sys.argv) > 1 else "output"
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 3000


def strip_ansi(text):
    """Remove ANSI escape sequences from text for clean display"""
    if not text:
        return text
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)


def read_file(path, lines=None):
    """Read file and return lines, optionally limited, with ANSI stripping"""
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            data = [strip_ansi(l.rstrip()) for l in f if l.strip()]
        return data[:lines] if lines else data
    except:
        return []


def parse_nuclei_jsonl(path):
    """Parse nuclei JSONL output with enhanced details"""
    vulns = []
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    info = obj.get('info', {})
                    vulns.append({
                        'severity': info.get('severity', 'info'),
                        'name': info.get('name', obj.get('template-id', 'Unknown')),
                        'template': obj.get('template-id', ''),
                        'url': obj.get('matched-at', ''),
                        'host': obj.get('host', ''),
                        'type': obj.get('type', ''),
                        'description': info.get('description', ''),
                        'reference': info.get('reference', []),
                        'tags': info.get('tags', []),
                        'timestamp': obj.get('timestamp', '')
                    })
                except:
                    pass
    except:
        pass
    return vulns


def parse_ports_file(path):
    """Parse naabu/port scan output into structured data"""
    ports = []
    try:
        with open(path, 'r') as f:
            for line in f:
                line = strip_ansi(line.strip())
                if ':' in line:
                    parts = line.split(':')
                    if len(parts) >= 2:
                        ports.append({
                            'host': parts[0],
                            'port': parts[1],
                            'service': parts[2] if len(parts) > 2 else 'unknown'
                        })
    except:
        pass
    return ports


def get_targets():
    """Get list of scanned targets with validation"""
    try:
        targets = []
        for d in os.listdir(OUTPUT_DIR):
            target_path = os.path.join(OUTPUT_DIR, d)
            if os.path.isdir(target_path) and not d.startswith('.'):
                has_data = any(os.path.exists(os.path.join(target_path, f)) 
                              for f in ['subdomains.txt', 'alive.txt', 'nuclei.json'])
                if has_data:
                    targets.append(d)
        return sorted(targets)
    except:
        return []


def get_data(target):
    """Get comprehensive scan data for target with full parsing"""
    td = os.path.join(OUTPUT_DIR, target)

    subdomains = read_file(os.path.join(td, 'subdomains.txt'))
    alive_raw = read_file(os.path.join(td, 'alive.txt'))
    urls = read_file(os.path.join(td, 'urls.txt'))
    ports = parse_ports_file(os.path.join(td, 'ports.txt'))
    vulns = parse_nuclei_jsonl(os.path.join(td, 'nuclei.json'))

    # Parse alive hosts for structured display
    parsed_alive = []
    for line in alive_raw:
        if '[' in line:
            parts = line.split('[')
            url = parts[0].strip()
            status = parts[1].split(']')[0] if len(parts) > 1 else ''
            title = parts[2].split(']')[0] if len(parts) > 2 else ''
            tech = parts[3].split(']')[0] if len(parts) > 3 else ''
            parsed_alive.append({
                'url': url,
                'status': status,
                'title': title,
                'tech': tech,
                'raw': line
            })
        else:
            parsed_alive.append({'url': line, 'status': '', 'title': '', 'tech': '', 'raw': line})

    # Calculate statistics
    severity_counts = {'critical': 0, 'high': 0, 'medium': 0, 'low': 0, 'info': 0}
    for v in vulns:
        sev = v.get('severity', 'info').lower()
        if sev in severity_counts:
            severity_counts[sev] += 1

    # Technology breakdown
    tech_stats = {}
    for host in parsed_alive:
        tech_field = host.get('tech', '')
        if tech_field:
            for t in tech_field.split(','):
                t = t.strip()
                if t and not t.startswith('['):
                    tech_stats[t] = tech_stats.get(t, 0) + 1

    return {
        'summary': {
            'subdomains': len(subdomains),
            'alive': len(parsed_alive),
            'urls': len(urls),
            'ports': len(ports),
            'vulnerabilities': len(vulns),
            'severity': severity_counts,
            'technologies': tech_stats
        },
        'subdomains': subdomains[:500],
        'alive': parsed_alive[:200],
        'urls': urls[:300],
        'ports': ports[:200],
        'vulns': vulns,
        'target': target,
        'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
    }


# HTML Dashboard with Cyberpunk Theme
HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BBR v1.0 | Cyber Reconnaissance Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root {
    --bg-primary: #0a0e1a;
    --bg-secondary: #111827;
    --bg-card: #1f2937;
    --bg-hover: #374151;
    --border-color: #374151;
    --accent-primary: #00f0ff;
    --accent-secondary: #7000ff;
    --accent-success: #00ff88;
    --accent-warning: #ffaa00;
    --accent-danger: #ff0044;
    --accent-info: #0099ff;
    --text-primary: #f9fafb;
    --text-secondary: #9ca3af;
    --text-muted: #6b7280;
    --font-mono: 'JetBrains Mono', monospace;
    --font-sans: 'Inter', sans-serif;
    --shadow-glow: 0 0 20px rgba(0, 240, 255, 0.15);
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: var(--font-sans);
    min-height: 100vh;
    background-image: 
        radial-gradient(circle at 20% 50%, rgba(112, 0, 255, 0.1) 0%, transparent 50%),
        radial-gradient(circle at 80% 80%, rgba(0, 240, 255, 0.05) 0%, transparent 50%);
}
.header {
    background: rgba(17, 24, 39, 0.95);
    backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--border-color);
    padding: 1rem 2rem;
    position: sticky;
    top: 0;
    z-index: 100;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1rem;
}
.brand { display: flex; align-items: center; gap: 0.75rem; }
.brand-icon {
    width: 40px; height: 40px;
    background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
    border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 1.2rem;
    box-shadow: var(--shadow-glow);
}
.brand-text h1 {
    font-size: 1.5rem; font-weight: 700;
    background: linear-gradient(135deg, var(--text-primary), var(--accent-primary));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}
.brand-text span {
    font-size: 0.75rem; color: var(--text-muted);
    text-transform: uppercase; letter-spacing: 0.1em;
}
.header-controls { display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; }
.target-selector {
    display: flex; align-items: center; gap: 0.5rem;
    background: var(--bg-card); padding: 0.5rem 1rem;
    border-radius: 8px; border: 1px solid var(--border-color);
}
select {
    background: transparent; color: var(--text-primary); border: none;
    font-family: var(--font-mono); font-size: 0.875rem;
    outline: none; cursor: pointer; min-width: 200px;
}
.btn {
    padding: 0.5rem 1rem; border-radius: 6px;
    border: 1px solid var(--border-color); background: var(--bg-card);
    color: var(--text-primary); cursor: pointer;
    font-size: 0.875rem; font-weight: 500;
    transition: all 0.2s;
}
.btn:hover {
    background: var(--bg-hover); border-color: var(--accent-primary);
    box-shadow: 0 0 10px rgba(0, 240, 255, 0.2);
}
.btn-primary {
    background: linear-gradient(135deg, var(--accent-secondary), var(--accent-primary));
    border: none; color: #000; font-weight: 600;
}
.main { padding: 2rem; max-width: 1600px; margin: 0 auto; }
.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem; margin-bottom: 2rem;
}
.stat-card {
    background: var(--bg-card); border: 1px solid var(--border-color);
    border-radius: 12px; padding: 1.5rem;
    position: relative; overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
}
.stat-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-glow); }
.stat-card::before {
    content: ''; position: absolute;
    top: 0; left: 0; right: 0; height: 3px;
    background: linear-gradient(90deg, var(--accent-primary), var(--accent-secondary));
}
.stat-card.critical::before { background: var(--accent-danger); }
.stat-card.high::before { background: var(--accent-warning); }
.stat-card.medium::before { background: var(--accent-success); }
.stat-card.low::before { background: var(--accent-info); }
.stat-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem; }
.stat-label { font-size: 0.875rem; color: var(--text-secondary); font-weight: 500; text-transform: uppercase; }
.stat-value { font-size: 2.5rem; font-weight: 700; font-family: var(--font-mono); color: var(--text-primary); }
.stat-card.critical .stat-value { color: var(--accent-danger); }
.stat-card.high .stat-value { color: var(--accent-warning); }
.content-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 1.5rem; }
@media (max-width: 768px) { .content-grid { grid-template-columns: 1fr; } .main { padding: 1rem; } }
.card { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 12px; overflow: hidden; }
.card-header { padding: 1rem 1.5rem; border-bottom: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between; }
.card-title { font-size: 1rem; font-weight: 600; display: flex; align-items: center; gap: 0.5rem; }
.card-body { padding: 1rem; max-height: 400px; overflow: auto; }
.filter-bar { display: flex; gap: 0.5rem; margin-bottom: 1rem; flex-wrap: wrap; }
.filter-btn { padding: 0.25rem 0.75rem; border-radius: 20px; border: 1px solid var(--border-color); background: transparent; color: var(--text-secondary); font-size: 0.75rem; cursor: pointer; }
.filter-btn:hover, .filter-btn.active { background: var(--accent-primary); color: #000; border-color: var(--accent-primary); }
.data-list { display: flex; flex-direction: column; gap: 0.5rem; }
.data-item { background: rgba(17, 24, 39, 0.5); border: 1px solid var(--border-color); border-radius: 8px; padding: 0.75rem; font-family: var(--font-mono); font-size: 0.8125rem; word-break: break-all; }
.data-item:hover { border-color: var(--accent-primary); background: rgba(0, 240, 255, 0.05); }
.badge { padding: 0.125rem 0.5rem; border-radius: 4px; font-size: 0.6875rem; font-weight: 700; text-transform: uppercase; }
.badge-critical { background: rgba(255, 0, 68, 0.2); color: var(--accent-danger); border: 1px solid var(--accent-danger); }
.badge-high { background: rgba(255, 170, 0, 0.2); color: var(--accent-warning); border: 1px solid var(--accent-warning); }
.badge-medium { background: rgba(0, 255, 136, 0.2); color: var(--accent-success); border: 1px solid var(--accent-success); }
.badge-tech { background: rgba(112, 0, 255, 0.2); color: #a78bfa; border: 1px solid #a78bfa; }
.vuln-item { background: rgba(17, 24, 39, 0.5); border: 1px solid var(--border-color); border-radius: 8px; padding: 1rem; margin-bottom: 0.5rem; }
.vuln-item:hover { border-color: var(--accent-primary); box-shadow: 0 0 10px rgba(0, 240, 255, 0.1); }
.vuln-header { display: flex; align-items: flex-start; gap: 0.75rem; margin-bottom: 0.5rem; }
.vuln-title { flex: 1; font-weight: 600; }
.vuln-url { font-size: 0.75rem; color: var(--accent-primary); font-family: var(--font-mono); word-break: break-all; }
.vuln-tags { display: flex; gap: 0.25rem; flex-wrap: wrap; margin-top: 0.5rem; }
.tag { padding: 0.125rem 0.375rem; background: rgba(0, 240, 255, 0.1); border: 1px solid rgba(0, 240, 255, 0.3); border-radius: 4px; font-size: 0.6875rem; color: var(--accent-primary); }
.chart-container { position: relative; height: 250px; padding: 1rem; }
.search-box { width: 100%; padding: 0.5rem 1rem; background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: 6px; color: var(--text-primary); font-family: var(--font-mono); font-size: 0.875rem; margin-bottom: 1rem; }
.search-box:focus { outline: none; border-color: var(--accent-primary); box-shadow: 0 0 0 3px rgba(0, 240, 255, 0.1); }
.empty-state { text-align: center; padding: 3rem; color: var(--text-muted); }
::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: var(--bg-secondary); }
::-webkit-scrollbar-thumb { background: var(--border-color); border-radius: 4px; }
</style>
</head>
<body>
<header class="header">
    <div class="brand">
        <div class="brand-icon">⚡</div>
        <div class="brand-text">
            <h1>BBR v1.0</h1>
            <span>Cyber Reconnaissance Dashboard</span>
        </div>
    </div>
    <div class="header-controls">
        <div class="target-selector">
            <label>🎯 Target:</label>
            <select id="target-select" onchange="loadTarget(this.value)"><option>Loading...</option></select>
        </div>
        <button class="btn btn-primary" onclick="refresh()">↻ Refresh</button>
        <span id="last-refresh" style="color:var(--text-muted);font-size:0.75rem;">--:--:--</span>
    </div>
</header>
<main class="main">
    <div class="stats-grid">
        <div class="stat-card"><div class="stat-header"><span class="stat-label">Subdomains</span><span>🌐</span></div><div class="stat-value" id="stat-subdomains">--</div></div>
        <div class="stat-card"><div class="stat-header"><span class="stat-label">Alive Hosts</span><span>✅</span></div><div class="stat-value" id="stat-alive">--</div></div>
        <div class="stat-card"><div class="stat-header"><span class="stat-label">URLs</span><span>🔗</span></div><div class="stat-value" id="stat-urls">--</div></div>
        <div class="stat-card"><div class="stat-header"><span class="stat-label">Open Ports</span><span>🔌</span></div><div class="stat-value" id="stat-ports">--</div></div>
        <div class="stat-card critical"><div class="stat-header"><span class="stat-label">Critical</span><span>🚨</span></div><div class="stat-value" id="stat-critical">--</div></div>
        <div class="stat-card high"><div class="stat-header"><span class="stat-label">High</span><span>⚠️</span></div><div class="stat-value" id="stat-high">--</div></div>
        <div class="stat-card medium"><div class="stat-header"><span class="stat-label">Medium</span><span>🔶</span></div><div class="stat-value" id="stat-medium">--</div></div>
        <div class="stat-card low"><div class="stat-header"><span class="stat-label">Low</span><span>ℹ️</span></div><div class="stat-value" id="stat-low">--</div></div>
    </div>
    <div class="content-grid">
        <div class="card"><div class="card-header"><div class="card-title">📊 Vulnerability Distribution</div></div><div class="chart-container"><canvas id="vulnChart"></canvas></div></div>
        <div class="card"><div class="card-header"><div class="card-title">🛠️ Technologies</div></div><div class="chart-container"><canvas id="techChart"></canvas></div></div>
        <div class="card">
            <div class="card-header"><div class="card-title">🐛 Vulnerabilities</div><div class="filter-bar"><button class="filter-btn active" onclick="filterVulns('all')">All</button><button class="filter-btn" onclick="filterVulns('critical')">Critical</button><button class="filter-btn" onclick="filterVulns('high')">High</button></div></div>
            <div class="card-body" id="vuln-list"><div class="empty-state">No vulnerabilities found</div></div>
        </div>
        <div class="card">
            <div class="card-header"><div class="card-title">🌐 Alive Hosts</div><input type="text" class="search-box" placeholder="Search hosts..." onkeyup="searchHosts(this.value)"></div>
            <div class="card-body" id="alive-list"><div class="empty-state">No alive hosts</div></div>
        </div>
        <div class="card">
            <div class="card-header"><div class="card-title">📋 Subdomains</div><input type="text" class="search-box" placeholder="Filter subdomains..." onkeyup="filterSubdomains(this.value)"></div>
            <div class="card-body"><div class="data-list" id="subdomain-list"><div class="empty-state">No subdomains</div></div></div>
        </div>
        <div class="card">
            <div class="card-header"><div class="card-title">🔗 URLs</div></div>
            <div class="card-body"><div class="data-list" id="url-list"><div class="empty-state">No URLs</div></div></div>
        </div>
    </div>
</main>
<script>
let vulnChart=null, techChart=null, currentData=null, currentVulnFilter='all';
async function fetchTargets(){ try{ const r=await fetch('/api/targets'); return await r.json(); }catch(e){ return []; } }
async function fetchData(target){ try{ const r=await fetch('/api/data?target='+encodeURIComponent(target)); return await r.json(); }catch(e){ return null; } }
function sev(s){ return s?s.toLowerCase():'info'; }
function updateStats(summary){
    document.getElementById('stat-subdomains').textContent=summary.subdomains||0;
    document.getElementById('stat-alive').textContent=summary.alive||0;
    document.getElementById('stat-urls').textContent=summary.urls||0;
    document.getElementById('stat-ports').textContent=summary.ports||0;
    const sev=summary.severity||{};
    document.getElementById('stat-critical').textContent=sev.critical||0;
    document.getElementById('stat-high').textContent=sev.high||0;
    document.getElementById('stat-medium').textContent=sev.medium||0;
    document.getElementById('stat-low').textContent=sev.low||0;
}
function renderVulnChart(severity){
    const ctx=document.getElementById('vulnChart').getContext('2d');
    const data=[severity.critical||0, severity.high||0, severity.medium||0, severity.low||0, severity.info||0];
    if(vulnChart)vulnChart.destroy();
    vulnChart=new Chart(ctx,{type:'doughnut',data:{labels:['Critical','High','Medium','Low','Info'],datasets:[{data:data,backgroundColor:['#ff0044','#ffaa00','#00ff88','#0099ff','#6b7280'],borderWidth:0}]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{position:'right',labels:{color:'#9ca3af',font:{family:'Inter',size:11}}}},cutout:'70%'}});
}
function renderTechChart(technologies){
    const ctx=document.getElementById('techChart').getContext('2d');
    const labels=Object.keys(technologies).slice(0,8);
    const data=Object.values(technologies).slice(0,8);
    if(techChart)techChart.destroy();
    if(labels.length===0)return;
    techChart=new Chart(ctx,{type:'bar',data:{labels:labels,datasets:[{label:'Hosts',data:data,backgroundColor:'rgba(0,240,255,0.6)',borderColor:'#00f0ff',borderWidth:1,borderRadius:4}]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},scales:{y:{beginAtZero:true,grid:{color:'rgba(55,65,81,0.5)'},ticks:{color:'#9ca3af'}},x:{grid:{display:false},ticks:{color:'#9ca3af'}}}}});
}
function renderVulns(vulns){
    const container=document.getElementById('vuln-list');
    if(!vulns||vulns.length===0){ container.innerHTML='<div class="empty-state">No vulnerabilities found</div>'; return; }
    let filtered=vulns;
    if(currentVulnFilter!=='all') filtered=vulns.filter(v=>sev(v.severity)===currentVulnFilter);
    if(filtered.length===0){ container.innerHTML='<div class="empty-state">No '+currentVulnFilter+' severity findings</div>'; return; }
    container.innerHTML=filtered.slice(0,50).map(v=>{
        const tags=(v.tags||[]).map(t=>'<span class="tag">'+t+'</span>').join('');
        const refs=(v.reference||[]).slice(0,2).map(r=>'<a href="'+r+'" target="_blank" style="color:var(--accent-primary);font-size:0.7rem;">[ref]</a>').join(' ');
        return '<div class="vuln-item"><div class="vuln-header"><span class="badge badge-'+sev(v.severity)+'">'+sev(v.severity)+'</span><span class="vuln-title">'+(v.name||v.template||'Unknown')+'</span></div><div class="vuln-url">'+(v.url||v.host||'')+'</div>'+(v.description?'<div style="color:var(--text-secondary);font-size:0.8rem;margin-top:0.25rem;">'+v.description+'</div>':'')+'<div style="margin-top:0.5rem;">'+(v.type?'<span class="badge badge-info">'+v.type+'</span>':'')+(v.template?'<span class="badge badge-info">'+v.template+'</span>':'')+refs+'</div>'+(tags?'<div class="vuln-tags">'+tags+'</div>':'')+'</div>';
    }).join('');
}
function filterVulns(severity){ currentVulnFilter=severity; document.querySelectorAll('.filter-btn').forEach(btn=>{ btn.classList.remove('active'); if(btn.textContent.toLowerCase().includes(severity)||(severity==='all'&&btn.textContent==='All')) btn.classList.add('active'); }); if(currentData) renderVulns(currentData.vulns); }
function renderAlive(hosts){
    const container=document.getElementById('alive-list');
    if(!hosts||hosts.length===0){ container.innerHTML='<div class="empty-state">No alive hosts</div>'; return; }
    container.innerHTML='<div class="data-list">'+hosts.slice(0,100).map(h=>{
        const status=h.status||'';
        const statusClass=status.startsWith('2')?'badge-medium':status.startsWith('3')?'badge-info':status.startsWith('4')?'badge-high':'badge-low';
        return '<div class="data-item"><div style="display:flex;align-items:center;gap:0.5rem;"><span style="color:var(--accent-primary);font-weight:600;flex:1;">'+(h.url||h.raw||'')+'</span>'+(status?'<span class="badge '+statusClass+'">'+status+'</span>':'')+'</div>'+(h.title?'<div style="color:var(--text-secondary);font-size:0.75rem;">'+h.title+'</div>':'')+(h.tech?'<div style="display:flex;gap:0.5rem;flex-wrap:wrap;margin-top:0.25rem;">'+h.tech.split(',').map(t=>'<span class="badge badge-tech">'+t.trim()+'</span>').join('')+'</div>':'')+'</div>';
    }).join('')+'</div>';
}
function searchHosts(query){ if(!currentData||!currentData.alive) return; const filtered=currentData.alive.filter(h=>(h.url||'').toLowerCase().includes(query.toLowerCase())||(h.tech||'').toLowerCase().includes(query.toLowerCase())); renderAlive(filtered); }
function renderSubdomains(subdomains){ const container=document.getElementById('subdomain-list'); if(!subdomains||subdomains.length===0){ container.innerHTML='<div class="empty-state">No subdomains</div>'; return; } container.innerHTML=subdomains.slice(0,200).map(s=>'<div class="data-item">'+s+'</div>').join(''); }
function filterSubdomains(query){ if(!currentData||!currentData.subdomains) return; const filtered=currentData.subdomains.filter(s=>s.toLowerCase().includes(query.toLowerCase())); renderSubdomains(filtered); }
function renderUrls(urls){ const container=document.getElementById('url-list'); if(!urls||urls.length===0){ container.innerHTML='<div class="empty-state">No URLs</div>'; return; } container.innerHTML='<div class="data-list">'+urls.slice(0,150).map(u=>'<div class="data-item">'+u+'</div>').join('')+'</div>'; }
async function loadTarget(target){
    if(!target) return;
    document.getElementById('vuln-list').innerHTML='<div style="text-align:center;padding:2rem;color:var(--text-muted);">Loading...</div>';
    const data=await fetchData(target);
    if(!data){ document.getElementById('vuln-list').innerHTML='<div class="empty-state">Failed to load</div>'; return; }
    currentData=data;
    updateStats(data.summary);
    renderVulnChart(data.summary.severity||{});
    renderTechChart(data.summary.technologies||{});
    renderVulns(data.vulns||[]);
    renderAlive(data.alive||[]);
    renderSubdomains(data.subdomains||[]);
    renderUrls(data.urls||[]);
    document.getElementById('last-refresh').textContent=new Date().toLocaleTimeString();
}
async function refresh(){ const sel=document.getElementById('target-select'); if(sel.value&&sel.value!=='Loading...') await loadTarget(sel.value); }
async function init(){
    const targets=await fetchTargets();
    const sel=document.getElementById('target-select');
    if(!targets||targets.length===0){ sel.innerHTML='<option>No scans found</option>'; return; }
    sel.innerHTML=targets.map(t=>'<option value="'+t+'">'+t+'</option>').join('');
    await loadTarget(targets[0]);
}
init();
setInterval(refresh, 30000);
</script>
</body>
</html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send_json(self, data, code=200):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if parsed.path == '/api/targets':
            self.send_json(get_targets())
        elif parsed.path == '/api/data':
            target = params.get('target', [''])[0]
            if not target:
                self.send_json({'error': 'missing target'}, 400)
                return
            self.send_json(get_data(target))
        elif parsed.path in ['/', '/index.html']:
            body = HTML.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.send_header('Content-Length', len(body))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()


if __name__ == '__main__':
    server = http.server.HTTPServer(('0.0.0.0', PORT), Handler)
    print(f"BBR Dashboard running on http://0.0.0.0:{PORT}")
    server.serve_forever()