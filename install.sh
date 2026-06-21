#!/usr/bin/env bash
# Hermes Stack Installer — bootstrap script
# Detects OS, installs prerequisites, launches the Python wizard.

set -euo pipefail

# ---------- colors ----------
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_CYAN=$'\033[36m'
else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""
    C_YELLOW=""; C_BLUE=""; C_CYAN=""
fi

log()   { printf "%s[hermes]%s %s\n" "${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf "%s[warn]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }
err()   { printf "%s[fail]%s %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; }
step()  { printf "\n%s==> %s%s\n" "${C_BOLD}" "$*" "${C_RESET}"; }

die() { err "$*"; exit 1; }

# ---------- banner ----------
print_banner() {
    cat <<'BANNER'

   _   _                                 ____  _             _
  | | | | ___ _ __ _ __ ___   ___  ___  / ___|| |_ __ _  ___| | __
  | |_| |/ _ \ '__| '_ ` _ \ / _ \/ __| \___ \| __/ _` |/ __| |/ /
  |  _  |  __/ |  | | | | | |  __/\__ \  ___) | || (_| | (__|   <
  |_| |_|\___|_|  |_| |_| |_|\___||___/ |____/ \__\__,_|\___|_|\_\

  Premium AI Teammate Installer

BANNER
}

# ---------- os detection ----------
detect_os() {
    local uname_s uname_m
    uname_s="$(uname -s 2>/dev/null || echo unknown)"
    uname_m="$(uname -m 2>/dev/null || echo unknown)"

    case "$uname_s" in
        Darwin)
            if [[ "$uname_m" == "arm64" ]]; then
                echo "macos-arm"
            else
                echo "macos-intel"
            fi
            ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null \
               || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ---------- helpers ----------
command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_dir() {
    local d="$1"
    [[ -d "$d" ]] || mkdir -p "$d"
}

# ---------- prereq installers ----------
install_homebrew() {
    if command_exists brew; then
        ok "Homebrew already installed"
        return 0
    fi
    step "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to current shell PATH for the rest of the script
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_nvm() {
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        ok "nvm already installed"
        # shellcheck disable=SC1091
        \. "$HOME/.nvm/nvm.sh"
        return 0
    fi
    step "Installing nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
}

install_node() {
    if command_exists node; then
        local v
        v="$(node -v 2>/dev/null | sed 's/^v//')"
        local major="${v%%.*}"
        if [[ "${major:-0}" -ge 18 ]]; then
            ok "Node.js $v already installed"
            return 0
        fi
        warn "Node.js $v is too old (need 18+), upgrading"
    fi

    step "Installing Node.js (LTS)"
    case "$OS" in
        macos-*)
            if command_exists brew; then
                brew install node
            else
                install_nvm
                nvm install --lts
                nvm use --lts
            fi
            ;;
        linux|wsl)
            install_nvm
            nvm install --lts
            nvm use --lts
            ;;
        *)
            die "Unsupported OS for Node install: $OS"
            ;;
    esac
}

install_python() {
    if command_exists python3; then
        local pyv major minor
        pyv="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
        major="${pyv%%.*}"
        minor="${pyv##*.}"
        if [[ "$major" -gt 3 ]] || { [[ "$major" -eq 3 ]] && [[ "$minor" -ge 10 ]]; }; then
            ok "Python $pyv already installed"
            return 0
        fi
        warn "Python $pyv is too old (need 3.10+)"
    fi

    step "Installing Python 3"
    case "$OS" in
        macos-*)
            brew install python@3.12
            ;;
        linux|wsl)
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip python3-venv
            elif command_exists dnf; then
                sudo dnf install -y python3 python3-pip
            elif command_exists pacman; then
                sudo pacman -S --noconfirm python python-pip
            else
                die "No supported package manager found for Python install"
            fi
            ;;
    esac
}

install_git() {
    if command_exists git; then
        ok "git already installed"
        return 0
    fi
    step "Installing git"
    case "$OS" in
        macos-*) brew install git ;;
        linux|wsl)
            if command_exists apt-get; then sudo apt-get install -y git
            elif command_exists dnf; then sudo dnf install -y git
            elif command_exists pacman; then sudo pacman -S --noconfirm git
            else die "No supported package manager for git"
            fi
            ;;
    esac
}

