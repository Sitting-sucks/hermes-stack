#!/usr/bin/env bash
# openmontage-setup.sh — OpenMontage: agentic video production system
# World's first open-source, agentic video production system.
# 12 pipelines, 52 tools, 500+ agent skills. Turns your AI coding assistant
# into a full video production studio. Works with any AI coding assistant.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENMONTAGE_REPO="https://github.com/calesthio/OpenMontage.git"
OPENMONTAGE_DIR="${HOME}/.tools/openmontage"

log()   { printf "[hermes] %s\n" "$*"; }
ok()    { printf "[ ok ] %s\n" "$*"; }
warn()  { printf "[warn] %s\n" "$*"; }

install_openmontage() {
    log "Installing OpenMontage..."

    if [[ -d "${OPENMONTAGE_DIR}" ]]; then
        log "OpenMontage already cloned, updating..."
        cd "${OPENMONTAGE_DIR}" && git pull --ff-only 2>/dev/null && ok "OpenMontage updated" || warn "update failed"
        return 0
    fi

    mkdir -p "$(dirname "${OPENMONTAGE_DIR}")"
    git clone --depth 1 "${OPENMONTAGE_REPO}" "${OPENMONTAGE_DIR}" 2>/dev/null

    if [[ ! -d "${OPENMONTAGE_DIR}" ]]; then
        warn "Failed to clone OpenMontage repository"
        return 1
    fi

    ok "OpenMontage cloned to ${OPENMONTAGE_DIR}"
}

install_dependencies() {
    log "Installing OpenMontage dependencies..."

    cd "${OPENMONTAGE_DIR}"

    # Python dependencies
    if [[ -f requirements.txt ]]; then
        if command -v pip3 &>/dev/null; then
            pip3 install -r requirements.txt --break-system-packages 2>/dev/null && \
                ok "Python dependencies installed" || \
                warn "pip install failed (try: pip3 install -r requirements.txt)"
        elif command -v pip &>/dev/null; then
            pip install -r requirements.txt --break-system-packages 2>/dev/null && \
                ok "Python dependencies installed" || \
                warn "pip install failed"
        else
            warn "pip not found — install Python dependencies manually"
        fi
    fi

    # Remotion composer (Node.js)
    if [[ -d remotion-composer ]]; then
        cd remotion-composer
        if command -v npm &>/dev/null; then
            npm install 2>/dev/null && ok "Remotion composer dependencies installed" || \
                warn "npm install failed in remotion-composer"
        fi
        cd "${OPENMONTAGE_DIR}"
    fi

    # Create .env from example if not exists
    if [[ -f .env.example ]] && [[ ! -f .env ]]; then
        cp .env.example .env
        ok "Created .env from .env.example — add your API keys"
    fi
}

configure_for_hermes() {
    log "Configuring OpenMontage for Hermes Agent..."

    HERMES_SKILLS_DIR="${HOME}/.hermes/skills"

    # Create symlink to OpenMontage skills if they exist
    if [[ -d "${OPENMONTAGE_DIR}/skills" ]]; then
        mkdir -p "${HERMES_SKILLS_DIR}"
        if [[ ! -L "${HERMES_SKILLS_DIR}/openmontage" ]]; then
            ln -sfn "${OPENMONTAGE_DIR}/skills" "${HERMES_SKILLS_DIR}/openmontage" 2>/dev/null && \
                ok "OpenMontage skills linked to Hermes" || \
                warn "Could not link skills"
        else
            ok "OpenMontage skills already linked"
        fi
    fi
}

main() {
    log "Setting up OpenMontage (agentic video production system)..."
    install_openmontage
    install_dependencies
    configure_for_hermes
    log ""
    log "OpenMontage is ready!"
    log "Location: ${OPENMONTAGE_DIR}"
    log "Tell your agent: 'Make a video about [topic] using OpenMontage'"
    log "Supports 12 pipelines: explainers, talking heads, screen demos, trailers, and more."
    log "Hack it: cd ${OPENMONTAGE_DIR} && cat AGENT_GUIDE.md"
}

main