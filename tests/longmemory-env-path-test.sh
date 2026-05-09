#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROCESS="$ROOT/scripts/process_longmemory_raw.py"
UPDATE="$ROOT/scripts/update_longmemory_wiki.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$PROCESS" ] || fail "missing process script: $PROCESS"
[ -f "$UPDATE" ] || fail "missing update script: $UPDATE"

temp_home="$(mktemp -d)"
trap 'rm -rf "$temp_home"' EXIT

longmemory="$temp_home/LONGMEMORY"
raw="$temp_home/2026-05-10_01-00-00_abc12345.md"

cat >"$raw" <<'EOF'
# Claude 세션 대화

## 사용자
aegis-ap 프로젝트의 다음 작업을 정리해줘.
다음 할 일: wing 기능 테스트를 추가해야 한다.

## Assistant
정리했습니다.
EOF

LONGMEMORY_DIR="$longmemory" python3 "$PROCESS" "$raw" >/dev/null

[ -f "$longmemory/wiki/index.md" ] || fail "process script should create wiki index under LONGMEMORY_DIR"
[ -f "$longmemory/wiki/projects/aegis-ap/timeline.md" ] || fail "process script should create project timeline under LONGMEMORY_DIR"
[ -f "$longmemory/raw/aegis-ap/2026-05-10_01-00-00_abc12345.md" ] || fail "process script should move classified raw under LONGMEMORY_DIR"

project_raw="$longmemory/wiki/projects/aegis-ap/2026-05-10_01-00-01_deadbeef.md"
cat >"$project_raw" <<'EOF'
project: aegis-ap

## 사용자
aegis-ap 관련 진행 상황을 기록한다.
EOF

LONGMEMORY_DIR="$longmemory" python3 "$UPDATE" >/dev/null

[ -f "$longmemory/wiki/topics/classification-report.md" ] || fail "update script should write classification report under LONGMEMORY_DIR"
grep -Fq "2026-05-10_01-00-01_deadbeef.md" "$longmemory/wiki/projects/aegis-ap/.processed_raw.txt" \
  || fail "update script should mark project raw as processed under LONGMEMORY_DIR"

fakebin="$temp_home/fakebin"
ssh_log="$temp_home/ssh.log"
mkdir -p "$fakebin"
cat >"$fakebin/ssh" <<'EOF'
#!/usr/bin/env bash
printf 'ssh %s\n' "$*" >>"$FAKE_SSH_LOG"
exit 1
EOF
chmod +x "$fakebin/ssh"

wiki_output="$temp_home/wiki-output.txt"
HOME="$temp_home" LONGMEMORY_DIR="$longmemory" LONGMEMORY_REMOTE_DIR="$longmemory" FAKE_SSH_LOG="$ssh_log" PATH="$fakebin:$PATH" \
  bash "$ROOT/scripts/wiki.sh" aegis >"$wiki_output"

grep -Fq "aegis-ap Context" "$wiki_output" || fail "wiki should read local LONGMEMORY when remote dir is the local LONGMEMORY"
[ ! -s "$ssh_log" ] || fail "wiki should not SSH when LONGMEMORY_REMOTE_DIR is the local LONGMEMORY"

echo "PASS"
