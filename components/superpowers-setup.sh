#!/usr/bin/env bash
# superpowers setup for Hermes Stack
# Agentic skills framework & software development methodology for Claude Code
# Installed via Claude Code plugin marketplace (claude-plugins-official)
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_superpowers() {
    log "Checking Superpowers (agentic dev methodology)..."

    # Superpowers is installed via Claude Code plugin marketplace
    # Check if it's already enabled in settings
    if grep -q '"superpowers@claude-plugins-official"' "$HOME/.claude/settings.json" 2>/dev/null; then
        ok "Superpowers v5.1.0 already installed and enabled (Claude Code plugin)"
        return 0
    fi

    warn "Superpowers not yet activated via plugin marketplace"
    warn "To install: open Claude Code and run:"
    warn '  /plugin marketplace add claude-plugins-official'
    warn '  /plugin install superpowers'
    warn "Or add to settings.json manually:"
    warn '  "enabledPlugins": { "superpowers@claude-plugins-official": true }'

    # Offer to enable it directly
    if grep -q "enabledPlugins" "$HOME/.claude/settings.json" 2>/dev/null; then
        # Try to add it to settings.json programmatically
        local settings="$HOME/.claude/settings.json"
        # Check if marketplace is registered
        if ! grep -q "claude-plugins-official" "$settings" 2>/dev/null; then
            log "Registering claude-plugins-official marketplace..."
            # This needs careful JSON manipulation — skip for now, let Claude Code handle it
            warn "Plugin marketplace registration requires Claude Code UI. Run the commands above."
        fi
    fi
}

install_superpowers