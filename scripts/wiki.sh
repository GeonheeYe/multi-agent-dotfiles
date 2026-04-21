#!/usr/bin/env bash
# LONGMEMORY wiki 조회 스크립트
# 사용법:
#   wiki                -> 전체 프로젝트 목록
#   wiki <키워드>       -> 프로젝트 퍼지 매칭 후 context/overview/timeline 중 하나 출력
# 기본 동작:
#   1) 로컬 ~/LONGMEMORY 우선
#   2) 없으면 S20(YOUR_S20_HOST) fallback

set -euo pipefail

REAL_HOME="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6)"
if [ -z "$REAL_HOME" ]; then
  REAL_HOME="$HOME"
fi

LONGMEMORY_CANDIDATES=()
if [ -n "${LONGMEMORY_DIR:-}" ]; then
  LONGMEMORY_CANDIDATES+=("$LONGMEMORY_DIR")
fi
LONGMEMORY_CANDIDATES+=(
  "$REAL_HOME/LONGMEMORY"
  "$HOME/LONGMEMORY"
)

WIKI_INDEX_REMOTE="/data/data/com.termux/files/home/LONGMEMORY/wiki/index.md"
WIKI_BASE_REMOTE="/data/data/com.termux/files/home/LONGMEMORY/wiki/projects"
S20_HOST="${S20_HOST:-YOUR_S20_HOST}"
SSH_OPTS=(-o ConnectTimeout=5 -o BatchMode=yes)
CONTEXT_FILES=(context.md overview.md timeline.md tasks.md decisions.md summaries.md)

_parse_index() {
  grep -E '^- \[' "$1" | grep './projects/' | sed 's/^- \[//;s/\].*//'
}

_resolve_local_longmemory() {
  local candidate
  for candidate in "${LONGMEMORY_CANDIDATES[@]}"; do
    [ -n "$candidate" ] || continue
    if [ -f "$candidate/wiki/index.md" ] || [ -d "$candidate/wiki/projects" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

LOCAL_LONGMEMORY="$( _resolve_local_longmemory || true )"
WIKI_INDEX_LOCAL="${LOCAL_LONGMEMORY:+$LOCAL_LONGMEMORY/wiki/index.md}"
WIKI_BASE_LOCAL="${LOCAL_LONGMEMORY:+$LOCAL_LONGMEMORY/wiki/projects}"

_has_local_wiki() {
  [ -n "$LOCAL_LONGMEMORY" ] && { [ -f "$WIKI_INDEX_LOCAL" ] || [ -d "$WIKI_BASE_LOCAL" ]; }
}

_has_remote_wiki() {
  ssh "${SSH_OPTS[@]}" "$S20_HOST" "test -f '$WIKI_INDEX_REMOTE' || test -d '$WIKI_BASE_REMOTE'" >/dev/null 2>&1
}

_get_project_list_local() {
  if [ -f "$WIKI_INDEX_LOCAL" ]; then
    _parse_index "$WIKI_INDEX_LOCAL"
    return 0
  fi

  if [ -d "$WIKI_BASE_LOCAL" ]; then
    find "$WIKI_BASE_LOCAL" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
    return 0
  fi

  return 1
}

_get_project_list_remote() {
  local tmp
  tmp="$(mktemp)"
  if ssh "${SSH_OPTS[@]}" "$S20_HOST" "cat '$WIKI_INDEX_REMOTE'" >"$tmp" 2>/dev/null; then
    _parse_index "$tmp"
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"

  ssh "${SSH_OPTS[@]}" "$S20_HOST" "find '$WIKI_BASE_REMOTE' -mindepth 1 -maxdepth 1 -type d -exec basename {} \\; | sort" 2>/dev/null
}

_get_project_list() {
  if _has_local_wiki; then
    _get_project_list_local && return 0
  fi

  if _has_remote_wiki; then
    _get_project_list_remote && return 0
  fi

  printf '로컬 LONGMEMORY도 없고 S20에도 연결할 수 없습니다.\n' >&2
  printf '확인한 로컬 후보 경로: %s\n' "${LONGMEMORY_CANDIDATES[*]}" >&2
  return 1
}

_pick_context_file_local() {
  local proj="$1"
  local name
  for name in "${CONTEXT_FILES[@]}"; do
    if [ -f "$WIKI_BASE_LOCAL/$proj/$name" ]; then
      printf '%s\n' "$WIKI_BASE_LOCAL/$proj/$name"
      return 0
    fi
  done
  return 1
}

_fetch_context_local() {
  local proj="$1"
  local file
  file="$(_pick_context_file_local "$proj")" || return 1
  cat "$file"
}

_fetch_context_remote() {
  local proj="$1"
  local name
  for name in "${CONTEXT_FILES[@]}"; do
    if ssh "${SSH_OPTS[@]}" "$S20_HOST" "test -f '$WIKI_BASE_REMOTE/$proj/$name'" >/dev/null 2>&1; then
      ssh "${SSH_OPTS[@]}" "$S20_HOST" "cat '$WIKI_BASE_REMOTE/$proj/$name'"
      return 0
    fi
  done
  return 1
}

_fetch_context() {
  local proj="$1"
  if _has_local_wiki && _fetch_context_local "$proj"; then
    return 0
  fi
  if _has_remote_wiki && _fetch_context_remote "$proj"; then
    return 0
  fi
  return 1
}

if [ $# -eq 0 ]; then
  _get_project_list
  exit 0
fi

keyword="$1"
all_projects="$(_get_project_list 2>/dev/null || true)"

if [ -z "$all_projects" ]; then
  printf '프로젝트 목록을 가져올 수 없습니다. 로컬 LONGMEMORY 또는 S20 연결 상태를 확인해 주세요.\n' >&2
  exit 1
fi

matches="$(printf '%s\n' "$all_projects" | grep -i "$keyword" || true)"
match_count="$(printf '%s\n' "$matches" | grep -c '[^[:space:]]' || true)"

if [ "$match_count" -eq 0 ]; then
  printf '일치하는 프로젝트가 없습니다: %s\n\n사용 가능한 프로젝트:\n%s\n' \
    "$keyword" "$all_projects" >&2
  exit 1
elif [ "$match_count" -eq 1 ]; then
  matched="$(printf '%s' "$matches" | xargs)"
  _fetch_context "$matched" || {
    printf '읽을 수 있는 위키 파일이 없습니다: %s\n' "$matched" >&2
    exit 1
  }
else
  printf '여러 프로젝트가 매칭됩니다:\n%s\n\n정확한 이름을 지정해 주세요.\n' "$matches" >&2
  exit 1
fi
