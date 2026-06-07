#!/usr/bin/env bash
# Caliber setup for Hermes Stack
# Auto-generates and maintains AI agent context files (CLAUDE.md, .cursorrules, MCP configs)
# for Claude Code, Cursor, Codex, OpenCode, GitHub Copilot.
# Prevents stale config drift — keeps AI agents grounded in your actual codebase.
# https://github.com/caliber-ai-org/ai-setup | @rely-ai/caliber
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_caliber() {
    log "Installing Caliber (AI context config generator)..."

    if command -v caliber &>/dev/null; then
        local ver
        ver=$(caliber --version 2>/dev/null || echo "unknown")
        ok "Caliber $ver already installed"
        return 0
    fi

    if npm install -g @rely-ai/caliber 2>/dev/null; then
        ok "Caliber installed"
    else
        warn "Caliber install failed — trying npx fallback"
        if npx @rely-ai/caliber --version &>/dev/null; then
            ok "Caliber available via npx"
        else
            warn "Caliber install failed — skipping (non-critical)"
            return 1
        fi
    fi
}

verify_cli() {
    if command -v caliber &>/dev/null; then
        ok "Caliber CLI available"
        log "  Run 'caliber init' in any project to generate AI configs"
        log "  Run 'caliber score' to check config quality"
        log "  Run 'caliber refresh' to update configs after code changes"
    fi
}

main() {
    install_caliber
    verify_cli

    log ""
    log "Caliber quick start:"
    log "  cd your-project"
    log "  caliber init              # full setup wizard"
    log "  caliber bootstrap         # install agent skills (2 sec)"
    log "  # Then in Claude Code:    /setup-caliber"
    log ""
    log "Keep configs fresh:"
    log "  caliber refresh           # after code changes"
    log "  caliber score             # check context health"
}

main "$@"