install_python_deps() {
    step "Installing Python wizard dependencies"
    local pip_cmd="python3 -m pip"

    # Use --user when not in a venv to avoid PEP 668 surprises
    local user_flag="--user"
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        user_flag=""
    fi

    # --break-system-packages is needed on newer Debian/Ubuntu/macOS to override PEP 668
    if ! $pip_cmd install $user_flag --upgrade rich pyyaml requests >/dev/null 2>&1; then
        warn "pip install failed, retrying with --break-system-packages"
        $pip_cmd install $user_flag --break-system-packages --upgrade rich pyyaml requests
    fi
    ok "Python dependencies ready"
}

install_npm_packages() {
    step "Installing global npm packages"
    local packages=(
        "@agentmemory/agentmemory"
        "@colbymchenry/codegraph"
        "@zilliz/claude-context-mcp"
        "@open-multi-agent/core"
        "@rely-ai/caliber"
    )

    for pkg in "${packages[@]}"; do
        log "Installing $pkg"
        if ! npm install -g "$pkg" >/dev/null 2>&1; then
            warn "Global install of $pkg failed — you may need to rerun with sudo or fix your npm prefix"
        else
            ok "$pkg installed"
        fi
    done
}

install_understand_anything() {
    step "Installing Understand-Anything (visual codebase knowledge graph)"
    local install_script_url="https://raw.githubusercontent.com/Lum1104/Understand-Anything/main/install.sh"
    local tmp_script="/tmp/understand-anything-install.sh"
    if curl -fsSL -o "$tmp_script" "$install_script_url"; then
        if bash "$tmp_script" hermes >/dev/null 2>&1; then
            ok "Understand-Anything installed for Hermes"
        else
            warn "Understand-Anything install failed — skipping (non-critical)"
        fi
        rm -f "$tmp_script"
    else
        warn "Could not download Understand-Anything installer — skipping (non-critical)"
    fi
}

install_jcodemunch() {
    step "Installing jcodemunch-mcp (token-efficient code retrieval)"
    if command -v jcodemunch-mcp 2>/dev/null; then
        ok "jcodemunch-mcp already installed"
        return 0
    fi
    if pip install git+https://github.com/jgravelle/jcodemunch-mcp.git 2>/dev/null || \
       pip3 install git+https://github.com/jgravelle/jcodemunch-mcp.git 2>/dev/null; then
        ok "jcodemunch-mcp installed"
    else
        warn "jcodemunch-mcp install failed — skipping (non-critical)"
    fi
}

install_browser_use() {
    step "Installing browser-use (browser automation for AI agents)"
    if python3 -c "import browser_use" 2>/dev/null; then
        ok "browser-use Python package already installed"
        return 0
    fi
    if pip install browser-use 2>/dev/null || pip3 install browser-use 2>/dev/null; then
        ok "browser-use installed"
    else
        warn "browser-use install failed — skipping (non-critical)"
    fi
}

install_fastapi_mcp() {
    step "Installing fastapi-mcp (FastAPI → MCP tool exporter)"
    if python3 -c "import fastapi_mcp" 2>/dev/null; then
        ok "fastapi-mcp already installed"
        return 0
    fi
    if pip install fastapi-mcp 2>/dev/null || pip3 install fastapi-mcp 2>/dev/null; then
        ok "fastapi-mcp installed"
    else
        warn "fastapi-mcp install failed — skipping (non-critical)"
    fi
}

# ---------- main ----------
main() {
    print_banner

    OS="$(detect_os)"
    log "Detected platform: ${C_BOLD}${OS}${C_RESET}"

    if [[ "$OS" == "unknown" ]]; then
        die "Unsupported operating system. Hermes supports macOS, Linux, and WSL."
    fi

    case "$OS" in
        macos-*) install_homebrew ;;
    esac

    install_git
    install_python
    install_node
    install_python_deps
    install_npm_packages
    install_jcodemunch
    install_browser_use
    install_fastapi_mcp

