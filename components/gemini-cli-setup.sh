#!/usr/bin/env bash
# Gemini CLI Setup — Google's open-source terminal AI agent
# Free Gemini 2.5 Pro access with 1M token context, 60 req/min, 1000 req/day
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

# Colors
C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[gemini-cli]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_gemini_cli() {
    log "Installing Gemini CLI (Google's open-source terminal AI agent)..."

    # Check if already installed
    if command -v gemini &>/dev/null; then
        local current_version
        current_version=$(gemini --version 2>/dev/null || echo "unknown")
        ok "Gemini CLI already installed (v$current_version)"
        log "Updating to latest..."
        npm update -g @google/gemini-cli 2>/dev/null && ok "Gemini CLI updated" || warn "Update skipped"
        return 0
    fi

    # Install via npm
    if command -v npm &>/dev/null; then
        npm install -g @google/gemini-cli && \
            ok "Gemini CLI installed via npm" || {
            warn "npm install failed — try: npm install -g @google/gemini-cli"
            return 1
        }
    else
        warn "npm not found — install Node.js first, then run: npm install -g @google/gemini-cli"
        return 1
    fi

    # Verify
    if command -v gemini &>/dev/null; then
        local version
        version=$(gemini --version 2>/dev/null || echo "unknown")
        ok "Gemini CLI v$version installed"
        log "Run 'gemini' to start — sign in with Google account for free tier"
        log "Free: Gemini 2.5 Pro, 1M context, 60 req/min, 1000 req/day"
    fi
}

# Configure as Claude Code fallback coding agent
configure_gemini_in_stack() {
    log "Configuring Gemini CLI as backup coding agent..."

    local CLAUDE_DIR="${HOME}/.claude"
    local CLAUDE_FILE="${CLAUDE_DIR}/CLAUDE.md"

    if [[ -f "$CLAUDE_FILE" ]]; then
        if ! grep -q "Gemini CLI" "$CLAUDE_FILE" 2>/dev/null; then
            cat >> "$CLAUDE_FILE" <<'EOF'

## Backup Coding Agent

Gemini CLI (gemini) is available as a free backup coding agent. Use it when:
- Claude Code is unavailable or rate-limited
- You need Google Search grounding for real-time info
- Working with 1M+ token context windows
- Running parallel analysis tasks

Install: npm install -g @google/gemini-cli
Auth: gemini (follow browser OAuth)
Free tier: 60 req/min, 1000 req/day, Gemini 2.5 Pro
EOF
            ok "Gemini CLI added to CLAUDE.md"
        else
            ok "Gemini CLI already referenced in CLAUDE.md"
        fi
    else
        warn "CLAUDE.md not found — skipping config (install Claude Code first)"
    fi
}

install_gemini_cli
configure_gemini_in_stack
ok "Gemini CLI setup complete"