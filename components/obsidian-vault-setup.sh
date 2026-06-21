#!/usr/bin/env bash
# obsidian-vault-setup.sh — Obsidian QMD (Quiet Multi-Directory) memory vault
# Scaffolds a persistent, unlimited, human-readable memory vault shared between
# you, your AI agent, and your coding agent. Replaces capped agent memory with
# a visible, searchable, linkable knowledge base you actually own.
#
# The vault uses the QMD structure: Projects, Knowledge, People, Decisions,
# Clients, Revenue, Trading, Journal. Every note is a markdown file you can
# read, edit, and version-control. Your AI reads it for context at session
# start and writes to it after sessions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_ENV="${HOME}/.hermes/.env"

# Default vault location — user can override
VAULT_NAME="Knowledge Vault"
DEFAULT_VAULT_PATH="${HOME}/${VAULT_NAME}"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

# QMD directory structure — each serves a purpose
VAULT_DIRS=(
    "Projects"
    "Knowledge"
    "People"
    "Decisions"
    "Clients"
    "Revenue"
    "Trading"
    "Journal"
)

create_vault_structure() {
    local vault_path="$1"

    log "Scaffolding QMD vault structure at: $vault_path"

    for dir in "${VAULT_DIRS[@]}"; do
        mkdir -p "$vault_path/$dir"
    done

    # Home.md — vault index
    if [[ ! -f "$vault_path/Home.md" ]]; then
        cat > "$vault_path/Home.md" << 'HOMEMD'
# 🧠 Knowledge Vault

Your persistent, unlimited memory — shared between you and your AI teammates.

## Structure

| Folder | Purpose |
|--------|---------|
| **Projects/** | Active projects with status and next actions |
| **Knowledge/** | Tool configs, workflows, learnings, setup guides |
| **People/** | Profiles and contact notes |
| **Decisions/** | Key decisions with rationale (date-stamped) |
| **Clients/** | Client logs and project status |
| **Revenue/** | Product tracking, sales, and goals |
| **Trading/** | Trading strategies, logs, and patterns |
| **Journal/** | Session summaries (YYYY-MM-DD Title.md) |

## How It Works

1. **Your AI reads this vault at session start** for instant context
2. **During sessions**, your AI updates notes and references existing content
3. **After sessions**, your AI writes a Journal entry with a date-stamped summary
4. **Link everything** with `[[Note Name]]` wikilinks to connect related ideas

## Note Format

```markdown
# Note Title
## Key facts
- Bulleted facts
## Related
[[Other Note]] — why connected
```

## Why Obsidian?

- **Unlimited** — no character caps, no token limits, no subscription
- **Visible** — plain markdown files you can read and edit anytime
- **Yours** — lives on your machine, not in someone's cloud
- **Searchable** — full-text search, backlinks, graph view
- **Shared** — your AI agent and coding agent both read and write here

---

*This vault was scaffolded by the Hermes Stack installer. Grow it over time — every note makes your AI smarter.*
HOMEMD
        ok "Created Home.md vault index"
    fi

    # Starter note: Knowledge/Vault Structure.md
    if [[ ! -f "$vault_path/Knowledge/Vault Structure.md" ]]; then
        cat > "$vault_path/Knowledge/Vault Structure.md" << 'STRUCTMD'
# Knowledge Vault Structure

## Overview

The vault uses the QMD (Quiet Multi-Directory) pattern — each folder has a clear
purpose, notes stay organized without rigid taxonomies, and everything is
cross-linked with wikilinks.

## Directory Guide

### Projects/
Active projects. Each project gets its own note with:
- Status (active, paused, shipped, killed)
- Goal
- Next actions
- Blockers
- Related notes

### Knowledge/
Tool configurations, workflows, learnings, setup guides. This is where your AI
documents how things work so future sessions don't re-learn everything.

### People/
Profiles, contact info, relationship notes. Clients, collaborators, mentors.

### Decisions/
Key decisions with rationale. Date-stamped. When you make a meaningful choice,
log it here so future-you (and your AI) knows why.

### Clients/
Client logs, project status, deliverables, communication history.

### Revenue/
Product tracking, sales data, revenue goals, pricing decisions.

### Trading/
Trading strategies, position logs, market patterns, bot performance.

### Journal/
Session summaries. Format: `YYYY-MM-DD Title.md`. Your AI writes here after
each session — what was done, what was decided, what's next.

## Linking

Use `[[Note Name]]` to create wikilinks. Obsidian builds a graph of connections
automatically. The more you link, the smarter the vault becomes.
STRUCTMD
        ok "Created Knowledge/Vault Structure.md"
    fi

    # Starter note: Journal/ welcome entry
    if [[ ! -f "$vault_path/Journal/Welcome.md" ]]; then
        local today
        today=$(date +%Y-%m-%d)
        cat > "$vault_path/Journal/Welcome.md" << "WELCOMEMD"
# ${today} — Vault Initialized

## What Happened
- Hermes Stack installer scaffolded this Knowledge Vault
- QMD directory structure created
- Home.md index written
- OBSIDIAN_VAULT_PATH configured

## Next Steps
- Open this folder in Obsidian (File → Open vault → choose this folder)
- Start adding notes as you work
- Your AI will read this vault at the start of every session for context
- Your AI will write Journal entries after sessions

## Notes
This is your memory now. Grow it. Every note makes your AI smarter and your
future sessions faster.

[[Vault Structure]] — how the folders work
WELCOMEMD
        ok "Created Journal/Welcome.md"
    fi
}

configure_env() {
    local vault_path="$1"

    log "Configuring OBSIDIAN_VAULT_PATH in ~/.hermes/.env"

    # Determine the Windows path if on WSL
    local env_value="$vault_path"
    if grep -qi microsoft /proc/version 2>/dev/null; then
        # WSL — convert /mnt/x/... to X:\...
        if [[ "$vault_path" =~ ^/mnt/([a-zA-Z])/(.*)$ ]]; then
            local drive="${BASH_REMATCH[1]}"
            local rest="${BASH_REMATCH[2]}"
            env_value=$(echo "${drive^^}:\\${rest//\//\\}")
        fi
    fi

    if [[ -f "$HERMES_ENV" ]]; then
        if grep -q "^OBSIDIAN_VAULT_PATH=" "$HERMES_ENV"; then
            # Update existing
            sed -i "s|^OBSIDIAN_VAULT_PATH=.*|OBSIDIAN_VAULT_PATH=${env_value}|" "$HERMES_ENV"
        else
            # Append
            echo "OBSIDIAN_VAULT_PATH=${env_value}" >> "$HERMES_ENV"
        fi
    else
        mkdir -p "$(dirname "$HERMES_ENV")"
        echo "OBSIDIAN_VAULT_PATH=${env_value}" > "$HERMES_ENV"
    fi

    ok "OBSIDIAN_VAULT_PATH=${env_value}"
}

install_obsidian_vault() {
    log "Setting up Obsidian Knowledge Vault..."

    # Check for existing vault (respect user's setup)
    local vault_path="$DEFAULT_VAULT_PATH"

    # If env already has a path, use that
    if [[ -f "$HERMES_ENV" ]] && grep -q "^OBSIDIAN_VAULT_PATH=" "$HERMES_ENV"; then
        local existing
        existing=$(grep "^OBSIDIAN_VAULT_PATH=" "$HERMES_ENV" | cut -d= -f2- | tr -d '\r')
        if [[ -n "$existing" && -d "$existing" ]]; then
            log "Found existing vault at: $existing"
            vault_path="$existing"
            ok "Using existing vault — will not overwrite notes"
            # Ensure structure is complete (creates missing dirs/notes only)
            create_vault_structure "$vault_path"
            return 0
        fi
    fi

    # Check default location
    if [[ -d "$vault_path" && -f "$vault_path/Home.md" ]]; then
        log "Vault already exists at: $vault_path"
        ok "Using existing vault — will not overwrite notes"
        create_vault_structure "$vault_path"
        configure_env "$vault_path"
        return 0
    fi

    # Create new vault
    create_vault_structure "$vault_path"
    configure_env "$vault_path"

    ok "Obsidian Knowledge Vault ready at: $vault_path"
    log ""
    log "Next steps:"
    log "  1. Open Obsidian → File → Open vault → choose: $vault_path"
    log "  2. Your AI agent reads this vault at session start for context"
    log "  3. Your AI writes Journal entries after sessions"
    log ""
    log "This is your persistent memory now. Unlimited, visible, yours."
}

install_obsidian_vault
