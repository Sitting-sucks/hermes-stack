# Hermes Stack Installer — Build Spec

Build a complete one-command installer for the Hermes AI Stack — a premium AI teammate setup for professionals.

## Architecture

Two entry points:
1. `install.sh` — Bootstrap script (detect OS, install deps, clone Hermes, launch wizard)
2. `wizard.py` — Python setup wizard (prompt for keys, generate configs, wire MCP servers, install skills)

## install.sh

Detects OS (macOS ARM, macOS Intel, Linux, WSL). Installs prerequisites:
- Node.js (if missing, install via nvm or brew)
- Python 3.10+ (if missing)
- git
- npm packages: @agentmemory/agentmemory, @colbymchenry/codegraph, @anthropic-ai/claude-code

Then runs: `python3 wizard.py`

## wizard.py

Interactive terminal wizard. Prompts the user for:
1. OpenRouter API key (required)
2. Anthropic API key (optional, for Claude fallback)
3. Chat platform (Discord bot token, Slack webhook, or Telegram bot token)
4. Email (for Google Workspace OAuth setup info)
5. Model preferences (default: deepseek primary, claude fallback)

Generates these files in the user's home directory:
- `~/.hermes/.env` — API keys
- `~/.claude.json` — MCP server configs (agentmemory, codegraph, n8n-mcp)
- `~/.hermes/config.yaml` — Hermes config with model routing
- `~/.claude/CLAUDE.md` — Project context
- `~/.claude/settings.json` — Permissions and MCP config

Installs skills from templates/ to `~/.claude/skills/`

Sets up agentmemory server
Runs codegraph init in their projects
Configures n8n-mcp

## templates/ Directory

### templates/env.template
Template for .env file. Placeholder values like `YOUR_OPENROUTER_API_KEY_HERE`.

### templates/claude.json.template
Claude Code MCP server config. Wires:
- agentmemory (npx @agentmemory/mcp)
- codegraph (codegraph serve --mcp)
- n8n-mcp (if user has n8n)

### templates/config.yaml.template
Hermes Agent config with:
- Model routing: deepseek primary, claude sonnet fallback
- Provider configs (OpenRouter, Anthropic)
- Enabled toolsets
- Gateway settings

## skills/ Directory
Copy of all authored skill files that go to ~/.claude/skills/
Include README explaining what each skill does.

## docs/ Directory
- QUICKSTART.md — What they have, how to use it, first commands to run
- TROUBLESHOOTING.md — Common issues and fixes

## CRITICAL RULES
- NO real API keys, tokens, passwords, or credentials in templates
- NO user data, memories, conversations, or personal information
- All references to "Ryan" or "Sitting Sucks" must be replaced with generic/placeholder text
- Templates use `YOUR_KEY_HERE` style placeholders
- The product is the tool stack and config, not our personal setup