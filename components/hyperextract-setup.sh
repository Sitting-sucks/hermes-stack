#!/usr/bin/env bash
# Hyper-Extract Setup — structured knowledge extraction from unstructured text
# Transforms docs into knowledge graphs, hypergraphs, temporal/spatial graphs
# CLI-first: `he parse document.md -t general/knowledge_graph`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[hyperextract]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_hyperextract() {
    log "Installing Hyper-Extract (structured knowledge extraction)..."
    log "Repo: github.com/yifanfeng97/Hyper-Extract | 627+ stars | Apache 2.0"

    # Check if uv is available (preferred for CLI install)
    if command -v uv &>/dev/null; then
        if uv tool list 2>/dev/null | grep -q hyperextract; then
            local ver
            ver=$(uv tool list 2>/dev/null | grep hyperextract | awk '{print $NF}')
            ok "Hyper-Extract CLI $ver already installed via uv"
        else
            if uv tool install hyperextract 2>/dev/null; then
                ok "Hyper-Extract CLI installed via uv (command: he)"
            else
                warn "uv tool install failed — trying pip fallback"
                install_hyperextract_pip
            fi
        fi
    else
        install_hyperextract_pip
    fi

    # Verify CLI
    if command -v he &>/dev/null; then
        ok "Hyper-Extract CLI ready — run 'he parse document.md -t general/knowledge_graph'"
    else
        warn "he command not found in PATH — check installation"
    fi

    # Install Python library for programmatic use
    if python3 -c "import hyperextract" 2>/dev/null; then
        ok "hyperextract Python package already installed"
    else
        if pip install hyperextract 2>/dev/null || pip3 install hyperextract 2>/dev/null; then
            ok "hyperextract Python package installed"
        else
            warn "hyperextract Python package install failed — CLI only"
        fi
    fi
}

install_hyperextract_pip() {
    if pip install hyperextract 2>/dev/null || pip3 install hyperextract 2>/dev/null; then
        ok "Hyper-Extract installed via pip"
    else
        warn "Hyper-Extract install failed — skipping (non-critical)"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_hyperextract
fi