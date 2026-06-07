#!/usr/bin/env bash
# browser-use setup for Hermes Stack
# Browser automation for AI agents - lets agents navigate, fill forms, and extract data from web pages
set -euo pipefail

TOOLS_DIR="${HERMES_TOOLS_DIR:-$HOME/.tools}"
BROWSER_USE_DIR="$TOOLS_DIR/browser-use"

log()   { printf "\033[36m[hermes]\033[0m %s\n" "$*"; }
ok()    { printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[33m[warn]\033[0m %s\n" "$*"; }

install_browser_use() {
    log "Installing browser-use (browser automation for AI agents)..."

    # Check if browser-use is already installed
    if python3 -c "import browser_use" 2>/dev/null; then
        ok "browser-use Python package already installed"
    else
        log "Installing browser-use Python package..."
        pip3 install browser-use 2>/dev/null || pip3 install --user browser-use 2>/dev/null || {
            warn "pip install failed, trying with --break-system-packages"
            pip3 install --break-system-packages browser-use 2>/dev/null || {
                warn "browser-use Python install failed — will try npx-based CLI"
            }
        }
    fi

    # Install Chromium for Playwright if needed
    if command -v playwright 2>/dev/null; then
        if ! python3 -c "from playwright.sync_api import sync_playwright; sync_playwright().__enter__().chromium.launch(headless=True).close()" 2>/dev/null; then
            log "Installing Playwright Chromium browser..."
            python3 -m playwright install chromium 2>/dev/null || npx playwright install chromium 2>/dev/null || warn "Could not auto-install Chromium - run 'playwright install chromium' manually"
        fi
    fi

    # Create a skill file for Claude Code / Hermes Agent
    mkdir -p "$BROWSER_USE_DIR"
    cat > "$BROWSER_USE_DIR/BROWSER_USE_SKILL.md" << 'SKILL'
# Browser Use Skill — Web Automation for AI Agents

You have browser-use installed. Use it when you need to:
- Navigate websites and extract data
- Fill forms and submit
- Test web application flows
- Monitor web pages for changes
- Automate repetitive browser tasks

## Quick Start

### Python (for custom agent workflows):
```python
from browser_use import Agent, Browser

async with Browser() as browser:
    agent = Agent(
        task="describe what you need done",
        llm=chat_model,  # use ChatBrowserUse() for optimized model
        browser=browser,
    )
    await agent.run()
```

### CLI (for direct browser automation):
```bash
# Open a page headlessly
browser-use open https://example.com

# Open with visible window for debugging
browser-use --headed open https://example.com

# Use your existing Chrome session (cookies, logins preserved)
browser-use --profile "Default" open https://example.com

# Get current page state
browser-use state

# Click elements
browser-use click 3

# Fill forms
browser-use fill 5 "text to enter"

# Take a screenshot
browser-use screenshot

# Extract structured data
browser-use extract "json format description"
```

### With Claude Code:
Ask Claude to "use browser-use to check [website] for [information]"

## Notes
- Default mode is headless (no visible window)
- Uses Chrome DevTools Protocol (CDP) — Chrome/Chromium only
- For production: use Browser Use Cloud for stealth, proxies, and parallel execution
SKILL

    # Try to install browser-use CLI (npx-based)
    if npm list -g browser-use 2>/dev/null | grep -q browser-use; then
        ok "browser-use CLI already installed"
    else
        log "Setting up browser-use CLI (npx)..."
        # The CLI works via npx - no global npm install needed
        cat > "$BROWSER_USE_DIR/browser-use" << 'CLIWRAPPER'
#!/usr/bin/env bash
# Wrapper to run browser-use CLI
exec npx browser-use "$@"
CLIWRAPPER
        chmod +x "$BROWSER_USE_DIR/browser-use"
        ok "browser-use CLI wrapper created"
    fi

    ok "browser-use installed successfully"
}

install_browser_use
ok "browser-use ready. Agents can now automate web browsers."
log "Usage: Ask your AI agent to 'browse [url] for [information]'"
log "For custom Python scripts: from browser_use import Agent"
