#!/usr/bin/env bash
# x-mcp setup for Hermes Stack
# X/Twitter MCP server - gives Claude Code X API access
set -euo pipefail

TOOLS_DIR="${HERMES_TOOLS_DIR:-$HOME/.tools}"
X_MCP_DIR="$TOOLS_DIR/x-mcp"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_x_mcp() {
    log "Installing x-mcp (X/Twitter MCP server)..."

    if [[ -f "$X_MCP_DIR/dist/index.js" ]]; then
        ok "x-mcp already installed at $X_MCP_DIR"
        return 0
    fi

    mkdir -p "$X_MCP_DIR"
    git clone https://github.com/Infatoshi/x-mcp.git /tmp/x-mcp-install
    cp -r /tmp/x-mcp-install/* "$X_MCP_DIR/"
    rm -rf /tmp/x-mcp-install

    cd "$X_MCP_DIR"
    npm install
    npm run build

    ok "x-mcp built successfully at $X_MCP_DIR"
}

configure_x_mcp() {
    log "To configure x-mcp with Claude Code, you need X API credentials."
    log "Get them at: https://developer.x.com/en/portal/dashboard"
    log ""
    log "Run this command with your credentials:"
    log ""
    log "claude mcp add x-twitter \\"
    log "  -e X_API_KEY=your_key \\"
    log "  -e X_API_SECRET=your_secret \\"
    log "  -e X_ACCESS_TOKEN=your_token \\"
    log "  -e X_ACCESS_TOKEN_SECRET=your_token_secret \\"
    log "  -e X_BEARER_TOKEN=your_bearer \\"
    log "  -- node $X_MCP_DIR/dist/index.js"
}

install_x_mcp
ok "x-mcp installation complete. Configure with your X API credentials."