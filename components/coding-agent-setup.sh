#!/usr/bin/env bash
# coding-agent-setup.sh — Install and wire the user's chosen coding agent
#
# Not everyone uses Claude Code. This script installs the coding agent the user
# selected in the wizard and wires the shared MCP servers (agentmemory,
# codegraph, n8n-mcp, codebase-memory-mcp) into that agent's config.
#
# Supported agents:
#   claude  — Claude Code (npm: @anthropic-ai/claude-code). Best for Claude Max.
#   codex   — OpenAI Codex CLI (npm: @openai/codex). Best for ChatGPT Plus/Pro.
#   cursor  — Cursor IDE (downloaded app). Best for visual IDE users.
#   none    — skip coding agent install (user wires their own later)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_ENV="${HOME}/.hermes/.env"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

# Read the chosen agent from env (set by wizard). Default to claude.
AGENT="${CODING_AGENT:-claude}"

# Shared MCP server config — these get wired into whichever agent is chosen.
# agentmemory + codegraph are always installed; n8n-mcp is optional.
build_mcp_config() {
    local n8n_base_url="${N8N_BASE_URL:-http://localhost:5678}"
    local n8n_api_key="${N8N_API_KEY:-}"

    local n8n_block=""
    if [[ -n "$n8n_api_key" && "$n8n_api_key" != "YOUR_N8N_API_KEY_HERE" ]]; then
        n8n_block=$(cat <<EOF
,
    "n8n-mcp": {
      "command": "npx",
      "args": ["-y", "@n8n-io/n8n-mcp"],
      "env": {
        "N8N_BASE_URL": "$n8n_base_url",
        "N8N_API_KEY": "$n8n_api_key"
      }
    }
EOF
)
    fi

    cat <<EOF
{
  "mcpServers": {
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "@agentmemory/agentmemory", "serve", "--stdio"],
      "env": {}
    },
    "codegraph": {
      "command": "npx",
      "args": ["-y", "@colbymchenry/codegraph", "serve", "--mcp"],
      "env": {}
    }${n8n_block}
  }
}
EOF
}

install_claude_code() {
    log "Installing Claude Code..."

    if command -v claude &>/dev/null; then
        local ver
        ver=$(claude --version 2>/dev/null || echo "unknown")
        ok "Claude Code already installed ($ver)"
    else
        if ! npm install -g @anthropic-ai/claude-code >/dev/null 2>&1; then
            warn "npm install of @anthropic-ai/claude-code failed"
            warn "Try manually: npm install -g @anthropic-ai/claude-code"
            return 1
        fi
        ok "Claude Code installed"
    fi

    # Wire MCP into ~/.claude.json (merge, don't overwrite)
    local claude_json="${HOME}/.claude.json"
    local mcp_config
    mcp_config=$(build_mcp_config)

    if [[ -f "$claude_json" ]]; then
        # Merge mcpServers into existing config using python
        python3 -c "
import json, sys
with open('$claude_json', 'r') as f:
    existing = json.load(f)
new = json.loads('''$mcp_config''')
if 'mcpServers' not in existing:
    existing['mcpServers'] = {}
existing['mcpServers'].update(new.get('mcpServers', {}))
with open('$claude_json', 'w') as f:
    json.dump(existing, f, indent=2)
" 2>/dev/null && ok "MCP servers wired into ~/.claude.json" || {
            warn "Could not auto-merge MCP config into ~/.claude.json"
            warn "Manually add this to your mcpServers: $mcp_config"
        }
    else
        echo "$mcp_config" > "$claude_json"
        ok "Created ~/.claude.json with MCP servers"
    fi

    log ""
    log "Claude Code is ready."
    log "  - Run 'claude' in any project to start"
    log "  - Login with: claude login (uses Anthropic account or API key)"
    log "  - Claude Max (\$100/mo) gives unlimited Opus — best value"
    log "  - MCP servers (memory, codegraph, n8n) are wired in"
}

