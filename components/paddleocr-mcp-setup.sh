#!/usr/bin/env bash
# PaddleOCR MCP Setup — industrial OCR as MCP server for AI agents
# PP-OCRv6 text detection + PP-StructureV3 layout parsing as MCP tools
# Use: `ocr` tool in Claude Code, Cursor, or any MCP host
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install.sh" 2>/dev/null || true

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RESET=""; fi

log()   { printf "%s[paddleocr]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

install_paddleocr_mcp() {
    log "Installing PaddleOCR MCP Server (OCR + document parsing for AI agents)..."
    log "Repo: github.com/PaddlePaddle/PaddleOCR | 45K+ stars | Apache 2.0"
    log "Docs: www.paddleocr.ai/latest/en/version3.x/deployment/mcp_server.html"

    # Determine install mode
    # Local inference mode needs paddlepaddle (GPU or CPU)
    # API mode uses cloud service — lighter install

    local mode="${1:-local}"
    if [[ "$mode" == "api" ]]; then
        log "Installing in API mode (lighter — uses PaddleOCR cloud service)"
    else
        log "Installing in local mode (full OCR pipeline — requires paddlepaddle)"
    fi

    # Install paddleocr-mcp package
    if python3 -c "import paddleocr_mcp" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import importlib.metadata; print(importlib.metadata.version('paddleocr-mcp'))" 2>/dev/null || echo "unknown")
        ok "paddleocr-mcp $ver already installed"
    else
        if pip install paddleocr-mcp 2>/dev/null || pip3 install paddleocr-mcp 2>/dev/null; then
            ok "paddleocr-mcp installed"
        else
            warn "paddleocr-mcp install failed — trying uvx fallback"
            if command -v uv &>/dev/null; then
                ok "uvx fallback available — run 'uvx paddleocr-mcp' when needed"
            else
                warn "PaddleOCR MCP install failed — skipping (non-critical)"
                return 1
            fi
        fi
    fi

    # Install local inference dependencies only in local mode
    if [[ "$mode" == "local" ]]; then
        if ! python3 -c "import paddle" 2>/dev/null; then
            log "Installing PaddlePaddle (CPU version)..."
            if pip install paddlepaddle 2>/dev/null || pip3 install paddlepaddle 2>/dev/null; then
                ok "PaddlePaddle CPU installed"
            else
                warn "PaddlePaddle install failed — GPU or manual install may be needed"
            fi
        else
            ok "PaddlePaddle already installed"
        fi
    fi

    # Create MCP config for Claude Code / Cursor
    local mcp_config_dir="${HOME}/.config"
    if [[ -d "${HOME}/.codex" ]]; then
        mcp_config_dir="${HOME}/.codex"
    fi

    # Detect Claude Code MCP config
    local claude_config="${HOME}/.claude/settings.json"
    if [[ -f "$claude_config" ]]; then
        log "PaddleOCR MCP can be added to Claude Code MCP config"
        log "Add to ~/.claude/settings.json mcpServers:"
        log '  "paddleocr": { "command": "uvx", "args": ["paddleocr-mcp", "--ppocr_source", "aistudio"] }'
    fi

    # Quick smoke test (API mode only — local mode needs more setup)
    if [[ "$mode" == "api" ]]; then
        if python3 -c "from paddleocr_mcp import __version__; print(__version__)" 2>/dev/null; then
            ok "PaddleOCR MCP smoke test passed"
        else
            warn "PaddleOCR MCP import check failed — check dependencies"
        fi
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_paddleocr_mcp "$@"
fi