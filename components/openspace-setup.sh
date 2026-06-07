#!/usr/bin/env bash
# Hermes Stack — OpenSpace Integration Setup
# Self-evolving skills engine for AI agents
# https://github.com/HKUDS/openSpace

set -euo pipefail

C_RESET='\033[0m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_CYAN='\033[36m'
C_BOLD='\033[1m'

log()   { printf "${C_CYAN}[hermes]${C_RESET} %s\n" "$*"; }
ok()    { printf "${C_GREEN}[ ok ]${C_RESET} %s\n" "$*"; }
warn()  { printf "${C_YELLOW}[warn]${C_RESET} %s\n" "$*"; }

main() {
    log "Setting up OpenSpace (self-evolving skills engine)..."

    local target_dir="$HOME/.hermes/openspace"
    local mcp_config="$HOME/.hermes/mcp-config.json"

    # Clone if not already present
    if [[ -d "$target_dir" ]]; then
        ok "OpenSpace already cloned at $target_dir"
    else
        mkdir -p "$(dirname "$target_dir")"
        git clone https://github.com/HKUDS/openSpace.git "$target_dir"
        ok "OpenSpace cloned"
    fi

    # Install Python package (requires Python 3.12+)
    local python_cmd="python3.12"
    if ! command -v python3.12 &>/dev/null; then
        python_cmd="python3"
    fi

    if $python_cmd -c "import openspace" 2>/dev/null; then
        ok "OpenSpace Python package already installed"
    else
        log "Installing OpenSpace Python package..."
        $python_cmd -m pip install "$target_dir" --break-system-packages 2>/dev/null || \
        $python_cmd -m pip install "$target_dir" 2>/dev/null || \
        warn "pip install failed — try manually: $python_cmd -m pip install $target_dir"
    fi

    # Verify openspace-mcp command
    if command -v openspace-mcp &>/dev/null; then
        ok "openspace-mcp command available"
    else
        # Try finding it in .local/bin
        if [[ -f "$HOME/.local/bin/openspace-mcp" ]]; then
            warn "Add $HOME/.local/bin to your PATH for openspace-mcp"
            export PATH="$HOME/.local/bin:$PATH"
        else
            warn "openspace-mcp not found in PATH"
        fi
    fi

    # Deploy host skills to Claude Code
    local claude_skills_dir="$HOME/.claude/skills"
    if [[ -d "$claude_skills_dir" ]]; then
        if [[ -d "$target_dir/openspace/host_skills/delegate-task" ]]; then
            cp -r "$target_dir/openspace/host_skills/delegate-task" "$claude_skills_dir/" 2>/dev/null || true
        fi
        if [[ -d "$target_dir/openspace/host_skills/skill-discovery" ]]; then
            cp -r "$target_dir/openspace/host_skills/skill-discovery" "$claude_skills_dir/" 2>/dev/null || true
        fi
        ok "OpenSpace host skills deployed to Claude Code"
    fi

    # Add MCP config entry
    if [[ -f "$mcp_config" ]]; then
        # Check if openspace entry already exists
        if grep -q '"openspace"' "$mcp_config" 2>/dev/null; then
            ok "OpenSpace MCP config already present"
        else
            warn "Add this to your MCP config manually — or we'll create a standalone config:"
            cat <<'CONFIG'
Add to your MCP config:
{
  "mcpServers": {
    "openspace": {
      "command": "openspace-mcp",
      "toolTimeout": 600,
      "env": {
        "OPENSPACE_HOST_SKILL_DIRS": "/home/$USER/.claude/skills",
        "OPENSPACE_WORKSPACE": "/home/$USER/.hermes/openspace"
      }
    }
  }
}
CONFIG
        fi
    else
        warn "No MCP config found at $mcp_config"
        warn "Add OpenSpace to your agent's MCP config using the JSON above"
    fi

    ok "OpenSpace setup complete"
    log "Usage: Add 'openspace-mcp' as an MCP server to any agent"
    log "Agents will auto-evolve skills, share knowledge, and use 46% fewer tokens over time"
}

main "$@"