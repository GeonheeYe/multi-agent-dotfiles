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

env -u WIKI_PATH -u LONGMEMORY_WIKI_PATH LONGMEMORY_DIR="$longmemory" python3 "$PROCESS" "$raw" >/dev/null

[ -f "$longmemory/wiki/index.md" ] || fail "process script should create wiki index under LONGMEMORY_DIR"
[ -f "$longmemory/wiki/projects/aegis-ap/timeline.md" ] || fail "process script should create project timeline under LONGMEMORY_DIR"
[ -f "$longmemory/wiki/raw/aegis-ap/2026-05-10_01-00-00_abc12345.md" ] || fail "process script should move classified raw under LONGMEMORY_DIR/wiki"

project_raw="$longmemory/wiki/projects/aegis-ap/2026-05-10_01-00-01_deadbeef.md"
cat >"$project_raw" <<'EOF'
project: aegis-ap

## 사용자
aegis-ap 관련 진행 상황을 기록한다.
EOF

env -u WIKI_PATH -u LONGMEMORY_WIKI_PATH LONGMEMORY_DIR="$longmemory" python3 "$UPDATE" >/dev/null

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
env -u WIKI_PATH -u LONGMEMORY_WIKI_PATH HOME="$temp_home" LONGMEMORY_DIR="$longmemory" LONGMEMORY_REMOTE_DIR="$longmemory" FAKE_SSH_LOG="$ssh_log" PATH="$fakebin:$PATH" \
  bash "$ROOT/scripts/wiki.sh" aegis >"$wiki_output"

grep -Fq "aegis-ap Context" "$wiki_output" || fail "wiki should read local LONGMEMORY when remote dir is the local LONGMEMORY"
grep -Fq "ssh " "$ssh_log" || fail "wiki should try remote first before falling back to local LONGMEMORY"

real_home="$temp_home/real-home"
personal_home="$temp_home/personal-home"
mkdir -p "$real_home/LONGMEMORY/wiki/projects/real-project" "$personal_home"
cat >"$real_home/LONGMEMORY/wiki/index.md" <<'EOF'
- [real-project](./projects/real-project/overview.md)
EOF
cat >"$real_home/LONGMEMORY/wiki/projects/real-project/overview.md" <<'EOF'
# Real Project Context
EOF

direct_loader_output="$temp_home/direct-loader-output.json"
env -u WIKI_PATH -u LONGMEMORY_WIKI_PATH -u LONGMEMORY_DIR -u LONGMEMORY_PATH HOME="$personal_home" REAL_HOME="$real_home" LONGMEMORY_REMOTE_FIRST=0 \
  python3 "$ROOT/scripts/longmemory_loader.py" load real-project >"$direct_loader_output"

grep -Fq "$real_home/LONGMEMORY/wiki" "$direct_loader_output" \
  || fail "loader should read REAL_HOME LONGMEMORY when HOME is a personal sandbox"
grep -Fq "Real Project Context" "$direct_loader_output" \
  || fail "loader should load project files from REAL_HOME LONGMEMORY"

remote_ssh_log="$temp_home/remote-ssh.log"
cat >"$fakebin/ssh" <<'EOF'
#!/usr/bin/env bash
printf 'ssh %s\n' "$*" >>"$FAKE_SSH_LOG"
printf '{"ok": true, "source": "local", "wiki": "/home/geonhee/wiki", "projects": ["aegis-ap"], "topics": []}\n'
EOF
chmod +x "$fakebin/ssh"

mkdir -p "$personal_home/LONGMEMORY/wiki/projects/local-project"
cat >"$personal_home/LONGMEMORY/wiki/index.md" <<'EOF'
- [local-project](./projects/local-project/overview.md)
EOF

remote_loader_output="$temp_home/remote-loader-output.json"
env -u WIKI_PATH -u LONGMEMORY_WIKI_PATH -u LONGMEMORY_DIR -u LONGMEMORY_PATH -u LONGMEMORY_REMOTE_HOST -u LONGMEMORY_SSH_HOST \
  HOME="$personal_home" REAL_HOME="$temp_home/missing-real-home" FAKE_SSH_LOG="$remote_ssh_log" PATH="$fakebin:$PATH" \
  python3 "$ROOT/scripts/longmemory_loader.py" list >"$remote_loader_output"

grep -Fq "geonhee-ubuntu" "$remote_ssh_log" \
  || fail "loader should default remote fallback to geonhee-ubuntu"
grep -Fq "LONGMEMORY_WIKI_PATH='/home/geonhee/wiki'" "$remote_ssh_log" \
  || fail "loader should read canonical geonhee-ubuntu LONGMEMORY wiki by default"
grep -Fq "LONGMEMORY_REMOTE_FIRST=0" "$remote_ssh_log" \
  || fail "remote loader invocation should disable nested remote-first lookup"
grep -Fq '"source": "remote"' "$remote_loader_output" \
  || fail "loader output should identify SSH-loaded wiki as remote"
grep -Fq '"remote_host": "geonhee-ubuntu"' "$remote_loader_output" \
  || fail "loader output should identify the default remote host"

echo "PASS"
