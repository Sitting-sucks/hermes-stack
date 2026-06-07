# Hermes Stack — Quickstart

Welcome. The installer has just configured your AI teammate. This guide gets you productive in 10 minutes.

## What you have now

| Location | What it is |
|---|---|
| `~/.hermes/.env` | Your API keys (0600 perms — keep private). |
| `~/.hermes/config.yaml` | Model routing + enabled toolsets. |
| `~/.claude.json` | MCP server registry — wires `agentmemory`, `codegraph`, and optionally `n8n-mcp` into Claude Code. |
| `~/.claude/CLAUDE.md` | Project-wide context every Claude Code session reads. |
| `~/.claude/settings.json` | Permission allowlist and env overrides. |
| `~/.claude/skills/` | Bundled skills, auto-discovered by Claude Code. |
| `~/.hermes/skills/understand-anything/` | Visual knowledge graph skills for codebase exploration. |

## First commands

### 1. Open Claude Code in a project

```sh
cd ~/projects/anything
claude
```

You'll get an interactive terminal. The `agentmemory` and `codegraph` MCP servers start automatically.

### 2. Index a codebase with CodeGraph

```sh
codegraph init -i
```

This builds a tree-sitter knowledge graph at `.codegraph/`. After this, ask Claude things like:

- "Where is `parseRequest` defined?"
- "What calls `UserService.create`?"
- "What would break if I rename `OldThing` to `NewThing`?"

CodeGraph answers structurally, not by grepping.

### 3. Explore with Understand-Anything

In any project directory, run:

```sh
/understand
```

This builds an interactive knowledge graph. Launch the dashboard:

```sh
/understand-dashboard
```

Then ask questions:

```sh
/understand-chat "How does the payment flow work?"
/understand-explain src/auth/login.ts
/understand-onboard
```

Understand-Anything gives you a visual, explorable map of your codebase — great for onboarding, architecture reviews, and seeing how business domains map to code.

### 4. Try the memory layer

In any Claude Code session:

> Remember that I prefer typed Python over duck-typed Python.

The next session will recall it. Memory is stored locally in the `agentmemory` SQLite database.

### 5. Switch models on the fly

In `~/.hermes/config.yaml`, edit `routing.primary` or `routing.fallback`. Changes take effect on next session.

Examples:

- `deepseek/deepseek-chat` — cheap, fast, capable.
- `anthropic/claude-sonnet-4-5` — best general-purpose.
- `openai/gpt-4.1-mini` — solid OpenAI alternative.

Any [OpenRouter model ID](https://openrouter.ai/models) works for `primary`.

## Useful shell aliases (optional)

Add to your `~/.bashrc` / `~/.zshrc`:

```sh
alias hermes-edit='$EDITOR ~/.hermes/config.yaml'
alias hermes-env='$EDITOR ~/.hermes/.env'
alias hermes-md='$EDITOR ~/.claude/CLAUDE.md'
```

## Chat platform wiring (if configured)

- **Discord:** invite your bot to a server with the `bot` and `applications.commands` scopes. Hermes listens on DMs only by default — flip `allow_dm_only` in `config.yaml` to allow channels.
- **Slack:** post to your configured incoming webhook from any tool.
- **Telegram:** message your bot directly; it'll respond.

## Google Workspace (Gmail / Calendar / Drive)

The Google MCP servers are not installed by default — they require a one-time OAuth dance:

1. Visit https://console.cloud.google.com/
2. Create a project, then enable: Gmail API, Calendar API, Drive API.
3. Create an OAuth client (type: Desktop) and download the JSON.
4. Add the Gmail / Calendar / Drive MCP servers via `claude mcp add`.
5. First use will open a browser to complete OAuth.

## Updating the stack

```sh
npm update -g @anthropic-ai/claude-code @agentmemory/agentmemory @colbymchenry/codegraph
# Update Understand-Anything (if installed):
curl -fsSL https://raw.githubusercontent.com/Lum1104/Understand-Anything/main/install.sh | bash -s -- --update
```

Re-run the installer at any time to re-render config files — your existing `~/.claude.json` is merged, not overwritten.

## Where to go next

- `docs/TROUBLESHOOTING.md` — common issues.
- Inside Claude Code, type `/help` for the full command list.
- Inspect `~/.claude/skills/` to see what's available; each skill has a description that tells you when it activates.