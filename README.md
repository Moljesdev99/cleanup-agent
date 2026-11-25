# Cleanup Agent

**A safety-first macOS cleanup bot for Telegram — built by [Moljesdev99](https://github.com/Moljesdev99).**

Cleanup Agent audits your Mac's storage, explains what is using space, and helps you reclaim it from Telegram. It is a deterministic automation tool: it follows explicit rules and never deletes anything without your approval.

It is **not an AI agent** and does not use an LLM. It is a bot with a rule-based cleanup engine.

---

## What it is

Cleanup Agent is made of four parts:

| Part | What it is |
|---|---|
| **Engine** (`bin/cleanup-agent`) | A Python CLI that scans, classifies, explains and applies cleanup |
| **Telegram bot** (`bin/cleanup-telegram-bot`) | The chat interface for reports, selection and approvals |
| **`launchd` jobs** | macOS services for the weekly report and keeping the bot alive |
| **Snapshot helper** (optional) | A tiny privileged script to purge local Time Machine snapshots |

Everything runs locally. No cloud, no telemetry, no AI service.

## What it does

- Scans caches, logs, temporary files, installers, large files, Steam games, Cap recordings and Coast data.
- Classifies every item into one of three groups:
  - 🟢 **Safe** — regenerable caches, logs and temp files.
  - 🟡 **Review** — games, recordings, large files and other data you should decide on.
  - 🔴 **Protected** — iCloud, Photos, WhatsApp backups, chat archives; read-only.
- Shows disk total/used/free, the biggest space consumers, and per-item details: size, exact path, risk, what will be deleted, what will be kept and what you lose.
- Sends a **weekly report** (Monday 09:00) with macOS and Telegram notifications.
- Deletes safe items, moves review items to a **7-day quarantine**, and keeps protected data read-only.
- Revalidates every path immediately before acting: containment, symlinks, excludes, file type and running apps.
- Can close an app, delete its files and reopen it (for example Coast) when you explicitly choose to.
- Purges local Time Machine snapshots when they are retaining freed space.

## What it does not do

- It does **not** delete anything without confirmation.
- It does **not** use AI, an LLM or the cloud.
- It does **not** “optimize” macOS or change system settings.
- It does **not** delete iCloud Drive, Photos, WhatsApp backups, chats, Mail, Messages, Keychains or browser profiles.
- It does **not** run as root (the only privileged component is the optional snapshot helper).
- It does **not** work on Windows or Linux.

## How to free space

1. **See what is using space.** Send `/report` (or wait for the Monday report). You get disk usage, top consumers and a cleanup summary.
2. **Clean the safe stuff.** Tap **🧹 Borrar todo lo seguro** to delete caches, logs and temp files. These are permanent, but they regenerate on their own.
3. **Review the bigger items.** Tap **🟡 Revisar** to see large files, installers, Steam games, Cap recordings and Coast data. Tap an item to see exactly what it is and what you lose.
4. **Choose what happens.** For 🟡 items you can choose:
   - **Quarantine** — recoverable for 7 days. It does **not** free space until you purge it.
   - **Permanent** — frees space immediately.
5. **Confirm.** The agent revalidates the path and acts. It will skip excluded paths, symlinks, protected items and files an app is using.
6. **Free quarantine space now (optional).** If you sent items to quarantine, run `/vaciar` to delete them permanently, or wait 7 days for the automatic purge.
7. **If the free space did not move**, a file is probably still open or a Time Machine snapshot is holding the blocks. The bot can close the app and retry, and the snapshot helper purges local snapshots.
8. **Protect what matters.** Use `/excluir ~/SomeFolder` for anything you never want touched.

### Example flow

```text
/report
  → 🟢 Seguro: 1.2 GB
  → 🟡 Revisar: 8.4 GB
  → 🔴 Protegido: 12.0 GB

Tap "🧹 Borrar todo lo seguro" → confirm → ~1.2 GB freed
Tap "🟡 Revisar" → select a Steam game → Permanent → confirm → game removed
Tap "🟡 Revisar" → select Coast videos → Quarantine → confirm → /vaciar → space freed
```

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
- Optional: **Full Disk Access** for the Python binary if you want the report to see protected folders such as Music and Photos.

## Installation

```bash
git clone https://github.com/Moljesdev99/cleanup-agent.git
cd cleanup-agent
./install.sh
```

The installer:

- copies the scripts to `~/.local/bin`;
- renders the `launchd` jobs with your home path and Python path;
- creates `~/.config/cleanup-agent/`;
- loads the weekly report and the Telegram bot;
- optionally installs the snapshot helper (with a scoped `sudoers` rule).

### Telegram setup

1. Create a bot with **@BotFather** and copy the token.
2. Send `/start` to your bot.
3. Get your `chat_id`:

```bash
curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['result'][-1]['message']['chat']['id'])"
```

4. Store the token and chat id in the macOS Keychain (not in the repo):

```bash
security add-generic-password -U -a bot_token -s cleanup-agent-telegram -w
security add-generic-password -U -a chat_id  -s cleanup-agent-telegram -w
```

5. Send `/report` to the bot.

## Usage

### Telegram commands

| Command | What it does |
|---|---|
| `/report` | Disk overview, top consumers, cleanup summary and buttons |
| `/limpiar` | Choose a group: 🟢 safe, 🟡 review, 🔴 protected |
| `/seguro` | Delete all safe items (with confirmation) |
| `/cuarentena` | View, restore or purge quarantined items |
| `/vaciar` | Permanently delete everything in quarantine |
| `/excluir <path>` | Add a path that must never be touched |
| `/exclusiones` | List excluded paths |
| `/status` | Show free disk space |
| `/cancelar` | Cancel the current selection |

### CLI

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

| What | Where |
|---|---|
| Excluded paths (never touched) | `~/.config/cleanup-agent/excludes` |
| Notifications | `~/.config/cleanup-agent/config.json` |
| Telegram secrets | macOS Keychain (`cleanup-agent-telegram`) |
| Logs and latest report | `~/Library/Logs/cleanup-agent/` |
| Quarantine | `~/Library/Application Support/cleanup-agent/quarantine/` |
| Weekly schedule | `~/Library/LaunchAgents/com.cleanupagent.weekly.plist` |

### Excludes

One path or glob per line:

```text
~/Documents
~/Desktop
~/.ssh
~/Library/Mobile Documents
~/Projects/do-not-touch-*
```

Excludes are applied when scanning and re-checked immediately before any deletion.

### Weekly schedule

The report runs **Monday at 09:00** by default. To change it, edit `StartCalendarInterval` in `~/Library/LaunchAgents/com.cleanupagent.weekly.plist` and reload it:

```bash
launchctl bootout gui/$(id -u)/com.cleanupagent.weekly
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cleanupagent.weekly.plist
```

### Full Disk Access

If the report does not see Music, Photos or other protected folders, grant Full Disk Access to the Python binary used by `launchd`:

1. Open **System Settings → Privacy & Security → Full Disk Access**.
2. Add `/usr/bin/python3` (or the Python path shown in the plist).
3. Enable it and restart the bot.

### Time Machine snapshot helper (optional)

Deleting a file does not always free space immediately if a local Time Machine snapshot retains the blocks. The helper purges those snapshots.

During `install.sh` you can install it with `sudo`. It creates:

- `/usr/local/sbin/cleanup-thin-snapshots`
- `/etc/sudoers.d/cleanup-agent` with a rule scoped to that single command

Without the helper, cleanup still works; the space may just take longer to appear.

## Safety model

1. **Allowlist-first** — only known cache/temp locations are classified as safe.
2. **User excludes** — respected at scan time and re-checked before deletion.
3. **Quarantine** — medium-risk items are moved, not deleted.
4. **Revalidation** — before acting, the agent checks that the path still exists, is inside your home, is not a symlink, is not excluded and that its app is not running (unless you explicitly force it).
5. **Protected category is read-only** — it can never be deleted from the bot.
6. **No root** — except the optional, scoped snapshot helper.
7. **Human approval** — every destructive action requires confirmation.

## Languages and technologies

- **Python 3.9+** — engine and Telegram bot, using only the standard library (`os`, `json`, `subprocess`, `shutil`, `urllib`, `html`, `glob`, `fnmatch`, `hashlib`, `datetime`, `argparse`, `re`, `time`).
- **Bash** — installer and optional helper.
- **XML property lists (`launchd`)** — scheduled jobs.
- **Telegram Bot API** — long polling and inline keyboards over HTTPS.
- **macOS Keychain** (`security`) — token and chat id storage.
- **macOS tools** — `du`, `df`, `find`, `ps`, `lsof`, `pgrep`, `tmutil`, `osascript`, `plutil`, `launchctl`.

No external Python packages. No pip dependencies.

## FAQ

**Does it delete anything without asking?**
No. Every destructive action requires confirmation in Telegram (or an explicit CLI flag).

**Does it use AI or send data anywhere?**
No. It is deterministic and runs entirely on your Mac. There is no telemetry.

**What is the difference between quarantine and permanent?**
Quarantine is recoverable for 7 days but does not free space until you purge it. Permanent frees space immediately.

**Why did the free space not change?**
A file may still be open by an app, or a local Time Machine snapshot may be retaining the blocks. The bot can close the app and retry; the optional helper purges local snapshots.

**Can I use only the CLI?**
Yes. The engine is independent; the Telegram bot is just a front-end.

## Author

Developed by **[Moljesdev99](https://github.com/Moljesdev99)**.

## Disclaimer

This project is not affiliated with Apple, Telegram, or any app mentioned. App names and paths are used only to describe where data is stored. Use it at your own risk and review every action.

## License

MIT. See [LICENSE](LICENSE).

---

## Resumen en español

Cleanup Agent es un bot de Telegram con un motor determinista para auditar y liberar espacio en macOS. Escanea, clasifica (🟢 seguro / 🟡 revisar / 🔴 protegido), explica qué se borra, mueve lo delicado a cuarentena 7 días y solo ejecuta lo que tú apruebas. No usa IA, no manda datos a la nube y no borra nada sin confirmación. Desarrollado por Moljesdev99.
