#!/usr/bin/env bash
# claude-context-mcp setup for Hermes Stack
# Semantic code search MCP - gives Claude Code hybrid BM25 + dense vector code retrieval
# Uses Zilliz Cloud or local Milvus as vector store
set -euo pipefail

TOOLS_DIR="${HERMES_TOOLS_DIR:-$HOME/.tools}"
CLAUDE_CONTEXT_DIR="$TOOLS_DIR/claude-context"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_claude_context() {
    log "Installing claude-context-mcp (semantic code search for Claude Code)..."

    # Check if already configured in MCP
    if grep -q "claude-context" "$HOME/.claude/mcp.json" 2>/dev/null; then
        ok "claude-context-mcp already configured in Claude Code"
        return 0
    fi

    # The MCP server runs via npx - no local install needed
    # But we provide setup instructions and a convenience script
    mkdir -p "$CLAUDE_CONTEXT_DIR"

    cat > "$CLAUDE_CONTEXT_DIR/setup.sh" << 'SETUPSCRIPT'
#!/usr/bin/env bash
# Configure claude-context-mcp for Claude Code
# Requires: OPENAI_API_KEY and either MILVUS_ADDRESS+MILVUS_TOKEN or Zilliz Cloud credentials
# Get Zilliz Cloud free tier: https://cloud.zilliz.com

echo "=== Claude Context MCP Setup ==="
echo ""
echo "This MCP server adds semantic code search to Claude Code."
echo "It indexes your codebase with hybrid BM25 + dense vector search."
echo ""
echo "You need:"
echo "  1. An OpenAI API key (for embeddings)"
echo "  2. A Zilliz Cloud account (free tier works) or local Milvus"
echo ""
echo "To configure in Claude Code, run:"
echo ""
echo "claude mcp add claude-context \\"
echo "  -e OPENAI_API_KEY=sk-your-openai-api-key \\"
echo "  -e MILVUS_ADDRESS=https://your-instance.zillizcloud.com \\"
echo "  -e MILVUS_TOKEN=your-zilliz-api-key \\"
echo "  -- npx @zilliz/claude-context-mcp@latest"
echo ""
echo "Then in any project:"
echo "  1. claude -p 'index this codebase for semantic search'"
echo "  2. claude -p 'find the code that handles user authentication'"
echo ""
SETUPSCRIPT
    chmod +x "$CLAUDE_CONTEXT_DIR/setup.sh"

    ok "claude-context-mcp setup script created at $CLAUDE_CONTEXT_DIR/setup.sh"
    warn "To activate: run the setup command above with your API keys"
    warn "Free Zilliz Cloud tier: https://cloud.zilliz.com"
}

install_claude_context
ok "claude-context-mcp ready. Configure with your API keys to enable semantic code search."
