#!/usr/bin/env bash
# mcp-x-intelligence Setup — X/Twitter Research MCP for AI Agents
# Read-only research: viral content search, account analysis, trending topics, niche leaders
# Powered by twitterapi.io — no OAuth, no developer account needed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

# Colors (borrowed from main installer)
C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[x-intel]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_mcp_x_intelligence() {
    log "Installing mcp-x-intelligence (X/Twitter Research MCP)..."

    # No local build needed — this is a hosted MCP server via npx mcp-remote
    # Just verify npx is available
    if ! command -v npx &>/dev/null; then
        warn "npx not found — please install Node.js (npm ships with it)"
        warn "mcp-x-intelligence requires npx to connect to the hosted endpoint"
        return 1
    fi

    ok "npx available — mcp-x-intelligence ready to configure"
    ok "No local build needed (hosted Cloudflare Worker endpoint)"
}

configure_mcp_x_intelligence() {
    log "To configure mcp-x-intelligence with Claude Code, you need a twitterapi.io API key."
    log ""
    log "1. Get a free API key at: https://twitterapi.io"
    log "   (Free tier: $0.10 in credits, pay-per-use at $0.15/1K tweets)"
    log ""
    log "2. Run this command to add it to Claude Code:"
    log ""
    log "claude mcp add x-intelligence npx -- -y mcp-remote \\"
    log "  https://mcp-x-intelligence.fluyeporlaweb.workers.dev/mcp \\"
    log "  --header x-twitterapi-key:YOUR_TWITTERAPI_KEY"
    log ""
    log "3. Or for Claude Desktop, add to claude_desktop_config.json:"
    log ""
    log '{"mcpServers": {'
    log '  "x-intelligence": {'
    log '    "command": "npx",'
    log '    "args": ["-y", "mcp-remote",'
    log '      "https://mcp-x-intelligence.fluyeporlaweb.workers.dev/mcp",'
    log '      "--header", "x-twitterapi-key: YOUR_TWITTERAPI_KEY"]'
    log '  }'
    log '}}'
    log ""
    log "4. Restart client and verify: ask 'What X research tools do you have?'"
    log ""
    log "Available tools:"
    log "  - search_viral_content  — Find top posts by keyword with engagement filters"
    log "  - analyze_account       — Full profile analysis (followers, top posts, engagement)"
    log "  - get_trending_topics   — Trending topics by country in real time"
    log "  - get_niche_leaders     — Top accounts in any niche sorted by follower count"
}

install_mcp_x_intelligence
ok "mcp-x-intelligence setup complete. Configure with your twitterapi.io API key."