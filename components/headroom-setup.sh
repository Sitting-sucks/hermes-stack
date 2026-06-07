#!/usr/bin/env bash
# Headroom Setup — context compression for AI agents
# Compresses tool outputs, logs, files, RAG chunks before LLM. 60-95% fewer tokens.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

# Colors (borrowed from main installer)
C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[headroom]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_headroom() {
    log "Installing Headroom (context compression for AI agents)..."

    # Python package — recommended install with proxy extras (enables compression pipeline)
    if python3 -c "import headroom" 2>/dev/null; then
        ok "Headroom Python package already installed"
    else
        if pip install "headroom-ai[proxy,mcp]" 2>/dev/null || \
           pip3 install "headroom-ai[proxy,mcp]" 2>/dev/null; then
            ok "Headroom Python package installed (proxy + mcp extras)"
        else
            warn "pip install with extras failed — trying proxy-only"
            if pip install "headroom-ai[proxy]" 2>/dev/null || pip3 install "headroom-ai[proxy]" 2>/dev/null; then
                ok "Headroom installed with proxy extras"
            else
                warn "pip install failed — trying minimal install"
                if pip install headroom-ai 2>/dev/null || pip3 install headroom-ai 2>/dev/null; then
                    ok "Headroom minimal install succeeded (run 'pip install headroom-ai[proxy]' later for full compression)"
                else
                    warn "Headroom install failed — skipping (non-critical)"
                    return 1
                fi
            fi
        fi
    fi

    # Try MCP server install for Claude Code
    if command -v headroom &>/dev/null; then
        log "Installing Headroom MCP server for Claude Code..."
        headroom mcp install 2>/dev/null || \
            warn "Headroom MCP auto-install skipped (Claude Code may not be configured yet)"
        ok "Headroom CLI available — run 'headroom mcp install' later to hook it up"
    else
        warn "headroom CLI not in PATH — MCP auto-install skipped"
    fi

    ok "Headroom setup complete"
}

install_headroom