step "Launching the Hermes setup wizard"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$script_dir"

    if [[ ! -f "$script_dir/wizard.py" ]]; then
        die "wizard.py not found in $script_dir"
    fi

    python3 "$script_dir/wizard.py" --installer-dir "$script_dir" --platform "$OS"
    local wizard_exit=$?

    if [[ $wizard_exit -eq 0 ]]; then
        install_understand_anything
        step "Installing coding agent"
        if [[ -f "$script_dir/components/coding-agent-setup.sh" ]]; then
            bash "$script_dir/components/coding-agent-setup.sh"
        fi
        step "Installing optional stack components"
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -f "$script_dir/components/stop-slop-setup.sh" ]]; then
            bash "$script_dir/components/stop-slop-setup.sh"
        fi
        if [[ -f "$script_dir/components/taste-skill-setup.sh" ]]; then
            bash "$script_dir/components/taste-skill-setup.sh"
        fi
        if [[ -f "$script_dir/components/x-mcp-setup.sh" ]]; then
            bash "$script_dir/components/x-mcp-setup.sh"
        fi
        if [[ -f "$script_dir/components/mcp-x-intelligence-setup.sh" ]]; then
            bash "$script_dir/components/mcp-x-intelligence-setup.sh"
        fi
        if [[ -f "$script_dir/components/browser-use-setup.sh" ]]; then
            bash "$script_dir/components/browser-use-setup.sh"
        fi
        if [[ -f "$script_dir/components/claude-context-mcp-setup.sh" ]]; then
            bash "$script_dir/components/claude-context-mcp-setup.sh"
        fi
        if [[ -f "$script_dir/components/markitdown-setup.sh" ]]; then
            bash "$script_dir/components/markitdown-setup.sh"
        fi
        if [[ -f "$script_dir/components/compound-engineering-setup.sh" ]]; then
            bash "$script_dir/components/compound-engineering-setup.sh"
        fi
        if [[ -f "$script_dir/components/graphify-setup.sh" ]]; then
            bash "$script_dir/components/graphify-setup.sh"
        fi
        if [[ -f "$script_dir/components/open-multi-agent-setup.sh" ]]; then
            bash "$script_dir/components/open-multi-agent-setup.sh"
        fi
        if [[ -f "$script_dir/components/fastapi-mcp-setup.sh" ]]; then
            bash "$script_dir/components/fastapi-mcp-setup.sh"
        fi
        if [[ -f "$script_dir/components/caliber-setup.sh" ]]; then
            bash "$script_dir/components/caliber-setup.sh"
        fi
        if [[ -f "$script_dir/components/headroom-setup.sh" ]]; then
            bash "$script_dir/components/headroom-setup.sh"
        fi
        if [[ -f "$script_dir/components/spec-kit-setup.sh" ]]; then
            bash "$script_dir/components/spec-kit-setup.sh"
        fi
        if [[ -f "$script_dir/components/gitingest-setup.sh" ]]; then
            bash "$script_dir/components/gitingest-setup.sh"
        fi
        if [[ -f "$script_dir/components/openspace-setup.sh" ]]; then
            bash "$script_dir/components/openspace-setup.sh"
        fi
        if [[ -f "$script_dir/components/last30days-setup.sh" ]]; then
            bash "$script_dir/components/last30days-setup.sh"
        fi
        if [[ -f "$script_dir/components/claude-hud-setup.sh" ]]; then
            bash "$script_dir/components/claude-hud-setup.sh"
        fi
        if [[ -f "$script_dir/components/open-notebook-setup.sh" ]]; then
            bash "$script_dir/components/open-notebook-setup.sh"
        fi
        if [[ -f "$script_dir/components/gemini-cli-setup.sh" ]]; then
            bash "$script_dir/components/gemini-cli-setup.sh"
        fi
        if [[ -f "$script_dir/components/contextgem-setup.sh" ]]; then
            bash "$script_dir/components/contextgem-setup.sh"
        fi
        if [[ -f "$script_dir/components/agent-skills-setup.sh" ]]; then
            bash "$script_dir/components/agent-skills-setup.sh"
        fi
        if [[ -f "$script_dir/components/webwright-setup.sh" ]]; then
            bash "$script_dir/components/webwright-setup.sh"
        fi
        if [[ -f "$script_dir/components/obsidian-vault-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/obsidian-vault-setup.sh"
        fi
        if [[ -f "$script_dir/components/codebase-memory-mcp-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/codebase-memory-mcp-setup.sh"
        fi
        if [[ -f "$script_dir/components/openmontage-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/openmontage-setup.sh"
        fi
        if [[ -f "$script_dir/components/skillspector-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/skillspector-setup.sh"
        fi
        if [[ -f "$script_dir/components/superpowers-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/superpowers-setup.sh"
        fi
        if [[ -f "$script_dir/components/omnigent-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/omnigent-setup.sh"
        fi
        if [[ -f "$script_dir/components/hyperextract-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/hyperextract-setup.sh"
        fi
        if [[ -f "$script_dir/components/paddleocr-mcp-setup.sh" ]]; then
            echo ""
            bash "$script_dir/components/paddleocr-mcp-setup.sh"
        fi
        step "Hermes Stack setup complete!"
        log "Run 'claude' in any project directory to start."
    else
        warn "Wizard exited with code $wizard_exit — skipping post-install steps."
    fi
}

main "$@"