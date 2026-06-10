#!/usr/bin/env bash
# ContextGem Setup — LLM-powered structured data extraction from documents
# Extract contracts, reports, research papers → structured JSON with references
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

# Colors
C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[contextgem]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_contextgem() {
    log "Installing ContextGem (LLM-powered document extraction)..."

    # Check if already installed
    if python3 -c "import contextgem; print(contextgem.__version__)" 2>/dev/null; then
        local version
        version=$(python3 -c "import contextgem; print(contextgem.__version__)" 2>/dev/null)
        ok "ContextGem v$version already installed"
        log "Update: pip install -U contextgem"
        return 0
    fi

    # Install via pip
    if pip install contextgem 2>/dev/null || pip3 install contextgem 2>/dev/null; then
        ok "ContextGem installed"
    else
        warn "pip install failed — try: pip install contextgem"
        return 1
    fi

    # Verify
    if python3 -c "import contextgem" 2>/dev/null; then
        local version
        version=$(python3 -c "import contextgem; print(contextgem.__version__)" 2>/dev/null)
        ok "ContextGem v$version ready for document extraction"
        log "Supports: contracts, reports, research papers, invoices, CVs"
        log "Extract: entities, dates, ratings, classifications — with paragraph-level references"
    fi
}

install_contextgem
ok "ContextGem setup complete"