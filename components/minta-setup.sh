#!/usr/bin/env bash
# Minta Setup — self-correcting AI memory engine with MCP
# Detects stale, conflicting, and redundant memory. Zero LLM cost. MIT license.
# https://github.com/xinchen03/minta
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[minta]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

TOOLS_DIR="${HERMES_TOOLS_DIR:-$HOME/.tools}"
MINTA_DIR="$TOOLS_DIR/minta"

install_minta() {
    log "Installing Minta (self-correcting AI memory engine)..."

    # Check if already installed
    if [[ -d "$MINTA_DIR" ]] && [[ -f "$MINTA_DIR/minta_cli.py" ]]; then
        ok "Minta already installed at $MINTA_DIR"
        return 0
    fi

    log "Cloning Minta repository..."
    mkdir -p "$TOOLS_DIR"
    if git clone https://github.com/xinchen03/minta.git "$MINTA_DIR" 2>/dev/null; then
        ok "Minta repository cloned"
    else
        if [[ -d "$MINTA_DIR" ]]; then
            ok "Minta directory already exists — using existing clone"
        else
            warn "git clone failed — check your network connection"
            return 1
        fi
    fi

    # Install Python dependencies
    log "Installing Python dependencies (sentence-transformers, chromadb, etc.)..."
    cd "$MINTA_DIR"
    if [[ -f "requirements.txt" ]]; then
        if pip install -r requirements.txt 2>/dev/null || pip3 install -r requirements.txt 2>/dev/null; then
            ok "Minta dependencies installed"
        else
            warn "Some dependencies failed — Minta may have limited functionality"
            warn "Try: cd $MINTA_DIR && pip install -r requirements.txt"
        fi
    fi

    # Create .env template if missing
    if [[ ! -f "$MINTA_DIR/.env" ]]; then
        cp "$MINTA_DIR/.env.example" "$MINTA_DIR/.env" 2>/dev/null || true
        # Generate a random JWT secret
        if command -v openssl &>/dev/null; then
            local secret
            secret=$(openssl rand -hex 32)
            sed -i "s/change-to-a-random-string/$secret/" "$MINTA_DIR/.env" 2>/dev/null || true
        fi
        warn "Minta .env created — edit $MINTA_DIR/.env to customize settings"
    fi

    ok "Minta installed at $MINTA_DIR"
}

configure_mcp() {
    log "Configuring Minta MCP server for Claude Code..."

    # Check if Minta MCP is already configured
    if grep -q "minta" "$HOME/.claude/mcp.json" 2>/dev/null; then
        ok "Minta MCP already configured in Claude Code"
        return 0
    fi

    local python_cmd="python3"
    if command -v python3 &>/dev/null; then
        python_cmd="python3"
    elif command -v python &>/dev/null; then
        python_cmd="python"
    fi

    # Add Minta MCP server to Claude Code
    mkdir -p "$(dirname "$HOME/.claude/mcp.json")"
    if [[ -f "$HOME/.claude/mcp.json" ]]; then
        # Check if it's empty or valid JSON
        if [[ ! -s "$HOME/.claude/mcp.json" ]]; then
            echo '{"mcpServers":{}}' > "$HOME/.claude/mcp.json"
        fi
        warn "Add Minta MCP to Claude Code manually or run:"
        warn "  cd $MINTA_DIR && $python_cmd minta_cli.py connect"
    else
        mkdir -p "$HOME/.claude"
        echo '{"mcpServers":{}}' > "$HOME/.claude/mcp.json"
        warn "Created mcp.json — run the connect command above to configure Minta"
    fi

    warn ""
    warn "To complete setup:"
    warn "  1. cd $MINTA_DIR"
    warn "  2. $python_cmd minta_cli.py start          # Start the Minta server"
    warn "  3. Open http://localhost:8772 — register an account"
    warn "  4. Copy API key from Settings → click copy"
    warn "  5. $python_cmd minta_cli.py connect        # Auto-configure MCP"
    warn "  6. $python_cmd minta_cli.py verify         # Verify everything works"
    warn ""
    warn "Minta gives Claude Code: conflict detection, staleness detection,"
    warn "redundancy detection, and memory health scoring — all with zero LLM cost."
}

verify_install() {
    if [[ -d "$MINTA_DIR" ]] && [[ -f "$MINTA_DIR/minta_cli.py" ]]; then
        ok "Minta installed successfully"
        log "  Location: $MINTA_DIR"
        log "  Start:    $MINTA_DIR/minta_cli.py start"
        log "  Connect:  $MINTA_DIR/minta_cli.py connect"
        log "  Verify:   $MINTA_DIR/minta_cli.py verify"
    else
        warn "Minta not fully installed — check $MINTA_DIR"
    fi
}

main() {
    install_minta
    configure_mcp
    verify_install
}

main "$@"