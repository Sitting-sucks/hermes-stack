#!/usr/bin/env python3
"""
Hermes Stack — interactive setup wizard.

Prompts for API keys, validates them, then writes config files for:
  - ~/.hermes/.env
  - ~/.hermes/config.yaml
  - ~/.claude.json (MCP server registry)
  - ~/.claude/CLAUDE.md
  - ~/.claude/settings.json

Also copies bundled skills into ~/.claude/skills/.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from string import Template
from typing import Optional

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import Prompt, Confirm
    from rich.table import Table
    from rich.text import Text
    from rich import box
except ImportError:
    sys.stderr.write(
        "[hermes] Missing dependency 'rich'. Install with: "
        "python3 -m pip install --user rich pyyaml requests\n"
    )
    sys.exit(1)

try:
    import yaml
except ImportError:
    sys.stderr.write(
        "[hermes] Missing dependency 'pyyaml'. Install with: "
        "python3 -m pip install --user pyyaml\n"
    )
    sys.exit(1)

try:
    import requests
except ImportError:
    sys.stderr.write(
        "[hermes] Missing dependency 'requests'. Install with: "
        "python3 -m pip install --user requests\n"
    )
    sys.exit(1)


console = Console()

HOME = Path.home()
HERMES_DIR = HOME / ".hermes"
CLAUDE_DIR = HOME / ".claude"
CLAUDE_SKILLS_DIR = CLAUDE_DIR / "skills"
CLAUDE_JSON = HOME / ".claude.json"

ENV_PATH = HERMES_DIR / ".env"
CONFIG_PATH = HERMES_DIR / "config.yaml"
CLAUDE_MD_PATH = CLAUDE_DIR / "CLAUDE.md"
SETTINGS_JSON_PATH = CLAUDE_DIR / "settings.json"


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class ChatPlatform:
    """Holds whichever chat-platform credentials the user provided."""
    kind: str = "none"  # discord | slack | telegram | none
    token: str = ""
    webhook: str = ""


@dataclass
class WizardAnswers:
    openrouter_key: str = ""
    anthropic_key: str = ""
    google_email: str = ""
    primary_model: str = "deepseek/deepseek-chat"
    fallback_model: str = "claude-sonnet-4-5"
    chat: ChatPlatform = field(default_factory=ChatPlatform)
    enable_n8n: bool = False
    n8n_url: str = ""
    n8n_api_key: str = ""
    obsidian_vault_path: str = ""

    def to_redacted_dict(self) -> dict:
        d = asdict(self)
        for k in ("openrouter_key", "anthropic_key", "n8n_api_key"):
            if d.get(k):
                d[k] = d[k][:6] + "…(redacted)"
        chat = d.get("chat") or {}
        for k in ("token", "webhook"):
            if chat.get(k):
                chat[k] = chat[k][:6] + "…(redacted)"
        return d


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

def banner() -> None:
    text = Text()
    text.append("Hermes Stack — Setup Wizard\n", style="bold cyan")
    text.append(
        "Configure your AI teammate: keys, models, MCP servers, and skills.\n",
        style="dim",
    )
    console.print(Panel(text, box=box.ROUNDED, border_style="cyan"))


def section(title: str) -> None:
    console.print()
    console.print(Panel.fit(f"[bold]{title}[/bold]", border_style="blue"))


def secret_prompt(label: str, *, optional: bool = False, default: str = "") -> str:
    suffix = " [dim](optional, press Enter to skip)[/dim]" if optional else ""
    while True:
        value = Prompt.ask(
            f"[bold]{label}[/bold]{suffix}",
            password=True,
            default=default,
            show_default=False,
        ).strip()
        if value or optional:
            return value
        console.print("[red]A value is required.[/red]")


def info(msg: str) -> None:
    console.print(f"[cyan]›[/cyan] {msg}")


def ok(msg: str) -> None:
    console.print(f"[green]✓[/green] {msg}")


def warn(msg: str) -> None:
    console.print(f"[yellow]![/yellow] {msg}")


def fail(msg: str) -> None:
    console.print(f"[red]✗[/red] {msg}")


# ---------------------------------------------------------------------------
# Validators (real network calls, with graceful fallback)
# ---------------------------------------------------------------------------

def validate_openrouter(key: str) -> bool:
    """Hits OpenRouter /api/v1/auth/key to confirm the key is live."""
    if not key:
        return False
    try:
        resp = requests.get(
            "https://openrouter.ai/api/v1/auth/key",
            headers={"Authorization": f"Bearer {key}"},
            timeout=8,
        )
        return resp.status_code == 200
    except requests.RequestException as e:
        warn(f"Could not reach OpenRouter for validation: {e}")
        return False


def validate_anthropic(key: str) -> bool:
    """Hits Anthropic /v1/models to confirm the key is live."""
    if not key:
        return False
    try:
        resp = requests.get(
            "https://api.anthropic.com/v1/models",
            headers={
                "x-api-key": key,
                "anthropic-version": "2023-06-01",
            },
            timeout=8,
        )
        return resp.status_code == 200
    except requests.RequestException as e:
        warn(f"Could not reach Anthropic for validation: {e}")
        return False


def validate_discord(token: str) -> bool:
    if not token:
        return False
    try:
        resp = requests.get(
            "https://discord.com/api/v10/users/@me",
            headers={"Authorization": f"Bot {token}"},
            timeout=8,
        )
        return resp.status_code == 200
    except requests.RequestException as e:
        warn(f"Could not reach Discord for validation: {e}")
        return False


def validate_slack_webhook(url: str) -> bool:
    """Light validation: ensure the URL shape is correct. Real POSTs are intrusive."""
    return url.startswith("https://hooks.slack.com/services/")


def validate_telegram(token: str) -> bool:
    if not token:
        return False
    try:
        resp = requests.get(
            f"https://api.telegram.org/bot{token}/getMe",
            timeout=8,
        )
        if resp.status_code != 200:
            return False
        data = resp.json()
        return bool(data.get("ok"))
    except requests.RequestException as e:
        warn(f"Could not reach Telegram for validation: {e}")
        return False
    except ValueError:
        return False


# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------

def prompt_openrouter() -> str:
    section("OpenRouter API Key")
    console.print(
        "Get a key at [link]https://openrouter.ai/keys[/link]. "
        "This is used as the primary LLM gateway.\n"
    )
    while True:
        key = secret_prompt("OpenRouter API key", optional=False)
        info("Validating key against OpenRouter…")
        if validate_openrouter(key):
            ok("OpenRouter key validated.")
            return key
        fail("That key did not validate. Try again, or press Ctrl-C to abort.")


def prompt_anthropic() -> str:
    section("Anthropic API Key (optional)")
    console.print(
        "Used for the Claude fallback model. Skip if you only want OpenRouter.\n"
        "Get a key at [link]https://console.anthropic.com/settings/keys[/link].\n"
    )
    key = secret_prompt("Anthropic API key", optional=True)
    if not key:
        warn("Skipping Anthropic — fallback model will be unavailable.")
        return ""
    info("Validating key against Anthropic…")
    if validate_anthropic(key):
        ok("Anthropic key validated.")
        return key
    fail("That key did not validate. Saving it anyway — fix later if needed.")
    return key


def prompt_chat() -> ChatPlatform:
    section("Chat Platform")
    console.print(
        "Hermes can post updates and accept commands from a chat platform.\n"
        "Pick one (or skip):\n"
    )
    choice = Prompt.ask(
        "[bold]Platform[/bold]",
        choices=["discord", "slack", "telegram", "none"],
        default="none",
    )

    if choice == "none":
        return ChatPlatform(kind="none")

    if choice == "discord":
        while True:
            token = secret_prompt("Discord bot token", optional=False)
            info("Validating Discord bot token…")
            if validate_discord(token):
                ok("Discord token validated.")
                return ChatPlatform(kind="discord", token=token)
            fail("Token rejected. Try again.")
            if not Confirm.ask("Retry?", default=True):
                return ChatPlatform(kind="none")

    if choice == "slack":
        while True:
            webhook = Prompt.ask("[bold]Slack incoming webhook URL[/bold]")
            if validate_slack_webhook(webhook):
                ok("Slack webhook URL looks good.")
                return ChatPlatform(kind="slack", webhook=webhook)
            fail("That doesn't look like a Slack webhook URL.")
            if not Confirm.ask("Retry?", default=True):
                return ChatPlatform(kind="none")

    if choice == "telegram":
        while True:
            token = secret_prompt("Telegram bot token", optional=False)
            info("Validating Telegram bot token…")
            if validate_telegram(token):
                ok("Telegram token validated.")
                return ChatPlatform(kind="telegram", token=token)
            fail("Token rejected. Try again.")
            if not Confirm.ask("Retry?", default=True):
                return ChatPlatform(kind="none")

    return ChatPlatform(kind="none")


def prompt_google() -> str:
    section("Google Workspace (informational)")
    console.print(
        "If you want Gmail / Calendar / Drive access, the wizard will print "
        "instructions for OAuth setup at the end. Enter the email you'll use.\n"
    )
    email = Prompt.ask("[bold]Google email[/bold]", default="").strip()
    if email and "@" not in email:
        warn("That doesn't look like an email — saving as-is.")
    return email


def prompt_models() -> tuple[str, str]:
    section("Model Routing")
    console.print(
        "Hermes routes requests through a primary model and falls back if it errors.\n"
    )
    primary = Prompt.ask(
        "[bold]Primary model[/bold]",
        default="deepseek/deepseek-chat",
    )
    fallback = Prompt.ask(
        "[bold]Fallback model[/bold]",
        default="claude-sonnet-4-5",
    )
    return primary, fallback


def prompt_n8n() -> tuple[bool, str, str]:
    section("n8n (optional automation)")
    if not Confirm.ask("Wire up n8n as an MCP server?", default=False):
        return False, "", ""

    url = Prompt.ask(
        "[bold]n8n base URL[/bold]",
        default="http://localhost:5678",
    ).strip()
    api_key = secret_prompt("n8n API key", optional=True)
    return True, url, api_key


def prompt_obsidian() -> str:
    section("Obsidian Knowledge Vault")
    info(
        "Your persistent, unlimited memory — shared between you, your AI agent, "
        "and your coding agent. Plain markdown files you own."
    )
    if not Confirm.ask("Scaffold an Obsidian vault for persistent memory?", default=True):
        return ""

    default_path = str(Path.home() / "Knowledge Vault")
    path = Prompt.ask(
        "[bold]Vault location[/bold]",
        default=default_path,
    ).strip()
    return path


# ---------------------------------------------------------------------------
# Config writers
# ---------------------------------------------------------------------------

def load_template(installer_dir: Path, name: str) -> str:
    path = installer_dir / "templates" / name
    if not path.exists():
        raise FileNotFoundError(f"Template not found: {path}")
    return path.read_text(encoding="utf-8")


def write_file(path: Path, content: str, *, mode: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    if mode is not None:
        os.chmod(path, mode)
    ok(f"Wrote {path}")


def render_env(answers: WizardAnswers, installer_dir: Path) -> str:
    tpl = Template(load_template(installer_dir, "env.template"))
    return tpl.safe_substitute(
        OPENROUTER_API_KEY=answers.openrouter_key or "YOUR_OPENROUTER_API_KEY_HERE",
        ANTHROPIC_API_KEY=answers.anthropic_key or "YOUR_ANTHROPIC_API_KEY_HERE",
        DISCORD_BOT_TOKEN=(
            answers.chat.token if answers.chat.kind == "discord"
            else "YOUR_DISCORD_BOT_TOKEN_HERE"
        ),
        SLACK_WEBHOOK_URL=(
            answers.chat.webhook if answers.chat.kind == "slack"
            else "YOUR_SLACK_WEBHOOK_URL_HERE"
        ),
        TELEGRAM_BOT_TOKEN=(
            answers.chat.token if answers.chat.kind == "telegram"
            else "YOUR_TELEGRAM_BOT_TOKEN_HERE"
        ),
        GOOGLE_WORKSPACE_EMAIL=answers.google_email or "YOUR_GOOGLE_EMAIL_HERE",
        N8N_BASE_URL=answers.n8n_url or "http://localhost:5678",
        N8N_API_KEY=answers.n8n_api_key or "YOUR_N8N_API_KEY_HERE",
        OBSIDIAN_VAULT_PATH=answers.obsidian_vault_path or str(Path.home() / "Knowledge Vault"),
    )


def render_config_yaml(answers: WizardAnswers, installer_dir: Path) -> str:
    tpl = Template(load_template(installer_dir, "config.yaml.template"))
    return tpl.safe_substitute(
        PRIMARY_MODEL=answers.primary_model,
        FALLBACK_MODEL=answers.fallback_model,
        CHAT_PLATFORM=answers.chat.kind,
        N8N_ENABLED=str(answers.enable_n8n).lower(),
        N8N_BASE_URL=answers.n8n_url or "http://localhost:5678",
    )


def render_claude_json(answers: WizardAnswers, installer_dir: Path) -> dict:
    raw = load_template(installer_dir, "claude.json.template")
    rendered = Template(raw).safe_substitute(
        N8N_BASE_URL=answers.n8n_url or "http://localhost:5678",
        N8N_API_KEY=answers.n8n_api_key or "YOUR_N8N_API_KEY_HERE",
    )
    data = json.loads(rendered)

    if not answers.enable_n8n:
        servers = data.get("mcpServers", {})
        servers.pop("n8n-mcp", None)

    return data


def merge_claude_json(new_data: dict) -> None:
    """Merge new MCP server config into existing ~/.claude.json without clobbering."""
    existing: dict = {}
    if CLAUDE_JSON.exists():
        try:
            existing = json.loads(CLAUDE_JSON.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            warn(f"Existing {CLAUDE_JSON} is not valid JSON — backing up and replacing.")
            backup = CLAUDE_JSON.with_suffix(".json.bak")
            shutil.copy2(CLAUDE_JSON, backup)
            existing = {}

    merged = dict(existing)
    incoming_servers = new_data.get("mcpServers", {})
    existing_servers = merged.get("mcpServers", {})
    existing_servers.update(incoming_servers)
    merged["mcpServers"] = existing_servers

    CLAUDE_JSON.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")
    ok(f"Wrote {CLAUDE_JSON}")


def write_claude_md(answers: WizardAnswers) -> None:
    primary = answers.primary_model
    fallback = answers.fallback_model
    chat = answers.chat.kind
    content = f"""# Project Context (Hermes Stack)

