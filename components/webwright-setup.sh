#!/usr/bin/env bash
# webwright-setup.sh — Microsoft Webwright browser agent framework
# SOTA web agent: 86.7% on Online-Mind2Web, 60.1% on Odysseys
# Installs as a Hermes Agent skill + standalone CLI tool
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_SKILLS_DIR="${HOME}/.hermes/skills"
WEBWRIGHT_REPO="https://github.com/microsoft/Webwright.git"
WEBWRIGHT_DIR="${HOME}/.local/share/webwright"

log()   { printf "[hermes] %s\n" "$*"; }
ok()    { printf "[ ok ] %s\n" "$*"; }
warn()  { printf "[warn] %s\n" "$*"; }

install_webwright_cli() {
    log "Installing Webwright CLI..."

    if [[ -d "${WEBWRIGHT_DIR}" ]]; then
        log "Webwright already cloned, updating..."
        cd "${WEBWRIGHT_DIR}" && git pull --ff-only 2>/dev/null && ok "Webwright updated" || warn "update failed"
        return 0
    fi

    mkdir -p "$(dirname "${WEBWRIGHT_DIR}")"
    git clone --depth 1 "${WEBWRIGHT_REPO}" "${WEBWRIGHT_DIR}" 2>/dev/null

    cd "${WEBWRIGHT_DIR}"

    # Install Python dependencies
    if command -v pip3 &>/dev/null; then
        pip3 install -e . 2>/dev/null && ok "Webwright Python package installed" || \
            warn "Webwright pip install failed (try: pip install playwright)"
    fi

    # Install Playwright browsers
    if command -v playwright &>/dev/null; then
        playwright install chromium 2>/dev/null && ok "Playwright Chromium installed" || \
            warn "Playwright browser install failed (run: playwright install chromium)"
    fi

    ok "Webwright CLI ready — run: python -m webwright.run.cli ..."
}

install_for_hermes() {
    log "Installing Webwright skill for Hermes Agent..."

    mkdir -p "${HERMES_SKILLS_DIR}"

    local webwright_skills="${WEBWRIGHT_DIR}/skills/webwright"
    if [[ ! -d "${webwright_skills}" ]]; then
        warn "Webwright skills directory not found at ${webwright_skills}"
        return 1
    fi

    local symlink_target="${HERMES_SKILLS_DIR}/webwright"

    # Remove existing symlink or dir
    if [[ -L "${symlink_target}" ]] || [[ -d "${symlink_target}" ]]; then
        rm -rf "${symlink_target}"
    fi

    ln -sfn "${webwright_skills}" "${symlink_target}"
    ok "Webwright symlinked to ${symlink_target}"

    # Verify
    if [[ -f "${symlink_target}/SKILL.md" ]]; then
        ok "Webwright skill verified (SKILL.md found)"
    else
        warn "Webwright SKILL.md not found at symlink target — Hermes may not load it"
    fi
}

install_for_claude() {
    if ! command -v claude &>/dev/null; then
        warn "Claude Code not found — skipping Claude plugin install"
        return 0
    fi
    log "Installing Webwright plugin for Claude Code..."
    if [[ -d "${WEBWRIGHT_DIR}" ]]; then
        cd "${WEBWRIGHT_DIR}"
        claude plugin marketplace add "$(pwd)" 2>/dev/null && \
            claude plugin install webwright@webwright 2>/dev/null && \
            ok "Webwright installed for Claude Code" || \
            warn "Claude Code plugin install failed (try manually: /plugin install webwright@webwright)"
    fi
}

main() {
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  Webwright (Microsoft Research)              │"
    echo "  │  SOTA Browser Agent Framework               │"
    echo "  │  86.7% Online-Mind2Web · 60.1% Odysseys     │"
    echo "  │  ~1,500 LoC · MIT License                   │"
    echo "  └─────────────────────────────────────────────┘"
    echo ""

    install_webwright_cli
    install_for_hermes
    install_for_claude

    echo ""
    ok "Webwright ready."
    echo "  CLI:    python -m webwright.run.cli -c base.yaml -t \"<task>\""
    echo "  Hermes: /webwright (auto-activates from skill description)"
    echo "  Repo:   https://github.com/microsoft/Webwright"
    echo "  Docs:   https://microsoft.github.io/Webwright/"
    echo ""
}

main