#!/usr/bin/env bash
# compound-engineering setup for Hermes Stack
# EveryInc's Compound Engineering plugin — structured AI development workflow
# Adds brainstorm → plan → work → review → compound agent skills to Claude Code
# 18K+ stars, MIT license.
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

setup_compound_engineering() {
    log "Setting up Compound Engineering plugin..."

    # Check for Claude Code
    if ! command -v claude &>/dev/null; then
        warn "claude command not found — cannot install plugin interactively"
        warn "Install Claude Code first, then run these commands manually:"
        log ""
        log "  claude plugin marketplace add EveryInc/compound-engineering-plugin"
        log "  claude plugin install compound-engineering"
        log ""
        log "Then in any project, run /ce-setup to configure."
        return 0
    fi

    # Check if already installed
    if claude plugin list 2>/dev/null | grep -q "compound-engineering"; then
        ok "Compound Engineering plugin already installed"
        return 0
    fi

    log "Installing Compound Engineering plugin for Claude Code..."
    log "This requires interactive approval — checking..."

    # Try non-interactive marketplace add
    if claude plugin marketplace add EveryInc/compound-engineering-plugin 2>/dev/null; then
        ok "Marketplace added"
        if claude plugin install compound-engineering 2>/dev/null; then
            ok "Compound Engineering plugin installed"
            log "Run '/ce-setup' in any project to bootstrap"
        else
            warn "Plugin install may require interactive approval"
            warn "Run manually: claude plugin install compound-engineering"
        fi
    else
        warn "Could not add marketplace non-interactively"
        warn "Run manually when Claude Code is available:"
        log ""
        log "  claude plugin marketplace add EveryInc/compound-engineering-plugin"
        log "  claude plugin install compound-engineering"
    fi
}

main() {
    setup_compound_engineering

    log ""
    log "Compound Engineering workflow:"
    log "  /ce-brainstorm  — explore requirements"
    log "  /ce-plan        — create implementation plans"
    log "  /ce-work        — execute plans"
    log "  /ce-code-review — multi-agent code review"
    log "  /ce-compound    — document learnings"
    log ""
    log "Philosophy: 80% planning + review, 20% execution."
    log "Each unit of work makes the next one easier."
}

main "$@"
