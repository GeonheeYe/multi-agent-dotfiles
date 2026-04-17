#!/usr/bin/env bash
set -euo pipefail

S20_HOST="${S20_HOST:-YOUR_S20_HOST}"
S20_NODE="${S20_NODE:-\$HOME/.openclaw-android/node/bin/node}"
S20_OPENCLAW_ENTRY="${S20_OPENCLAW_ENTRY:-/data/data/com.termux/files/usr/bin/openclaw}"

_usage() {
  cat <<'EOF'
Usage:
  s20-openclaw.sh <openclaw args...>
  s20-openclaw.sh gateway-up
  s20-openclaw.sh telegram-send <chat_id> <message...>

Examples:
  s20-openclaw.sh channels list
  s20-openclaw.sh gateway-up
  s20-openclaw.sh telegram-send YOUR_TELEGRAM_CHAT_ID "hello from s20"
EOF
}

_remote_openclaw() {
  local ssh_target="$1"
  shift
  ssh -tt "$ssh_target" "bash -lc 'export PATH=\"\$HOME/.openclaw-android/node/bin:\$PATH\"; \"\$HOME/.openclaw-android/node/bin/node\" \"$S20_OPENCLAW_ENTRY\" $*'"
}

case "${1:-}" in
  ""|-h|--help)
    _usage
    ;;
  gateway-up)
    ssh -tt "$S20_HOST" "bash -lc 'export PATH=\"\$HOME/.openclaw-android/node/bin:\$PATH\"; pkill -f openclaw || true; sleep 2; nohup \"\$HOME/.openclaw-android/node/bin/node\" \"$S20_OPENCLAW_ENTRY\" gateway --force > ~/openclaw-gw-manual.log 2>&1 < /dev/null & echo \$! > ~/.openclaw-gateway.pid; sleep 10; echo PID=\$(cat ~/.openclaw-gateway.pid); tail -80 ~/openclaw-gw-manual.log'"
    ;;
  telegram-send)
    shift
    if [ "$#" -lt 2 ]; then
      printf 'telegram-send requires <chat_id> <message...>\n' >&2
      exit 2
    fi
    chat_id="$1"
    shift
    _remote_openclaw "$S20_HOST" "message send --channel telegram --target $(printf '%q' "$chat_id") --message $(printf '%q' "$*") --json"
    ;;
  *)
    args=()
    for arg in "$@"; do
      args+=("$(printf '%q' "$arg")")
    done
    _remote_openclaw "$S20_HOST" "${args[*]}"
    ;;
esac
