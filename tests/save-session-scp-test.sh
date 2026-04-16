#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/save-session-scp.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"
  if ! grep -Fq "$needle" "$file"; then
    fail "$message"
  fi
}

[ -f "$SCRIPT" ] || fail "missing save script: $SCRIPT"

temp_home="$(mktemp -d)"
trap 'rm -rf "$temp_home"' EXIT
mkdir -p "$temp_home/codex-sessions" "$temp_home/.codex/sessions/2026/04/14"

transcript="$temp_home/.codex/sessions/2026/04/14/rollout-2026-04-14T10-00-00-abc12345.jsonl"
cat >"$transcript" <<'EOF'
{"timestamp":"2026-04-14T01:00:00.000Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"사용자 질문"}]}}
{"timestamp":"2026-04-14T01:00:01.000Z","type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"어시스턴트 답변"}],"phase":"final_answer"}}
EOF

printf '{"session_id":"abc12345","transcript_path":"%s","source":"codex"}\n' "$transcript" \
  | HOME="$temp_home" SAVE_SESSION_DIR="$temp_home/codex-sessions" bash "$SCRIPT" >/dev/null 2>&1

saved_file="$(find "$temp_home/codex-sessions" -maxdepth 1 -type f -name '*.md' | head -n 1)"
[ -n "$saved_file" ] || fail "save script should create a markdown transcript"
assert_file_contains "$saved_file" "## 사용자" "saved transcript should include user section"
assert_file_contains "$saved_file" "사용자 질문" "saved transcript should include user text"
assert_file_contains "$saved_file" "## Assistant" "saved transcript should include assistant section"
assert_file_contains "$saved_file" "어시스턴트 답변" "saved transcript should include assistant text"

echo "PASS"
