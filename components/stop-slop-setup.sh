#!/usr/bin/env bash
# stop-slop setup for Hermes Stack
# Removes AI tells from prose - makes content sound human
set -euo pipefail

SKILLS_DIR="${HERMES_SKILLS_DIR:-$HOME/.claude/skills}"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }

install_stop_slop() {
    log "Installing stop-slop skill..."

    if [[ -f "$SKILLS_DIR/stop-slop/SKILL.md" ]]; then
        ok "stop-slop already installed"
        return 0
    fi

    mkdir -p "$SKILLS_DIR/stop-slop/references"

    curl -fsSL -o "$SKILLS_DIR/stop-slop/SKILL.md" \
        https://raw.githubusercontent.com/hardikpandya/stop-slop/main/SKILL.md
    curl -fsSL -o "$SKILLS_DIR/stop-slop/references/phrases.md" \
        https://raw.githubusercontent.com/hardikpandya/stop-slop/main/references/phrases.md
    curl -fsSL -o "$SKILLS_DIR/stop-slop/references/structures.md" \
        https://raw.githubusercontent.com/hardikpandya/stop-slop/main/references/structures.md
    curl -fsSL -o "$SKILLS_DIR/stop-slop/references/examples.md" \
        https://raw.githubusercontent.com/hardikpandya/stop-slop/main/references/examples.md

    ok "stop-slop installed ($(wc -l < "$SKILLS_DIR/stop-slop/SKILL.md") lines)"
}

install_stop_slop
ok "stop-slop ready. Activate by asking Claude to 'run stop-slop on this' or reference it in prompts."