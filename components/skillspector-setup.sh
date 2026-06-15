#!/usr/bin/env bash
# skillspector-setup.sh — NVIDIA SkillSpector security scanner for AI agent skills
# Scans skills for vulnerabilities, malicious patterns, and security risks before installation.
# 64 vulnerability patterns across 16 categories. Risk scoring 0-100.
# GitHub: https://github.com/NVIDIA/SkillSpector
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")\" && pwd)"

C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RED='\033[31m'; C_RESET='\033[0m'
if [[ ! -t 1 ]]; then C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RED=""; C_RESET=""; fi

log()   { printf "%s[skillspector]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }
err()   { printf "%s[fail]%s %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; }

install_skillspector() {
    log "Installing NVIDIA SkillSpector (AI agent skill vulnerability scanner)..."

    # Check if already installed
    if command -v skillspector &>/dev/null; then
        local ver
        ver=$(skillspector --version 2>/dev/null | head -1 || echo "installed")
        ok "SkillSpector $ver already installed"
        return 0
    fi

    # SkillSpector requires Python 3.12+
    local py_cmd=""
    for cmd in python3.12 python3.13 python3; do
        if command -v "$cmd" &>/dev/null; then
            local ver
            ver=$("$cmd" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
            local major="${ver%%.*}"
            local minor="${ver##*.}"
            if [[ "$major" -gt 3 ]] || { [[ "$major" -eq 3 ]] && [[ "$minor" -ge 12 ]]; }; then
                py_cmd="$cmd"
                break
            fi
        fi
    done

    if [[ -z "$py_cmd" ]]; then
        err "Python 3.12+ required for SkillSpector. Install with:"
        err "  sudo apt-get install python3.12 python3.12-venv   # Ubuntu/Debian"
        err "  brew install python@3.12                          # macOS"
        warn "SkillSpector install deferred — skipping (try again after installing Python 3.12+)"
        return 1
    fi

    # Install via pip — installs the 'skillspector' CLI
    if $py_cmd -m pip install --user --break-system-packages git+https://github.com/NVIDIA/SkillSpector.git 2>/dev/null; then
        ok "SkillSpector installed via pip"
    else
        # Fallback: try without --break-system-packages
        if $py_cmd -m pip install --user git+https://github.com/NVIDIA/SkillSpector.git 2>/dev/null; then
            ok "SkillSpector installed via pip"
        else
            warn "pip install failed — trying uv..."
            if command -v uv &>/dev/null; then
                uv tool install --python "$py_cmd" git+https://github.com/NVIDIA/SkillSpector.git 2>/dev/null && \
                    ok "SkillSpector installed via uv" || \
                    warn "uv install failed"
            else
                warn "SkillSpector install failed — skipping (non-critical)"
                return 1
            fi
        fi
    fi

    # Verify installation
    if command -v skillspector &>/dev/null; then
        local ver
        ver=$(skillspector --version 2>/dev/null | head -1 || echo "installed")
        ok "SkillSpector $ver ready"
    else
        # Check if it's in .local/bin
        if [[ -f "$HOME/.local/bin/skillspector" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            ok "SkillSpector found in ~/.local/bin"
        else
            warn "skillspector CLI not in PATH — you may need to add ~/.local/bin to your PATH"
            return 1
        fi
    fi
}

show_usage() {
    echo ""
    echo "  SkillSpector usage:"
    echo "    skillspector scan ./path/to/skill/          # Scan a skill directory"
    echo "    skillspector scan ./SKILL.md                # Scan a single skill file"
    echo "    skillspector scan https://github.com/user/repo  # Scan a Git repo"
    echo "    skillspector scan ./skill.zip               # Scan a zip archive"
    echo "    skillspector scan ./skill/ --format json    # JSON output"
    echo ""
    echo "  Scan your Hermes skills:"
    echo "    skillspector scan ~/.hermes/skills/ --no-llm"
    echo ""
    echo "  Docs: https://github.com/NVIDIA/SkillSpector"
    echo ""
}

main() {
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  NVIDIA SkillSpector                                        │"
    echo "  │  Security Scanner for AI Agent Skills                       │"
    echo "  │  64 patterns · 16 categories · Risk scoring (0-100)        │"
    echo "  │  Apache 2.0 · github.com/NVIDIA/SkillSpector                │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""

    install_skillspector
    show_usage

    if command -v skillspector &>/dev/null; then
        ok "SkillSpector setup complete."
    fi
}

main "$@"