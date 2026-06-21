# Hermes Stack — Premium AI Teammate

One command. Full stack. Your AI teammate today.

```sh
curl -fsSL https://raw.githubusercontent.com/Sitting-sucks/hermes-stack/main/install.sh | bash
```

## What you get

- **Hermes Agent** — your AI teammate, running on your machine
- **Coding agent of your choice** — Claude Code, OpenAI Codex, or Cursor IDE (all wired with the same MCP servers)
- **Obsidian Knowledge Vault** — persistent, unlimited memory in plain markdown you own
- **codegraph** — instant code understanding, no grep
- **understand-anything** — visual knowledge graph with guided tours & business domain mapping
- **n8n-mcp** — workflow automation via natural language
- **claude-context-mcp** — semantic code search via hybrid BM25 + dense vector retrieval
- **browser-use** — browser automation for AI agents (navigate, fill forms, extract data)
- **Webwright** — Microsoft Research's SOTA browser agent (86.7% Mind2Web, 60.1% Odysseys). Terminal-native: writes Playwright code, not click coordinates. Installed as Hermes skill + CLI tool.
- **SkillSpector** — NVIDIA's security scanner for AI agent skills. 64 vulnerability patterns across 16 categories. Scans every skill before installation. Catches prompt injection, data exfiltration, malicious code execution — before they reach your stack. v2.1.4, Apache 2.0.
- **graphify** — multimodal knowledge graphs from code, docs, PDFs, images (type `/graphify`)
- **open-multi-agent** — TypeScript-native multi-agent orchestration (goal→task DAG→result)
- **jcodemunch-mcp** — token-efficient code retrieval (cuts code-reading tokens by 95%+)
- **OpenSpace** — self-evolving skills engine. 46% fewer tokens, auto-fixes broken skills, shares knowledge across all agents
- **last30days-skill** — research any topic across Reddit, X, YouTube, HN, Polymarket, GitHub — scored by social signals, not SEO
- **fastapi-mcp** — auto-expose any FastAPI endpoint as MCP tools for AI agents (adds MCP to your APIs in 3 lines)
- **Caliber** — auto-generates and maintains AI agent configs (CLAUDE.md, .cursorrules, MCP configs) so they never go stale
- **Open Notebook** — self-hosted NotebookLM alternative. Turn research docs into podcasts, summaries, and multi-model AI research briefs. 18+ AI providers. Part of the Sitting Sucks content pipeline.
- **Gemini CLI** — Google's open-source terminal AI agent. Free Gemini 2.5 Pro with 1M token context. Backup coding agent with Google Search grounding. 60 req/min, 1000 req/day free.
- **ContextGem** — LLM-powered structured data extraction from documents. Contracts, reports, research papers → structured JSON with paragraph-level references and justifications. Part of the Sitting Sucks content pipeline.
- **agent-skills (addyosmani)** — production-grade engineering skills from Google Chrome's Addy Osmani. v0.6.0: 7 slash commands, 24 skills, 3-tier orchestration (Personas → Skills → Commands). Parallel /ship runs code-reviewer, security-auditor, and test-engineer concurrently. New: doubt-driven-development (adversarial fresh-context review on in-flight decisions), source-driven-development (grounds framework decisions in official docs). Encodes Google engineering culture: spec-driven, test-first, security review, trunk-based deployment.
- **Obsidian Knowledge Vault** — your persistent, unlimited memory. QMD structure (Projects, Knowledge, People, Decisions, Clients, Revenue, Trading, Journal). Shared between you, your AI agent, and your coding agent. Plain markdown files you own — no caps, no cloud, no subscription. Your AI reads it for context at session start and writes Journal entries after sessions.
- **codebase-memory-mcp** — fastest code intelligence engine (158 languages, sub-ms queries, 99% fewer tokens)
- **OpenMontage** — agentic video production system (12 pipelines, 52 tools, 500+ skills)
- **20+ professional skills** — engineering workflows pre-loaded
- **Smart model routing** — deepseek primary, Claude fallback
- **Chat platform** — talk to your AI on Discord, Slack, or Telegram
- **Claude HUD** — real-time heads-up display for Claude Code. Context health, tool activity, subagent tracking, rate limits — always visible below your input
- **Superpowers** — battle-tested agentic dev methodology (227K+ stars). Enforces design → plan → TDD → review workflow so your agent ships clean code

| **New in v2026.6.18** |
- **codebase-memory-mcp** — The fastest code intelligence engine for AI agents. Full-indexes an average repo in milliseconds, Linux kernel in 3 minutes. 158 languages, sub-ms structural queries, 99% fewer tokens. Single static C binary — no Docker, no runtime deps, no API key. 14 MCP tools. Auto-detects and configures Hermes, Claude Code, Codex, Gemini CLI, Cursor, and 7 other agents. MIT license. 4K+ stars, trending #1 on GitHub.
- **OpenMontage** — World's first open-source, agentic video production system. 12 production pipelines, 52 tools, 500+ agent skills. Turn your AI coding assistant into a full video production studio. Makes real videos from free stock footage + open archives — not the "animate stills" trick. Multi-point self-review: ffprobe validation, frame sampling, audio level analysis. Sitting Sucks content pipeline integration. AGPL-3.0. 5.6K+ stars.

| **New in v2026.6.17**|

- **Hyper-Extract** — CLI-first knowledge extraction engine. Turns unstructured text into 8 types of structured knowledge: graphs, hypergraphs, temporal/spatial graphs, and more. One `he parse` command. 80+ domain templates. Complements graphify and understand-anything with deeper extraction capabilities. Apache 2.0.
- **PaddleOCR MCP** — Industrial OCR as an MCP server for AI agents. PP-OCRv6 text detection + PP-StructureV3 layout parsing. Your agents can OCR images, scanned PDFs, and documents on demand. Closes the gap MarkItDown can't handle (images, scans). 45K+ stars, Apache 2.0.

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