#!/usr/bin/env bash
# superpowers-setup.sh — obra/superpowers agentic skills framework
# Full software development methodology for coding agents
# Installed via Claude Code plugin marketplace
# 229K+ stars, MIT license
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }
err()   { printf "\033[31m[fail]\033[0m %s\n" "$*" >&2; }

install_superpowers() {
    log "Installing Superpowers (agentic dev methodology)..."

    # Superpowers can be installed via Claude Code plugin OR directly as skills
    # We prefer the direct install method for automation

    local target_dir="$HOME/.claude/skills"
    mkdir -p "$target_dir"

    # Check if already installed via plugin marketplace
    if [[ -f "$HOME/.claude/settings.json" ]]; then
        if grep -q '"superpowers@claude-plugins-official"' "$HOME/.claude/settings.json" 2>/dev/null; then
            ok "Superpowers already installed and enabled (Claude Code plugin)"
            
            # Check for updates
            log "Checking for Superpowers update..."
            if command -v claude &>/dev/null; then
                # Latest version check
                local plugin_dir
                plugin_dir=$(find "$HOME/.claude/plugins" -name "*superpowers*" -type d 2>/dev/null | head -1)
                if [[ -n "$plugin_dir" && -f "$plugin_dir/version.txt" ]]; then
                    local installed_version
                    installed_version=$(cat "$plugin_dir/version.txt")
                    log "Installed version: $installed_version"
                fi
            fi
            return 0
        fi
    fi

    # Direct install: clone superpowers repo and link skills
    log "Installing Superpowers skills directly..."
    local clone_dir="/tmp/superpowers-install"
    
    if [[ -d "$clone_dir" ]]; then
        rm -rf "$clone_dir"
    fi

    if git clone --depth 1 https://github.com/obra/superpowers.git "$clone_dir" 2>/dev/null; then
        ok "Superpowers repository cloned"
        
        # Copy skills to Claude Code skills directory
        if [[ -d "$clone_dir/skills" ]]; then
            cp -r "$clone_dir/skills/"* "$target_dir/" 2>/dev/null || true
            ok "Superpowers skills installed to $target_dir"
        fi
        
        # Also install the init instructions
        if [[ -f "$clone_dir/INSTRUCTIONS.md" ]]; then
            cp "$clone_dir/INSTRUCTIONS.md" "$HOME/.claude/superpowers-instructions.md" 2>/dev/null || true
        fi
        
        rm -rf "$clone_dir"
    else
        warn "Could not clone superpowers repo directly"
        warn "Alternative: install via Claude Code plugin marketplace:"
        warn "  /plugin marketplace add claude-plugins-official"
        warn "  /plugin install superpowers"
    fi

    # Try plugin marketplace registration via settings.json
    if [[ -f "$HOME/.claude/settings.json" ]]; then
        if ! grep -q "claude-plugins-official" "$HOME/.claude/settings.json" 2>/dev/null; then
            log "Registering claude-plugins-official marketplace..."
            # We can't safely edit JSON from bash — warn user instead
            warn "Run this in Claude Code to complete setup:"
            warn "  /plugin marketplace add claude-plugins-official"
            warn "  /plugin install superpowers"
        fi
    fi

    ok "Superpowers setup complete"
    log "Available slash commands after Claude Code restart:"
    log "  /brainstorming — Socratic design refinement"
    log "  /writing-plans — Detailed implementation plans"
    log "  /test-driven-development — RED-GREEN-REFACTOR cycle"
    log "  /subagent-driven-development — Parallel subagent dispatch"
    log "  /systematic-debugging — Root-cause analysis before fixes"
    log "  /requesting-code-review — Pre-review checklist"
    log "  /dispatching-parallel-agents — Concurrent subagent workflows"
}

install_superpowers