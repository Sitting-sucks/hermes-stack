#!/usr/bin/env bash
# markitdown setup for Hermes Stack
# Microsoft MarkItDown - converts office docs (PPTX, DOCX, XLSX, PDF) to clean markdown
# for AI/LLM document pipelines. 130K+ stars, MIT license.
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_markitdown() {
    log "Installing Microsoft MarkItDown (document-to-markdown converter)..."

    if python3 -c "from markitdown import MarkItDown" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import importlib.metadata; print(importlib.metadata.version('markitdown'))" 2>/dev/null || echo "unknown")
        ok "markitdown $ver already installed"
        return 0
    fi

    if pip install 'markitdown[all]' 2>/dev/null || pip3 install 'markitdown[all]' 2>/dev/null; then
        ok "markitdown installed"
    else
        warn "markitdown install failed — trying without extras"
        if pip install markitdown 2>/dev/null || pip3 install markitdown 2>/dev/null; then
            ok "markitdown (core) installed"
        else
            warn "markitdown install failed — skipping (non-critical)"
            return 1
        fi
    fi

    # Quick smoke test
    if python3 -c "from markitdown import MarkItDown; MarkItDown(); print('OK')" 2>/dev/null; then
        ok "markitdown smoke test passed"
    else
        warn "markitdown smoke test failed — check dependencies"
    fi
}

# Verify CLI works
verify_cli() {
    if command -v markitdown &>/dev/null; then
        ok "markitdown CLI available"
    else
        # CLI is installed as a console script with markitdown
        if python3 -m markitdown --help &>/dev/null; then
            ok "markitdown CLI available (python -m)"
        else
            warn "markitdown CLI may not be on PATH — use 'python3 -m markitdown' or 'markitdown'"
        fi
    fi
}

main() {
    install_markitdown
    verify_cli

    log ""
    log "markitdown usage:"
    log "  markitdown path/to/file.pptx > output.md"
    log "  cat path/to/file.pdf | markitdown > output.md"
    log "  python3 -c \"from markitdown import MarkItDown; print(MarkItDown().convert('file.docx').text_content)\""
}

main "$@"
