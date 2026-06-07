#!/usr/bin/env bash
# Hermes Stack — last30days-skill Integration Setup
# AI agent skill: research any topic across Reddit, X, YouTube, HN, Polymarket, GitHub
# https://github.com/mvanhorn/last30days-skill

set -euo pipefail

C_RESET='\033[0m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_CYAN='\033[36m'
C_BOLD='\033[1m'

log()   { printf "${C_CYAN}[hermes]${C_RESET} %s\n" "$*"; }
ok()    { printf "${C_GREEN}[ ok ]${C_RESET} %s\n" "$*"; }
warn()  { printf "${C_YELLOW}[warn]${C_RESET} %s\n" "$*"; }

main() {
    log "Setting up last30days-skill (cross-platform AI research)..."

    local skill_dir="$HOME/.claude/skills/last30days"
    local global_skills_dir="$HOME/.config/skills/last30days"

    # Try installing via npx skills (preferred method — auto-updates)
    if command -v npx &>/dev/null; then
        log "Installing via npx skills..."
        if npx skills add mvanhorn/last30days-skill -g --yes 2>/dev/null; then
            ok "last30days-skill installed via npx skills (global)"
            ok "last30days-skill linked for Claude Code"
            return 0
        else
            warn "npx skills install failed, falling back to git clone"
        fi
    fi

    # Fallback: git clone
    local clone_dir="$HOME/.hermes/last30days-skill"
    if [[ -d "$clone_dir" ]]; then
        ok "last30days-skill already cloned"
    else
        mkdir -p "$(dirname "$clone_dir")"
        git clone https://github.com/mvanhorn/last30days-skill.git "$clone_dir"
        ok "last30days-skill cloned"
    fi

    # Symlink into Claude Code skills
    mkdir -p "$HOME/.claude/skills"
    if [[ ! -L "$skill_dir" ]] && [[ ! -d "$skill_dir" ]]; then
        if [[ -d "$clone_dir/skills/last30days" ]]; then
            ln -s "$clone_dir/skills/last30days" "$skill_dir"
            ok "Symlinked last30days-skill into Claude Code skills"
        fi
    else
        ok "last30days-skill already linked for Claude Code"
    fi

    # Set up memory directory
    local memory_dir="$HOME/Documents/Last30Days"
    if [[ ! -d "$memory_dir" ]]; then
        mkdir -p "$memory_dir"
        ok "Created last30days memory directory at $memory_dir"
    fi

    ok "last30days-skill setup complete"
    log "First run will trigger a setup wizard for API keys (X, YouTube, etc.)"
    log "Usage: In Claude Code, type '/last30days <topic>' to research anything"
    log "Sources: Reddit (upvotes), X (engagement), YouTube (transcripts), HN, Polymarket, GitHub"
}

main "$@"