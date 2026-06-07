#!/usr/bin/env bash
# Spec Kit Setup — GitHub's Spec-Driven Development toolkit
# Structured Spec → Plan → Tasks → Implement pipeline for AI coding agents
# https://github.com/github/spec-kit
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")\" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[spec-kit]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_spec_kit() {
    log "Installing Spec Kit (Spec-Driven Development toolkit from GitHub)..."

    if command -v specify &>/dev/null; then
        local ver
        ver=$(specify version 2>/dev/null | grep "CLI Version" | awk '{print $NF}' || echo "installed")
        ok "Spec Kit CLI $ver already installed"
        return 0
    fi

    log "Installing specify-cli via pip..."
    if pip install git+https://github.com/github/spec-kit.git 2>/dev/null || \
       pip3 install git+https://github.com/github/spec-kit.git 2>/dev/null; then
        ok "Spec Kit CLI installed"
    else
        warn "pip install failed — trying uv..."
        if command -v uv &>/dev/null; then
            uv tool install specify-cli --from git+https://github.com/github/spec-kit.git 2>/dev/null && \
                ok "Spec Kit CLI installed via uv"
        else
            warn "Spec Kit install failed — skipping (non-critical)"
            return 1
        fi
    fi

    # Verify
    if command -v specify &>/dev/null; then
        ok "Spec Kit ready — run 'specify init <project>' to start"
        log "  Usage: cd into a project directory and run: specify init . --ai claude"
        log "  This creates the Spec-Driven Development workflow with slash commands"
        log "  Then use /speckit.specify, /speckit.plan, /speckit.implement in Claude Code"
    fi
}

verify_install() {
    if command -v specify &>/dev/null; then
        ok "Spec Kit CLI available: $(specify version 2>/dev/null | grep "CLI Version" | awk '{print $NF}')"
    else
        warn "Spec Kit not found in PATH — try running 'pip install git+https://github.com/github/spec-kit.git'"
    fi
}

main() {
    install_spec_kit
    verify_install

    log ""
    log "Spec Kit quick start:"
    log "  1. cd ~/your-project"
    log "  2. specify init . --ai claude"
    log "  3. In Claude Code, use: /speckit.specify, /speckit.plan, /speckit.implement"
    log "  Docs: https://github.github.io/spec-kit/"
    log ""
}

main "$@"