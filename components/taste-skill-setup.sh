#!/usr/bin/env bash
# taste-skill setup for Hermes Stack
# Anti-slop frontend framework - makes AI-generated UIs look professional
set -euo pipefail

SKILLS_DIR="${HERMES_SKILLS_DIR:-$HOME/.claude/skills}"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_taste_skill() {
    log "Installing taste-skill..."

    if [[ -f "$SKILLS_DIR/taste-skill/SKILL.md" ]]; then
        ok "taste-skill already installed"
        return 0
    fi

    mkdir -p "$SKILLS_DIR/taste-skill"

    # Clone the full repo for access to all skill variants
    local tmp_dir="/tmp/taste-skill-install"
    git clone https://github.com/Leonxlnx/taste-skill.git "$tmp_dir" 2>/dev/null

    if [[ -f "$tmp_dir/taste-skill/SKILL.md" ]]; then
        cp "$tmp_dir/taste-skill/SKILL.md" "$SKILLS_DIR/taste-skill/"
        # Also copy v1 as a fallback
        mkdir -p "$SKILLS_DIR/taste-skill-v1"
        cp "$tmp_dir/taste-skill-v1/SKILL.md" "$SKILLS_DIR/taste-skill-v1/" 2>/dev/null || true
        rm -rf "$tmp_dir"
        ok "taste-skill installed ($(wc -l < "$SKILLS_DIR/taste-skill/SKILL.md") lines)"
    else
        warn "Could not install taste-skill from clone, trying direct download..."
        curl -fsSL -o "$SKILLS_DIR/taste-skill/SKILL.md" \
            https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/taste-skill/SKILL.md 2>/dev/null && \
            ok "taste-skill installed via direct download" || \
            warn "taste-skill download failed"
    fi
}

install_taste_skill
ok "taste-skill ready. Activates automatically on frontend work."