<p align="center">
  <img src="assets/icon.png" width="160" alt="Cleanup Agent icon">
</p>

<h1 align="center">Cleanup Agent</h1>

<p align="center">
  A safety-first macOS cleanup bot for Telegram. It audits disk usage, explains what is safe to remove, and cleans only what you approve. Everything runs locally.
</p>

---

## Features

- **Weekly disk report** via `launchd` with macOS and Telegram notifications.
- **One-tap safe cleanup** for caches, logs and temporary files.
- **Review and choose**: large files, installers, Steam games, Cap recordings, Coast data.
- **Quarantine**: non-safe deletions are restorable for 7 days.
- **Protected data is read-only**: iCloud, Photos, WhatsApp backups and chat archives.
- **Running-app awareness**: skips files an app is using; can close an app and retry on demand.
- **Revalidates every path** before deletion: containment, symlinks, excludes and type.
- **Time Machine snapshot cleanup** (optional helper) so freed space shows up immediately.
- **CLI and Telegram bot** share the same engine and safety rules.
- **No telemetry, no cloud, no AI service.**

## Safety model

1. **Allowlist-first**: only known cache/temp locations are classified as safe.
2. **User excludes**: `~/.config/cleanup-agent/excludes` is respected at scan time and re-checked before deletion.
3. **Quarantine**: medium-risk items move to a local quarantine instead of being deleted.
4. **Revalidation**: right before acting, the agent checks that the path still exists, is inside your home, is not a symlink, is not excluded, and that the app is not running (unless you explicitly force it).
5. **Protected category is read-only**; it can never be deleted from the bot.
6. **No root** except an optional, scoped `sudoers` rule for the snapshot helper.
7. **Human approval** for every destructive action.

## Architecture

```
┌──────────────────────────────┐
│        Telegram bot          │  commands, buttons, approvals
│  bin/cleanup-telegram-bot    │
└──────────────┬───────────────┘
               │ calls
┌──────────────▼───────────────┐
│     Cleanup engine (CLI)     │  scan, classify, explain, apply
│       bin/cleanup-agent      │
└──────┬───────────┬───────────┘
       │           │
  quarantine   Time Machine
   (7 days)    snapshot helper
```

Scheduled jobs:

- `com.cleanupagent.weekly` — Monday 09:00 report + notification.
- `com.cleanupagent.telegram-bot` — keeps the bot alive.

## Requirements

- macOS 13 or newer (tested on macOS 26, Apple Silicon).
- Python 3.9+ (the system Python is enough).
- A Telegram bot token from [@BotFather](https://t.me/BotFather).
- Optional: Full Disk Access for the Python binary if you want the report to see protected folders (Music, Photos, etc.).

## Install

```bash
git clone https://github.com/Moljesdev99/cleanup-agent.git
cd cleanup-agent
./install.sh
```

The installer copies the scripts to `~/.local/bin`, renders the `launchd` jobs with your home path, creates the config files, and optionally installs the snapshot helper.

### Telegram setup

1. Create a bot with **@BotFather** and copy the token.
2. Send `/start` to your bot.
3. Get your `chat_id`:

```bash
curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['result'][-1]['message']['chat']['id'])"
```

4. Store the token and chat id in the macOS Keychain:

```bash
security add-generic-password -U -a bot_token -s cleanup-agent-telegram -w
security add-generic-password -U -a chat_id  -s cleanup-agent-telegram -w
```

5. Send `/report` to the bot.

## Commands

| Command | What it does |
|---|---|
| `/report` | Disk overview, top consumers, cleanup summary, buttons |
| `/limpiar` | Choose a group: 🟢 safe, 🟡 review, 🔴 protected |
| `/seguro` | Delete all safe items (with confirmation) |
| `/cuarentena` | View, restore or purge quarantined items |
| `/vaciar` | Permanently delete everything in quarantine |
| `/excluir <path>` | Add a path that must never be touched |
| `/exclusiones` | List excluded paths |
| `/status` | Show free disk space |
| `/cancelar` | Cancel the current selection |

## CLI

```bash
cleanup-agent --report
cleanup-agent --apply-safe
cleanup-agent --choose
cleanup-agent --pick S1,S4-S6
cleanup-agent --quarantine-list
cleanup-agent --restore <id>
cleanup-agent --purge-quarantine
cleanup-agent --add-exclude ~/SomeFolder
cleanup-agent --excludes
```

Add `--dry-run` to preview without changes.

## Configuration

- `~/.config/cleanup-agent/excludes` — paths that are never touched (one per line, supports `~` and `*`).
- `~/.config/cleanup-agent/config.json` — notification settings. Prefer the Keychain for secrets.
- `~/Library/Logs/cleanup-agent/` — logs and the latest report (`report-latest.md`).
- `~/Library/Application Support/cleanup-agent/quarantine/` — quarantined items (auto-purged after 7 days).

## How the scan works

- **Safe**: `~/Library/Caches`, `~/.cache`, npm/uv/Homebrew caches, app caches, updater caches, logs, Trash, web app caches, Steam/Coast caches.
- **Review**: large files, installers, old app versions, Steam games, Cap recordings, Coast recordings and index.
- **Protected**: iCloud Drive, Photos, WhatsApp iCloud backup, chat archives and anything you exclude.

Each item is shown with its size, risk, exact path, what will be deleted, what will not, and what you lose.

## What it never touches

`~/Documents`, `~/Desktop`, `~/Pictures`, `~/Movies`, `~/Music`, iCloud Drive, Mail, Messages, Keychains, `~/.ssh`, browser profiles, WhatsApp backups, chat archives and Docker volumes. You can add more exclusions at any time.

## FAQ

**Does it delete anything without asking?**
No. Every destructive action requires confirmation in Telegram (or an explicit CLI flag).

**Does it use an LLM or send data anywhere?**
No. The agent is deterministic and runs entirely on your Mac. There is no telemetry.

**Why didn't the free space change?**
A file may still be open by an app, or a local Time Machine snapshot may be retaining the blocks. The bot can close the app and force the deletion, and the optional helper purges local snapshots.

**Can I use only the CLI?**
Yes. The engine is independent; the Telegram bot is just a front-end.

## Disclaimer

This project is not affiliated with Apple, Telegram, or any app mentioned. App names and paths are used only to describe where data is stored. Use it at your own risk and review every action.

## License

MIT. See [LICENSE](LICENSE).

---

## Resumen en español

Un bot de Telegram con un motor determinista para auditar y liberar espacio en macOS. Escanea, clasifica (🟢 seguro / 🟡 revisar / 🔴 protegido), explica qué se borra, mueve lo delicado a cuarentena 7 días y solo ejecuta lo que tú apruebas. Sin IA, sin nube y sin telemetría.
