#!/usr/bin/env bash
# codebase-memory-mcp-setup.sh — High-performance code intelligence MCP server
# Indexes codebases into persistent knowledge graphs. 158 languages, sub-ms queries,
# 99% fewer tokens. Single static binary, zero dependencies.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_CONFIG="${HOME}/.hermes/config.yaml"
CBM_BINARY="${HOME}/.local/bin/codebase-memory-mcp"

log()   { printf "[hermes] %s\n" "$*"; }
ok()    { printf "[ ok ] %s\n" "$*"; }
warn()  { printf "[warn] %s\n" "$*"; }

install_codebase_memory_mcp() {
    log "Installing codebase-memory-mcp..."

    if command -v codebase-memory-mcp &>/dev/null; then
        local version
        version=$(codebase-memory-mcp --version 2>/dev/null || echo "unknown")
        log "codebase-memory-mcp already installed (${version}), updating..."
        curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash 2>/dev/null
        ok "codebase-memory-mcp updated"
        return 0
    fi

    curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash 2>/dev/null

    if command -v codebase-memory-mcp &>/dev/null; then
        local version
        version=$(codebase-memory-mcp --version 2>/dev/null || echo "unknown")
        ok "codebase-memory-mcp ${version} installed"
    else
        warn "codebase-memory-mcp binary not found in PATH after install"
        warn "Try: source ~/.bashrc"
    fi
}

configure_for_hermes() {
    log "Configuring codebase-memory-mcp for Hermes Agent..."

    if [[ ! -f "${HERMES_CONFIG}" ]]; then
        warn "Hermes config not found at ${HERMES_CONFIG} — skipping Hermes MCP registration"
        return 0
    fi

    # Check if codebase-memory-mcp is already in the Hermes MCP config
    if grep -q "codebase-memory-mcp" "${HERMES_CONFIG}" 2>/dev/null; then
        ok "codebase-memory-mcp already registered in Hermes"
        return 0
    fi

    if [[ ! -f "${CBM_BINARY}" ]]; then
        warn "codebase-memory-mcp binary not found at ${CBM_BINARY}"
        return 0
    fi

    # Add to Hermes MCP servers config
    # Find the mcp_servers section and add before 'time:'
    if grep -q "^mcp_servers:" "${HERMES_CONFIG}"; then
        # Insert after the mcp_servers: line
        sed -i '/^mcp_servers:/a\  codebase-memory-mcp:\n    command: '"${CBM_BINARY}"'\n    args: []' "${HERMES_CONFIG}"
        ok "codebase-memory-mcp registered in Hermes MCP config"
    else
        warn "Could not find mcp_servers section in Hermes config"
    fi
}

main() {
    log "Setting up codebase-memory-mcp (code intelligence MCP server)..."
    install_codebase_memory_mcp
    configure_for_hermes
    log ""
    log "codebase-memory-mcp is ready. Tell your agent: 'Index this project'"
    log "Your codebase knowledge graph is available via 14 MCP tools."
    log "Linux kernel (28M LOC) indexes in ~3 min. Average repo: milliseconds."
}

main