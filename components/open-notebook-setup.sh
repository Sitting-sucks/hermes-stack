#!/usr/bin/env bash
# Hermes Stack — Open Notebook Integration Setup
# Open-source NotebookLM alternative — podcast generation, multi-model AI research
# https://github.com/lfnovo/open-notebook
#
# Self-hosted, privacy-first. Turn docs into podcasts, summaries, research briefs.
# Perfect for Sitting Sucks content pipeline.

set -euo pipefail

C_RESET='\033[0m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_CYAN='\033[36m'
C_BOLD='\033[1m'

log()   { printf "${C_CYAN}[hermes]${C_RESET} %s\n" "$*"; }
ok()    { printf "${C_GREEN}[ ok ]${C_RESET} %s\n" "$*"; }
warn()  { printf "${C_YELLOW}[warn]${C_RESET} %s\n" "$*"; }

install_docker() {
    if command -v docker &>/dev/null; then
        ok "Docker already installed"
        return 0
    fi

    log "Installing Docker..."

    # Detect OS
    local os_type
    os_type="$(uname -s 2>/dev/null || echo unknown)"

    case "$os_type" in
        Darwin)
            if command -v brew &>/dev/null; then
                brew install --cask docker
                warn "Docker Desktop installed. Open it manually to complete setup."
            else
                warn "Please install Docker Desktop from https://docs.docker.com/desktop/install/mac/"
                return 1
            fi
            ;;
        Linux)
            if command -v apt-get &>/dev/null; then
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl
                sudo install -m 0755 -d /etc/apt/keyrings
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                sudo usermod -aG docker "$USER"
                warn "Added $USER to docker group — may need to log out and back in"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                sudo systemctl enable --now docker
                sudo usermod -aG docker "$USER"
            else
                warn "Unsupported Linux distro. Install Docker manually: https://docs.docker.com/engine/install/"
                return 1
            fi
            ;;
        *)
            warn "Unknown OS. Install Docker manually."
            return 1
            ;;
    esac

    ok "Docker installed"
}

main() {
    log "Setting up Open Notebook (open-source NotebookLM alternative)..."

    # Ensure Docker is available
    install_docker || {
        warn "Docker installation required for Open Notebook — skipping for now"
        warn "Install Docker manually, then run: docker compose up -d in the open-notebook directory"
        return 1
    }

    # Ensure Docker daemon is running
    if ! docker info &>/dev/null; then
        warn "Docker daemon not running. Starting it..."
        if command -v systemctl &>/dev/null; then
            sudo systemctl start docker 2>/dev/null || true
        fi
        if ! docker info &>/dev/null; then
            warn "Docker daemon not available. Start Docker Desktop or run: sudo systemctl start docker"
            return 1
        fi
    fi

    local notebook_dir="$HOME/.hermes/open-notebook"

    # Create directory
    mkdir -p "$notebook_dir"

    # Download docker-compose.yml if not present
    if [[ -f "$notebook_dir/docker-compose.yml" ]]; then
        ok "Open Notebook docker-compose.yml already exists"
    else
        log "Downloading docker-compose.yml..."
        curl -fsSL -o "$notebook_dir/docker-compose.yml" \
            https://raw.githubusercontent.com/lfnovo/open-notebook/main/docker-compose.yml

        # Generate a random encryption key
        local enc_key
        enc_key="$(head -c 32 /dev/urandom | base64 2>/dev/null || echo "change-me-to-a-secret-string")"
        sed -i "s/change-me-to-a-secret-string/$enc_key/g" "$notebook_dir/docker-compose.yml"

        ok "docker-compose.yml ready with generated encryption key"
    fi

    # Create data directories
    mkdir -p "$notebook_dir/surreal_data"
    mkdir -p "$notebook_dir/notebook_data"

    # Start the services
    log "Starting Open Notebook services..."
    cd "$notebook_dir"
    if docker compose up -d 2>/dev/null; then
        ok "Open Notebook services started"
    else
        warn "docker compose up failed — check Docker is running and try: cd $notebook_dir && docker compose up -d"
    fi

    # Create a launch script
    local launch_script="$HOME/.hermes/bin/open-notebook"
    mkdir -p "$HOME/.hermes/bin"
    cat > "$launch_script" << 'SCRIPT'
#!/usr/bin/env bash
cd "$HOME/.hermes/open-notebook" || { echo "Open Notebook not found at $HOME/.hermes/open-notebook"; exit 1; }
docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null
echo "→ Open Notebook: http://localhost:8502"
echo "→ Configure your AI provider at Settings > API Keys"
SCRIPT
    chmod +x "$launch_script"

    ok "Open Notebook setup complete!"
    log "Open it at: http://localhost:8502"
    log "Run '$HOME/.hermes/bin/open-notebook' to start services anytime"
    log "Add your AI provider key in Settings → API Keys"
    log "Import PDFs, videos, web pages → generate podcasts with 1-4 speakers"
    log "Learn more: https://github.com/lfnovo/open-notebook"
}

main "$@"