install_codex() {
    log "Installing OpenAI Codex CLI..."

    if command -v codex &>/dev/null; then
        local ver
        ver=$(codex --version 2>/dev/null || echo "unknown")
        ok "Codex CLI already installed ($ver)"
    else
        # Codex CLI is @openai/codex on npm
        if ! npm install -g @openai/codex >/dev/null 2>&1; then
            warn "npm install of @openai/codex failed"
            warn "Try manually: npm install -g @openai/codex"
            warn "Or check: https://github.com/openai/codex"
            return 1
        fi
        ok "Codex CLI installed"
    fi

    # Wire MCP into ~/.codex/config.json (Codex uses this for MCP servers)
    local codex_dir="${HOME}/.codex"
    local codex_config="${codex_dir}/config.json"
    local mcp_config
    mcp_config=$(build_mcp_config)

    mkdir -p "$codex_dir"

    if [[ -f "$codex_config" ]]; then
        python3 -c "
import json
with open('$codex_config', 'r') as f:
    existing = json.load(f)
new = json.loads('''$mcp_config''')
if 'mcpServers' not in existing:
    existing['mcpServers'] = {}
existing['mcpServers'].update(new.get('mcpServers', {}))
with open('$codex_config', 'w') as f:
    json.dump(existing, f, indent=2)
" 2>/dev/null && ok "MCP servers wired into ~/.codex/config.json" || {
            warn "Could not auto-merge MCP config into ~/.codex/config.json"
        }
    else
        echo "$mcp_config" > "$codex_config"
        ok "Created ~/.codex/config.json with MCP servers"
    fi

    log ""
    log "Codex CLI is ready."
    log "  - Run 'codex' in any project to start"
    log "  - Login with: codex login (uses OpenAI account)"
    log "  - ChatGPT Plus/Pro includes Codex usage"
    log "  - MCP servers (memory, codegraph, n8n) are wired in"
}

install_cursor() {
    log "Setting up Cursor IDE integration..."

    # Cursor is a GUI app — we can't install it from CLI, but we can wire MCP
    local cursor_dir="${HOME}/.cursor"
    local cursor_mcp="${cursor_dir}/mcp.json"
    local mcp_config
    mcp_config=$(build_mcp_config)

    mkdir -p "$cursor_dir"

    if [[ -f "$cursor_mcp" ]]; then
        python3 -c "
import json
with open('$cursor_mcp', 'r') as f:
    existing = json.load(f)
new = json.loads('''$mcp_config''')
if 'mcpServers' not in existing:
    existing['mcpServers'] = {}
existing['mcpServers'].update(new.get('mcpServers', {}))
with open('$cursor_mcp', 'w') as f:
    json.dump(existing, f, indent=2)
" 2>/dev/null && ok "MCP servers wired into ~/.cursor/mcp.json" || {
            warn "Could not auto-merge MCP config into ~/.cursor/mcp.json"
        }
    else
        echo "$mcp_config" > "$cursor_mcp"
        ok "Created ~/.cursor/mcp.json with MCP servers"
    fi

    # Check if Cursor is installed
    if [[ -d "/Applications/Cursor.app" ]] || [[ -d "/mnt/c/Users/$(whoami)/AppData/Local/Programs/cursor" ]]; then
        ok "Cursor IDE detected"
    else
        warn "Cursor IDE not found on your system."
        warn "Download it from: https://cursor.com"
        warn "After installing, restart Cursor — MCP servers are already wired."
    fi

    log ""
    log "Cursor integration is ready."
    log "  - MCP servers (memory, codegraph, n8n) are wired into Cursor"
    log "  - Restart Cursor to pick up the new MCP config"
    log "  - Cursor uses your Claude/OpenAI API keys or built-in subscriptions"
}

install_coding_agent() {
    log "Configuring coding agent: $AGENT"

    case "$AGENT" in
        claude)
            install_claude_code
            ;;
        codex)
            install_codex
            ;;
        cursor)
            install_cursor
            ;;
        none)
            log "Skipping coding agent install."
            log "You can wire MCP servers manually later — see docs/QUICKSTART.md"
            ;;
        *)
            warn "Unknown agent: $AGENT. Defaulting to Claude Code."
            AGENT="claude"
            install_claude_code
            ;;
    esac
}

install_coding_agent
