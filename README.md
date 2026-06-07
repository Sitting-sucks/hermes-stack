# Hermes Stack — Premium AI Teammate

One command. Full stack. Your AI teammate today.

```sh
curl -fsSL https://raw.githubusercontent.com/Sitting-sucks/hermes-stack/main/install.sh | bash
```

## What you get

- **Hermes Agent** — your AI teammate, running on your machine
- **Claude Code** — coding agent with Opus-level reasoning
- **agentmemory** — remembers everything across sessions
- **codegraph** — instant code understanding, no grep
- **understand-anything** — visual knowledge graph with guided tours & business domain mapping
- **n8n-mcp** — workflow automation via natural language
- **claude-context-mcp** — semantic code search via hybrid BM25 + dense vector retrieval
- **browser-use** — browser automation for AI agents (navigate, fill forms, extract data)
- **graphify** — multimodal knowledge graphs from code, docs, PDFs, images (type `/graphify`)
- **open-multi-agent** — TypeScript-native multi-agent orchestration (goal→task DAG→result)
- **jcodemunch-mcp** — token-efficient code retrieval (cuts code-reading tokens by 95%+)
- **OpenSpace** — self-evolving skills engine. 46% fewer tokens, auto-fixes broken skills, shares knowledge across all agents
- **last30days-skill** — research any topic across Reddit, X, YouTube, HN, Polymarket, GitHub — scored by social signals, not SEO
- **fastapi-mcp** — auto-expose any FastAPI endpoint as MCP tools for AI agents (adds MCP to your APIs in 3 lines)
- **Caliber** — auto-generates and maintains AI agent configs (CLAUDE.md, .cursorrules, MCP configs) so they never go stale
- **20+ professional skills** — engineering workflows pre-loaded
- **Smart model routing** — deepseek primary, Claude fallback
- **Chat platform** — talk to your AI on Discord, Slack, or Telegram

## Prerequisites — What You Need

The Hermes Stack runs locally on your machine. Here's exactly what you need before you start:

### Operating System

- **Linux** (Ubuntu 22.04+, Debian 12+, Fedora 39+, or any modern distro)
- **macOS** (Ventura 13.0+)
- **Windows** — requires WSL2 (Windows Subsystem for Linux). The installer runs inside WSL. If you don't have WSL2 set up, [follow Microsoft's guide](https://learn.microsoft.com/en-us/windows/wsl/install) first (free, takes ~10 min).

### API Keys (you bring these — we never see them)

| Service | Why you need it | Sign up |
|---|---|---|
| **OpenRouter** | Primary AI model access (DeepSeek V4 Flash) | [openrouter.ai](https://openrouter.ai) — free to sign up, pay-per-use (~$0.11/M tokens) |
| **Anthropic** | Claude Code for coding tasks | [console.anthropic.com](https://console.anthropic.com) — API key, pay-per-use |
| **Discord Bot** | Talk to your AI via Discord | [discord.com/developers](https://discord.com/developers) — free to create a bot |
| **GitHub** | CodeGraph code intelligence | Your existing GitHub account or a [personal access token](https://github.com/settings/tokens) |

All keys stay on your machine. The installer prompts you for each one — they're stored locally and never sent anywhere.

### Hardware

- **Minimum:** 8GB RAM, 10GB free disk
- **Recommended:** 16GB+ RAM, SSD
- No GPU required. Everything runs on CPU or via API.

### Time

- **10–15 minutes** for the full install
- Most of that is waiting for downloads. The wizard handles everything.

## How It Works

1. You run the install command
2. The installer detects your OS and installs dependencies (Node.js, Python, git)
3. A setup wizard walks you through each API key — paste them in, they stay local
4. Tools, skills, and configs are deployed
5. You chat with your AI teammate on Discord 5 minutes later

## Your Data

Everything runs locally. Your API keys, your conversations, your code — none of it goes to us. You're buying the installer and the configs, not a service. You own it.

## Pricing

**$1,497** — one-time setup. No subscriptions. Your AI, your machine, your data.

Includes lifetime access to the installer and all future updates to skills, configs, and tool wiring. Updates are delivered via `--update` flag — merges new tools without touching your config.

[Buy Now](https://ryansaisetup.com/products.html) · [Book a Free Call](https://cal.com/ryansaisetup/consultation)

---

*Built by Ryan's AI Setup. Not affiliated with Anthropic, Discord, or any API provider.*