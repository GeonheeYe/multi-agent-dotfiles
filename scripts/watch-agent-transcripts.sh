#!/usr/bin/env bash
set -euo pipefail

# Cursor agent-transcripts watcher (always-on)
#
# 목표:
# - Cursor가 만드는 ~/.cursor/projects/**/agent-transcripts/**/*.jsonl 변화를 감지
# - 변화가 생기면 dotfiles의 save-session-scp.sh로 전달해서 s20으로 전송
#
# 동작:
# - AGENT_TRANSCRIPTS_DIR 가 지정되어 있으면 해당 폴더만 감시
# - 아니면 ~/.cursor/projects 전체를 재귀 감시해서 "프로젝트가 바뀌어도" 자동으로 따라감

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SAVE_SCRIPT="$DOTFILES/scripts/save-session-scp.sh"
STATE_DIR="${WATCH_AGENT_STATE_DIR:-$HOME/cursor-sessions/.watch-agent-state}"
mkdir -p "$STATE_DIR"

if [ ! -x "$SAVE_SCRIPT" ]; then
  printf '[watch-agent] save-session-scp.sh 실행 파일을 찾을 수 없습니다: %s\n' "$SAVE_SCRIPT" >&2
  exit 1
fi

if ! command -v fswatch >/dev/null 2>&1; then
  printf '[watch-agent] fswatch 명령을 찾을 수 없습니다. 설치 후 다시 시도하세요.\n' >&2
  printf '  macOS (brew): brew install fswatch\n' >&2
  exit 1
fi

WATCH_ROOT="${AGENT_TRANSCRIPTS_DIR:-$HOME/.cursor/projects}"
if [ ! -d "$WATCH_ROOT" ]; then
  printf '[watch-agent] 감시할 디렉터리가 없습니다: %s\n' "$WATCH_ROOT" >&2
  exit 1
fi

send_session() {
  local path="$1"
  [ -f "$path" ] || return 0
  case "$path" in
    *.jsonl) ;;
    *) return 0 ;;
  esac

  # Cursor projects 전체를 감시할 때는 "agent-transcripts" 하위만 처리
  if [ -z "${AGENT_TRANSCRIPTS_DIR:-}" ]; then
    case "$path" in
      */agent-transcripts/*.jsonl|*/agent-transcripts/*/*.jsonl|*/agent-transcripts/*/*/*.jsonl) ;;
      *) return 0 ;;
    esac
  fi

  local sid
  sid="$(basename "$path" .jsonl)"

  # Debounce per session file:
  # - Cursor agent-transcripts jsonl is appended many times during a session.
  # - We only want to send once after writes settle.
  local lock="$STATE_DIR/${sid}.lock"
  if [ -e "$lock" ]; then
    return 0
  fi
  : >"$lock"

  (
    # Wait for writes to settle (inactivity window)
    local before after
    before="$(stat -f '%m %z' "$path" 2>/dev/null || echo '')"
    sleep "${WATCH_AGENT_DEBOUNCE_SECONDS:-5}"
    after="$(stat -f '%m %z' "$path" 2>/dev/null || echo '')"

    if [ -z "$before" ] || [ -z "$after" ] || [ "$before" != "$after" ]; then
      rm -f "$lock"
      exit 0
    fi

    python3 - "$sid" "$path" <<'PYEOF' \
      | SAVE_SESSION_DIR="${SAVE_SESSION_DIR:-$HOME/cursor-sessions}" "$SAVE_SCRIPT" >/dev/null 2>&1 || true
import json, sys
session_id, transcript_path = sys.argv[1], sys.argv[2]
print(json.dumps({
    "session_id": session_id,
    "transcript_path": transcript_path,
    "source": "cursor",
}, ensure_ascii=False))
PYEOF

    rm -f "$lock"
  ) >/dev/null 2>&1 &

  return 0
}

printf '[watch-agent] 감시 시작: %s\n' "$WATCH_ROOT" >&2

# -r: recursive
# -0: NUL delimiter
fswatch -r -0 "$WATCH_ROOT" | while IFS= read -r -d '' changed; do
  send_session "$changed"
done