This machine is configured by the Hermes Stack installer.

## Model routing
- Primary: `{primary}` (via OpenRouter)
- Fallback: `{fallback}` (via Anthropic)

## Active MCP servers
- `agentmemory` — durable memory across sessions
- `codegraph` — symbol-aware code intelligence

## Active skills
- `understand-anything` — visual knowledge graph for codebase exploration (run `/understand`)

## Chat platform
- {chat if chat != "none" else "none configured"}

## Operating guidance
- Prefer the primary model unless the task explicitly needs Claude.
- Use `codegraph_*` tools for structural code questions before grepping.
- Persist user preferences via `agentmemory` so they survive between sessions.
"""
    write_file(CLAUDE_MD_PATH, content)


def write_settings_json() -> None:
    """Conservative defaults; merge if the file already exists."""
    defaults = {
        "permissions": {
            "allow": [
                "Bash(git status:*)",
                "Bash(git diff:*)",
                "Bash(git log:*)",
                "Bash(ls:*)",
                "Bash(mkdir:*)",
            ],
            "deny": [],
        },
        "env": {},
    }

    if SETTINGS_JSON_PATH.exists():
        try:
            existing = json.loads(SETTINGS_JSON_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            warn(f"Existing {SETTINGS_JSON_PATH} is not valid JSON — leaving it alone.")
            return
        # Shallow merge: only add what's missing.
        for key, value in defaults.items():
            existing.setdefault(key, value)
        SETTINGS_JSON_PATH.write_text(
            json.dumps(existing, indent=2) + "\n", encoding="utf-8"
        )
        ok(f"Updated {SETTINGS_JSON_PATH}")
        return

    write_file(SETTINGS_JSON_PATH, json.dumps(defaults, indent=2) + "\n")


def copy_skills(installer_dir: Path) -> int:
    src = installer_dir / "skills"
    if not src.exists():
        warn("No bundled skills/ directory found — skipping skill install.")
        return 0

    CLAUDE_SKILLS_DIR.mkdir(parents=True, exist_ok=True)
    count = 0
    for child in src.iterdir():
        if child.name.startswith("."):
            continue
        dest = CLAUDE_SKILLS_DIR / child.name
        if child.is_dir():
            shutil.copytree(child, dest, dirs_exist_ok=True)
        else:
            shutil.copy2(child, dest)
        count += 1

    if count:
        ok(f"Installed {count} skill(s) to {CLAUDE_SKILLS_DIR}")
    return count


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

def print_summary(answers: WizardAnswers) -> None:
    section("Summary")
    table = Table(box=box.SIMPLE_HEAVY, show_header=False)
    table.add_column("Key", style="bold cyan")
    table.add_column("Value")

    def mask(s: str) -> str:
        if not s:
            return "[dim](not set)[/dim]"
        return s[:6] + "…(hidden)"

    table.add_row("Primary model", answers.primary_model)
    table.add_row("Fallback model", answers.fallback_model)
    table.add_row("OpenRouter key", mask(answers.openrouter_key))
    table.add_row("Anthropic key", mask(answers.anthropic_key))
    table.add_row("Chat platform", answers.chat.kind)
    if answers.chat.kind in ("discord", "telegram"):
        table.add_row("Chat token", mask(answers.chat.token))
    elif answers.chat.kind == "slack":
        table.add_row("Slack webhook", mask(answers.chat.webhook))
    table.add_row("Google email", answers.google_email or "[dim](not set)[/dim]")
    table.add_row("n8n enabled", "yes" if answers.enable_n8n else "no")

    console.print(table)


def print_next_steps(answers: WizardAnswers) -> None:
    section("Next steps")
    console.print(
        "[bold]1.[/bold] Restart your shell so PATH changes take effect.\n"
        "[bold]2.[/bold] Run [cyan]claude[/cyan] in any project directory.\n"
        "[bold]3.[/bold] See [cyan]docs/QUICKSTART.md[/cyan] for first commands.\n"
        "[bold]4.[/bold] If something breaks, see [cyan]docs/TROUBLESHOOTING.md[/cyan].\n"
    )
    if answers.google_email:
        console.print(
            "[yellow]Google OAuth:[/yellow] visit https://console.cloud.google.com/, "
            "create a project, enable the Gmail/Calendar/Drive APIs, "
            "and add credentials. The Claude Code Gmail/Calendar/Drive MCP servers "
            "will prompt for OAuth on first use.\n"
        )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Hermes Stack setup wizard")
    p.add_argument(
        "--installer-dir",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="Directory containing templates/ and skills/",
    )
    p.add_argument(
        "--platform",
        default="unknown",
        help="OS detected by install.sh (informational only)",
    )
    p.add_argument(
        "--non-interactive",
        action="store_true",
        help="Write template defaults without prompting (for CI).",
    )
    return p.parse_args()


def run_wizard(installer_dir: Path) -> WizardAnswers:
    answers = WizardAnswers()
    answers.openrouter_key = prompt_openrouter()
    answers.anthropic_key = prompt_anthropic()
    answers.chat = prompt_chat()
    answers.google_email = prompt_google()
    answers.primary_model, answers.fallback_model = prompt_models()
    enable_n8n, n8n_url, n8n_api_key = prompt_n8n()
    answers.enable_n8n = enable_n8n
    answers.n8n_url = n8n_url
    answers.n8n_api_key = n8n_api_key
    answers.obsidian_vault_path = prompt_obsidian()
    return answers


def write_all(answers: WizardAnswers, installer_dir: Path) -> None:
    HERMES_DIR.mkdir(parents=True, exist_ok=True)
    CLAUDE_DIR.mkdir(parents=True, exist_ok=True)

    section("Writing configuration files")
    write_file(ENV_PATH, render_env(answers, installer_dir), mode=0o600)
    write_file(CONFIG_PATH, render_config_yaml(answers, installer_dir))

    claude_json = render_claude_json(answers, installer_dir)
    merge_claude_json(claude_json)

    write_claude_md(answers)
    write_settings_json()
    copy_skills(installer_dir)


def main() -> int:
    args = parse_args()
    installer_dir: Path = args.installer_dir.resolve()

    if not (installer_dir / "templates").is_dir():
        fail(f"Templates directory not found at {installer_dir / 'templates'}")
        return 2

    try:
        banner()

        if args.non_interactive:
            warn("Running in non-interactive mode — using template placeholders.")
            answers = WizardAnswers()
        else:
            answers = run_wizard(installer_dir)

        print_summary(answers)

        if not args.non_interactive and not Confirm.ask(
            "Write these files now?", default=True
        ):
            warn("Aborted by user. Nothing was written.")
            return 1

        write_all(answers, installer_dir)
        print_next_steps(answers)
        console.print("[bold green]Hermes Stack setup complete.[/bold green]\n")
        return 0

    except KeyboardInterrupt:
        console.print()
        warn("Wizard cancelled by user.")
        return 130
    except Exception as e:
        fail(f"Wizard crashed: {e}")
        console.print_exception()
        return 1


if __name__ == "__main__":
    sys.exit(main())
