# Hermes Stack — Troubleshooting

## "command not found: codegraph" after install

Your npm global bin directory may not be on `$PATH`. Find it:

```sh
npm list -g --depth=0 2>/dev/null
npm root -g
```

Then add the global bin to your shell config:

```sh
# Add to ~/.bashrc or ~/.zshrc
export PATH="$(npm root -g)/../bin:$PATH"
```

Or symlink directly:

```sh
sudo ln -s "$(npm root -g)/../bin/codegraph" /usr/local/bin/codegraph
```

## Claude Code returns 401 (authentication error)

Run in your terminal:

```sh
claude login
```

This opens a browser for OAuth. After completing it, non-interactive `claude -p` calls will work.

If you're on a headless server (no browser), use an API key instead:

```sh
export ANTHROPIC_API_KEY="sk-ant-..."
```

## "claude" command not found

Make sure `@anthropic-ai/claude-code` was installed globally:

```sh
npm install -g @anthropic-ai/claude-code
```

Then find the binary:

```sh
which claude || npx claude --version
```

## agentmemory MCP server fails

agentmemory requires a running backend. Start it manually:

```sh
npx @agentmemory/agentmemory
```

This starts the server on port 3111. Keep the terminal open or run it as a background service:

```sh
npx @agentmemory/agentmemory &
disown
```

The viewer is at `http://localhost:3113`.

## API key validation failed

- **OpenRouter:** Go to [openrouter.ai/keys](https://openrouter.ai/keys). Make sure the key is active and has credits.
- **Anthropic:** Go to [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys). API keys start with `sk-ant-`.
- Keys are stored in `~/.hermes/.env` with 0600 permissions. Verify they're set correctly.

## n8n connection refused

If you enabled n8n but don't have it running:

1. Start n8n locally: `n8n start`
2. Or use n8n cloud: replace `N8N_BASE_URL` with your cloud instance URL
3. Generate an API key in n8n: Settings → API → Create Key

n8n is optional. Set `enabled: false` in `config.yaml` if you're not using it.

## "Rich" or "yaml" import errors in wizard

The wizard needs Python libraries that weren't installed. Run:

```sh
python3 -m pip install --user rich pyyaml requests
```

## Config changes not taking effect

After editing `~/.hermes/config.yaml` or `~/.claude.json`:

1. Close all Claude Code sessions
2. Start a new one — configs are read at startup

For the Hermes agent itself, restart the gateway:

```sh
hermes gateway restart
```

## Permission denied running install.sh

Make the script executable:

```sh
chmod +x install.sh
./install.sh
```

## I want to reset everything and start over

```sh
# Backup existing configs
cp ~/.hermes/.env ~/.hermes/.env.bak
cp ~/.claude.json ~/.claude.json.bak

# Remove configs (wizard will recreate them)
rm -f ~/.hermes/.env
rm -f ~/.hermes/config.yaml
rm -f ~/.claude.json

# Re-run installer
./install.sh
```

## Still stuck?

Open an issue at [github.com/Sitting-sucks/hermes-stack](https://github.com/Sitting-sucks/hermes-stack/issues) or reach out via [ryansaisetup.com](https://ryansaisetup.com).
