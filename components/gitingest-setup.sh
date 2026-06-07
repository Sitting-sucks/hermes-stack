#!/usr/bin/env bash
# Gitingest Setup — codebase ingestion for AI agents
# Turn any Git repo into a prompt-friendly text digest for LLMs
# https://github.com/cyclotruc/gitingest
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")\" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[gitingest]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_gitingest() {
    log "Installing Gitingest (codebase → LLM-prompt ingestion)..."

    if python3 -c "from gitingest import ingest; print('ready')" 2>/dev/null; then
        ok "Gitingest Python package already installed"
        return 0
    fi

    if pip install gitingest 2>/dev/null || pip3 install gitingest 2>/dev/null; then
        ok "Gitingest installed"
    else
        warn "Gitingest install failed — skipping (non-critical)"
        return 1
    fi

    # Verify
    if python3 -c "from gitingest import ingest; print('OK')" 2>/dev/null; then
        ok "Gitingest Python package ready"
    fi
}

verify_install() {
    if python3 -c "from gitingest import ingest; print('Gitingest: ready')" 2>/dev/null; then
        ok "Gitingest package available"
    fi
}

main() {
    install_gitingest
    verify_install

    log ""
    log "Gitingest quick start:"
    log "  CLI:    gitingest /path/to/repo"
    log "  URL:    gitingest https://github.com/user/repo"
    log "  Python: from gitingest import ingest; summary, tree, content = ingest('path')"
    log "  Web:    Replace 'hub' with 'ingest' in any GitHub URL"
    log "  Docs:   https://gitingest.com"
    log ""
}

main "$@"