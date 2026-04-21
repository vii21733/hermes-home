# Hermes Home ☤

Private backup and auto-restore configuration for [Hermes Agent](https://github.com/NousResearch/hermes-agent).

## Quick Setup on a New Machine

```bash
git clone https://github.com/vii21733/hermes-home.git
cd hermes-home
bash setup.sh
```

That's it! The setup script will:

1. Install system dependencies (Python 3.11+, Node.js 22+, git)
2. Clone and install Hermes Agent from GitHub
3. Restore all your config, data, sessions, and state
4. Start the gateway and keeper
5. Set up auto-sync to GitHub every 30 minutes
6. Add auto-start to your shell

## What's Backed Up

| File | Description |
|------|-------------|
| `.env` | API keys and bot tokens |
| `config.yaml` | Full Hermes configuration |
| `prefill.json` | Prefill messages |
| `SOUL.md` | Agent personality/soul |
| `auth.json` | Authentication data |
| `state.db` | Session state database |
| `sessions/` | Conversation history |
| `skills/` | Custom skills |
| `memories/` | Agent memories |
| `hooks/` | Custom hooks |
| `cron/` | Scheduled automations |
| `logs/` | Gateway and agent logs |

## Auto-Sync

Files are automatically committed and pushed to GitHub every 30 minutes via `sync-daemon.sh`. Only changed files are synced.

## Manual Sync

```bash
cd hermes-home
bash auto-sync.sh
```

## Useful Commands

```bash
hermes                  # Start interactive CLI
hermes gateway status   # Check gateway status
hermes gateway restart  # Restart gateway
tail -f logs/agent.log  # Watch logs
bash uninstall.sh       # Stop all processes
```

## Uninstall

```bash
bash uninstall.sh
```

Stops all processes but preserves your data. Add `rm -rf` flags to fully remove.
