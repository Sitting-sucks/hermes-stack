#!/usr/bin/env bash
# Omnigent Setup — Databricks open-source meta-harness for AI agents
# Wraps Claude Code, Codex, Pi, and custom agents in a unified interface
# with composition, governance policies, and live collaboration.
set -euo pipefail

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }
err()   { printf "\033[31m[fail]\033[0m %s\n" "$*" >&2; }

install_omnigent() {
    log "Installing Omnigent — meta-harness for all your AI agents..."

    # Check prerequisites
    local missing=()
    command -v python3 &>/dev/null || missing+=("python3 (3.12+)")
    command -v uv &>/dev/null || missing+=("uv (pip installer)")
    command -v git &>/dev/null || missing+=("git")
    command -v node &>/dev/null || missing+=("node (22 LTS+)")
    command -v npm &>/dev/null || missing+=("npm")
    command -v tmux &>/dev/null || missing+=("tmux")

    if [[ "$(uname -s)" == "Linux" ]] && ! command -v bwrap &>/dev/null; then
        missing+=("bubblewrap (bwrap)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing prerequisites: ${missing[*]}"
        log "Installing missing system packages..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq tmux bubblewrap 2>/dev/null || true
        elif command -v brew &>/dev/null; then
            brew install tmux 2>/dev/null || true
        fi
    fi

    # Check if already installed
    if command -v omnigent &>/dev/null; then
        local version
        version=$(omnigent --version 2>/dev/null || echo "installed")
        ok "Omnigent already installed ($version)"
        return 0
    fi

    # Install via uv (preferred) or pip
    log "Installing Omnigent via uv..."
    if command -v uv &>/dev/null; then
        uv tool install omnigent 2>&1 | tail -3
    else
        pip install omnigent 2>&1 | tail -3
    fi

    # Verify installation
    if command -v omnigent &>/dev/null; then
        ok "Omnigent installed successfully"
        log "Run 'omnigent setup' to configure models (OpenRouter, Anthropic, etc.)"
        log "Run 'omnigent' to start your first meta-agent session"
        log "Web UI available at http://localhost:6767"
    else
        err "Omnigent installation failed"
        return 1
    fi
}

# Configure Omnigent to use OpenRouter (our primary provider)
configure_omnigent_gateway() {
    log "Configuring Omnigent for Hermes Stack..."
    
    local config_dir="$HOME/.omnigent"
    mkdir -p "$config_dir"

    # If OpenRouter key exists in our env, suggest it
    if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
        log "OpenRouter API key detected — Omnigent can use it as a gateway"
        log "Run: omnigent setup → select 'Gateway' → paste OpenRouter key"
    fi

    ok "Omnigent ready — configure with 'omnigent setup'"
}

log "═══ Omnigent — Meta-Harness Installation ═══"
install_omnigent
configure_omnigent_gateway