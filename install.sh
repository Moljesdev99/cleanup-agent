#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONF_DIR="$HOME/.config/cleanup-agent"
AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/cleanup-agent"

PYTHON="$(command -v python3 || true)"
if [ -z "$PYTHON" ]; then
  echo "python3 not found. Install the Xcode Command Line Tools: xcode-select --install"
  exit 1
fi

echo "Installing Cleanup Agent..."
mkdir -p "$BIN_DIR" "$CONF_DIR" "$AGENTS_DIR" "$LOG_DIR"

install -m 755 "$REPO_DIR/bin/cleanup-agent" "$BIN_DIR/cleanup-agent"
install -m 755 "$REPO_DIR/bin/cleanup-telegram-bot" "$BIN_DIR/cleanup-telegram-bot"

if [ ! -f "$CONF_DIR/config.json" ]; then
  cp "$REPO_DIR/config/config.example.json" "$CONF_DIR/config.json"
  chmod 600 "$CONF_DIR/config.json"
fi
if [ ! -f "$CONF_DIR/excludes" ]; then
  cp "$REPO_DIR/config/excludes.example" "$CONF_DIR/excludes"
  chmod 600 "$CONF_DIR/excludes"
fi

for label in com.cleanupagent.weekly com.cleanupagent.telegram-bot; do
  sed -e "s|__HOME__|$HOME|g" -e "s|__PYTHON__|$PYTHON|g" \
    "$REPO_DIR/launchd/$label.plist.template" > "$AGENTS_DIR/$label.plist"
  plutil -lint "$AGENTS_DIR/$label.plist" >/dev/null
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$AGENTS_DIR/$label.plist" || true
done

echo
echo "Installed."
echo
echo "Next steps:"
echo "1) Create a Telegram bot with @BotFather, then store the token and chat id in Keychain:"
echo "   security add-generic-password -U -a bot_token  -s cleanup-agent-telegram -w"
echo "   security add-generic-password -U -a chat_id   -s cleanup-agent-telegram -w"
echo "2) Send /report to your bot."
echo
echo "Optional: install the snapshot helper (needs sudo) so freed space is released instantly."

if [ -t 0 ]; then
  read -r -p "Install snapshot helper now? [y/N] " ans
  case "$ans" in
    y|Y|yes|YES)
      sudo install -o root -g wheel -m 755 \
        "$REPO_DIR/scripts/cleanup-thin-snapshots" /usr/local/sbin/cleanup-thin-snapshots
      echo "$(id -un) ALL=(root) NOPASSWD: /usr/local/sbin/cleanup-thin-snapshots" \
        | sudo tee /etc/sudoers.d/cleanup-agent >/dev/null
      sudo chmod 440 /etc/sudoers.d/cleanup-agent
      sudo visudo -cf /etc/sudoers.d/cleanup-agent
      echo "Snapshot helper installed."
      ;;
  esac
fi
