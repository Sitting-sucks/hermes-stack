#!/usr/bin/env bash
# agent-skills-setup.sh — Addy Osmani's production-grade engineering skills
# Installs agent-skills as a Hermes Agent skill + Claude Code plugin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_SKILLS_DIR="${HOME}/.hermes/skills"
AGENT_SKILLS_REPO="https://github.com/addyosmani/agent-skills.git"
AGENT_SKILLS_DIR="${HERMES_SKILLS_DIR}/agent-skills"

log()   { printf "[hermes] %s\n" "$*"; }
ok()    { printf "[ ok ] %s\n" "$*"; }
warn()  { printf "[warn] %s\n" "$*"; }

install_for_hermes() {
    log "Installing agent-skills for Hermes Agent..."
    mkdir -p "${HERMES_SKILLS_DIR}"

    if [[ -d "${AGENT_SKILLS_DIR}" ]]; then
        log "agent-skills already installed, updating..."
        cd "${AGENT_SKILLS_DIR}" && git pull --ff-only 2>/dev/null && ok "agent-skills updated" || warn "update failed"
        return 0
    fi

    git clone --depth 1 "${AGENT_SKILLS_REPO}" "${AGENT_SKILLS_DIR}" 2>/dev/null
    ok "agent-skills cloned to ${AGENT_SKILLS_DIR}"
}

install_for_claude() {
    if ! command -v claude &>/dev/null; then
        warn "Claude Code not found — skipping Claude plugin install"
        return 0
    fi
    log "Installing agent-skills for Claude Code..."
    claude plugin marketplace add addyosmani/agent-skills 2>/dev/null && \
        claude plugin install agent-skills@addy-agent-skills 2>/dev/null && \
        ok "agent-skills installed for Claude Code" || \
        warn "Claude Code plugin install failed (try manually: /plugin install agent-skills@addy-agent-skills)"
}

main() {
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  Agent Skills (addyosmani)                  │"
    echo "  │  Production-grade engineering skills        │"
    echo "  │  7 slash commands, 23 skills                │"
    echo "  └─────────────────────────────────────────────┘"
    echo ""

    install_for_hermes
    install_for_claude

    echo ""
    ok "Agent Skills ready."
    echo "  Skills: /spec, /plan, /build, /test, /review, /ship, /code-simplify"
    echo "  Docs:   https://addyosmani.com/blog/agent-skills/"
    echo ""
}

main