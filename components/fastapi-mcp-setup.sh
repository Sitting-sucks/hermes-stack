#!/usr/bin/env bash
# fastapi-mcp setup for Hermes Stack
# Expose FastAPI endpoints as Model Context Protocol (MCP) tools.
# Turn any FastAPI service into MCP-accessible tools for AI agents.
# 12K+ stars, MIT license. https://github.com/tadata-org/fastapi_mcp
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_fastapi_mcp() {
    log "Installing fastapi-mcp (FastAPI → MCP tool exporter)..."

    if python3 -c "import fastapi_mcp" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import importlib.metadata; print(importlib.metadata.version('fastapi_mcp'))" 2>/dev/null || echo "unknown")
        ok "fastapi-mcp $ver already installed"
        return 0
    fi

    if pip install fastapi-mcp 2>/dev/null || pip3 install fastapi-mcp 2>/dev/null; then
        ok "fastapi-mcp installed"
    else
        warn "fastapi-mcp install failed — skipping (non-critical)"
        return 1
    fi

    # Smoke test
    if python3 -c "import fastapi_mcp; print('OK')" 2>/dev/null; then
        ok "fastapi-mcp smoke test passed"
    else
        warn "fastapi-mcp smoke test failed — check dependencies"
    fi
}

main() {
    install_fastapi_mcp

    log ""
    log "fastapi-mcp usage:"
    log "  from fastapi import FastAPI"
    log "  from fastapi_mcp import FastApiMCP"
    log "  app = FastAPI()"
    log "  mcp = FastApiMCP(app)"
    log "  mcp.mount()  # MCP server at /mcp"
    log ""
    log "Then connect from any MCP client:"
    log '  { "mcpServers": { "my-api": { "url": "http://localhost:8000/mcp" } } }'
}

main "$@"