#!/usr/bin/env bash
# jcodemunch setup for Hermes Stack
# Token-efficient code retrieval MCP - cuts code-reading token usage by 95%+
# Uses tree-sitter AST parsing for precise symbol-level code retrieval
set -euo pipefail

TOOLS_DIR="${HERMES_TOOLS_DIR:-$HOME/.tools}"
JCODEMUNCH_DIR="$TOOLS_DIR/jcodemunch"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_jcodemunch() {
    log "Installing jcodemunch-mcp (token-efficient code retrieval for AI agents)..."

    # Check if jcodemunch-mcp is already installed
    if command -v jcodemunch-mcp 2>/dev/null; then
        ok "jcodemunch-mcp already installed at $(which jcodemunch-mcp)"
    else
        log "Installing jcodemunch-mcp from GitHub..."
        pip install git+https://github.com/jgravelle/jcodemunch-mcp.git 2>/dev/null || \
        pip3 install git+https://github.com/jgravelle/jcodemunch-mcp.git 2>/dev/null || {
            warn "jcodemunch-mcp install failed — trying pip with --break-system-packages"
            pip3 install --break-system-packages git+https://github.com/jgravelle/jcodemunch-mcp.git 2>/dev/null || {
                warn "jcodemunch-mcp installation failed — skipping (non-critical)"
                return 1
            }
        }
    fi

    # Create skill documentation
    mkdir -p "$JCODEMUNCH_DIR"
    cat > "$JCODEMUNCH_DIR/JCODEMUNCH_SKILL.md" << 'SKILL'
# jCodeMunch Skill — Token-Efficient Code Retrieval

jCodeMunch is an MCP server that indexes codebases with tree-sitter AST parsing.
It lets AI agents retrieve exact functions, classes, and symbols without reading entire files.

## Key Benefits
- **95%+ token reduction** on code retrieval tasks
- **Precise symbol-level access** — get only what you need
- **MCP-native** — works with Claude Code, Cursor, Windsurf, Codex CLI, and Hermes Agent
- **Auto-reindexing** — watches files for changes

## Quick Start
```bash
# Initialize for current project
jcodemunch-mcp init

# Run the MCP server
jcodemunch-mcp serve

# Index a directory
jcodemunch-mcp index /path/to/project

# Watch for changes and auto-reindex
jcodemunch-mcp watch /path/to/project
```

## Available Tools (available to agent via MCP)
- `get_symbol_source` — get exact function/class implementation
- `find_references` — find all references to a symbol
- `get_blast_radius` — what breaks if you change this symbol
- `find_dead_code` — unreachable code detection
- `get_pr_risk_profile` — composite risk score for changes
- `search_ast` — structural code pattern matching
- `plan_refactoring` — edit-ready refactoring plans

## Integration with Claude Code
Run `jcodemunch-mcp init` to auto-configure MCP for Claude Code.

Ask your agent: "find the authenticate function in this project" or "what calls this function"
SKILL

    ok "jcodemunch-mcp installed and configured"
    log "Run 'jcodemunch-mcp init' in any project to configure MCP"
}

install_jcodemunch
ok "jcodemunch-mcp ready. Cuts code-reading token usage by 95%+."
