#!/usr/bin/env bash
# LONGMEMORY wiki 조회 래퍼
# 사용법:
#   wiki                -> 전체 프로젝트/토픽 목록
#   wiki <키워드>       -> longmemory_loader.py로 프로젝트/토픽 컨텍스트 JSON 출력
#   wiki --text <키워드> -> 사람이 읽기 쉬운 markdown으로 출력
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$(cd "$SCRIPT_DIR/.." && pwd)}"
LOADER="${LONGMEMORY_LOADER:-$DOTFILES/scripts/longmemory_loader.py}"

if command -v getent >/dev/null 2>&1; then
  REAL_HOME="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6 || true)"
else
  REAL_HOME="$HOME"
fi
if [ -n "${REAL_HOME:-}" ] && [ -z "${LONGMEMORY_DIR:-}" ]; then
  export LONGMEMORY_DIR="$REAL_HOME/LONGMEMORY"
fi

if [ ! -f "$LOADER" ]; then
  printf 'longmemory_loader.py를 찾을 수 없습니다: %s\n' "$LOADER" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  exec python3 "$LOADER" list
fi

TEXT_MODE=0
if [ "${1:-}" = "--text" ]; then
  TEXT_MODE=1
  shift
fi

keyword="${1:-}"
if [ -z "$keyword" ]; then
  exec python3 "$LOADER" list
fi

if [ "$TEXT_MODE" != "1" ]; then
  exec python3 "$LOADER" load "$keyword"
fi

python3 - "$LOADER" "$keyword" <<'PY'
import json
import subprocess
import sys

loader, keyword = sys.argv[1], sys.argv[2]
proc = subprocess.run([sys.executable, loader, 'load', keyword], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if proc.returncode != 0 and not proc.stdout.strip():
    sys.stderr.write(proc.stderr)
    raise SystemExit(proc.returncode)
try:
    data = json.loads(proc.stdout)
except Exception:
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)
    raise SystemExit(proc.returncode)

if not data.get('ok'):
    print(json.dumps(data, ensure_ascii=False, indent=2))
    raise SystemExit(proc.returncode)

print(f"# {data.get('slug')} ({data.get('kind')})")
print(f"\n- source: {data.get('source')}\n- base: {data.get('base')}\n")
for name, text in data.get('files', {}).items():
    print(f"\n## {name}\n")
    print(text.rstrip())
for name, text in data.get('recent_sessions', {}).items():
    print(f"\n## recent/{name}\n")
    print(text.rstrip())
PY
