#!/usr/bin/env bash
# Context7 Setup — version-specific documentation for AI coding agents
# Eliminates hallucinated APIs. 56K+ stars. MIT license.
# https://github.com/upstash/context7
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[context7]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_context7() {
    log "Installing Context7 (version-specific docs for AI agents)..."

    # Check if already installed
    if command -v ctx7 &>/dev/null; then
        local ver
        ver=$(ctx7 --version 2>/dev/null || echo "installed")
        ok "Context7 CLI $ver already installed"
        if grep -q "context7" "$HOME/.claude/mcp.json" 2>/dev/null || \
           grep -q "context7" "$HOME/.claude/settings.json" 2>/dev/null; then
            ok "Context7 already configured in Claude Code"
            return 0
        fi
        warn "Context7 CLI found but may not be configured — running setup..."
    fi

    log "Running Context7 setup wizard..."
    log "This will authenticate via OAuth and configure MCP/CLI mode."
    log "You can also get a free API key at https://context7.com/dashboard"

    if npx ctx7 setup 2>/dev/null; then
        ok "Context7 setup complete — authenticated and configured"
    else
        warn "npx ctx7 setup did not complete interactively (expected in non-TTY)"
        warn "Run 'npx ctx7 setup' manually in a terminal to complete setup"
        warn ""
        warn "For manual config, add to ~/.claude/mcp.json:"
        warn '  "context7": {'
        warn '    "command": "npx",'
        warn '    "args": ["-y", "@upstash/context7-mcp"],'
        warn '    "env": { "CONTEXT7_API_KEY": "your-key-here" }'
        warn '  }'
        warn ""
        warn "Get a free key at: https://context7.com/dashboard"
    fi

    ok "Context7 ready. In Claude Code, just add 'use context7' to any prompt."
}

verify_cli() {
    if command -v ctx7 &>/dev/null; then
        ok "Context7 CLI available"
        log "  Run 'ctx7 library <query>' to search for docs"
        log "  In Claude Code: 'How do I use Next.js 14 middleware? use context7'"
    fi
}

main() {
    install_context7
    verify_cli

    log ""
    log "Context7 quick start:"
    log "  In any Claude Code prompt, append 'use context7' or 'use library /nextjs/next.js'"
    log "  CLI: ctx7 library 'next.js middleware'  →  ctx7 docs /nextjs/next.js"
    log "  It indexes version-specific docs from 1000s of libraries — no more hallucinated APIs"
    log ""
}

main "$@"
