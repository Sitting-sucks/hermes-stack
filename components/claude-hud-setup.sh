#!/usr/bin/env bash
# claude-hud setup for Hermes Stack
# Real-time heads-up display for Claude Code — context health, tool activity, agent tracking
set -euo pipefail

TOOLS_DIR="${HERMES_TOOLS_DIR:-$HOME/.tools}"
CLAUDE_HUD_DIR="$HOME/.claude/plugins/claude-hud"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_claude_hud() {
    log "Installing Claude HUD (real-time Claude Code dashboard)..."

    # Check if already configured
    if grep -q "claude-hud" "$HOME/.claude/settings.json" 2>/dev/null; then
        ok "Claude HUD already configured in Claude Code settings.json"
        return 0
    fi

    # Clone and build the plugin
    local tmp_dir="/tmp/claude-hud-$$"
    if git clone --depth=1 https://github.com/jarrodwatts/claude-hud.git "$tmp_dir" 2>/dev/null; then
        cd "$tmp_dir"
        if npm ci >/dev/null 2>&1 && npm run build >/dev/null 2>&1; then
            # Move to permanent location
            mkdir -p "$CLAUDE_HUD_DIR"
            cp -r "$tmp_dir"/* "$CLAUDE_HUD_DIR/"
            rm -rf "$tmp_dir"

            # Add statusLine to Claude Code settings
            local settings_file="$HOME/.claude/settings.json"
            if [[ -f "$settings_file" ]]; then
                # Remove trailing whitespace/brace
                sed -i 's/[[:space:]]*$//' "$settings_file"
                # Insert statusLine before closing brace
                sed -i '$d' "$settings_file"
                echo ',' >> "$settings_file"
                echo '  "statusLine": {' >> "$settings_file"
                echo '    "type": "command",' >> "$settings_file"
                echo '    "command": "node '"$CLAUDE_HUD_DIR"'/dist/index.js"' >> "$settings_file"
                echo '  }' >> "$settings_file"
                echo '}' >> "$settings_file"
                ok "Claude HUD installed and configured"
            else
                warn "settings.json not found — Claude HUD files installed but not activated"
                warn "Add this to ~/.claude/settings.json manually:"
                warn '  "statusLine": { "type": "command", "command": "node '"$CLAUDE_HUD_DIR"'/dist/index.js" }'
            fi
        else
            warn "Claude HUD build failed — skipping (non-critical)"
            rm -rf "$tmp_dir"
            return 1
        fi
    else
        warn "Could not download Claude HUD — skipping (non-critical)"
        return 1
    fi
}

install_claude_hud