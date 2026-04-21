#!/usr/bin/env bash
# 로컬 LONGMEMORY wiki 조회 스크립트
# 사용법:
#   wiki                -> 전체 프로젝트 목록
#   wiki <키워드>       -> 프로젝트 퍼지 매칭 후 context/overview/timeline 중 하나 출력

set -euo pipefail

LONGMEMORY_DIR="${LONGMEMORY_DIR:-$HOME/LONGMEMORY}"
WIKI_INDEX="${LONGMEMORY_DIR}/wiki/index.md"
WIKI_BASE="${LONGMEMORY_DIR}/wiki/projects"

_parse_index() {
  grep -E '^- \[' "$1" | grep './projects/' | sed 's/^- \[//;s/\].*//'
}

_get_project_list() {
  if [ -f "$WIKI_INDEX" ]; then
    _parse_index "$WIKI_INDEX"
    return 0
  fi

  if [ -d "$WIKI_BASE" ]; then
    find "$WIKI_BASE" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
    return 0
  fi

  printf '로컬 LONGMEMORY wiki를 찾을 수 없습니다: %s\n' "$WIKI_BASE" >&2
  return 1
}

_pick_context_file() {
  local proj="$1"
  local candidates=(
    "$WIKI_BASE/$proj/context.md"
    "$WIKI_BASE/$proj/overview.md"
    "$WIKI_BASE/$proj/timeline.md"
    "$WIKI_BASE/$proj/tasks.md"
    "$WIKI_BASE/$proj/decisions.md"
    "$WIKI_BASE/$proj/summaries.md"
  )
  local file
  for file in "${candidates[@]}"; do
    if [ -f "$file" ]; then
      printf '%s\n' "$file"
      return 0
    fi
  done
  return 1
}

_fetch_context() {
  local proj="$1"
  local file
  file="$(_pick_context_file "$proj")" || return 1
  cat "$file"
}

if [ $# -eq 0 ]; then
  _get_project_list
  exit 0
fi

keyword="$1"
all_projects="$(_get_project_list 2>/dev/null || true)"

if [ -z "$all_projects" ]; then
  printf '로컬 LONGMEMORY 프로젝트 목록을 가져올 수 없습니다.\n' >&2
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
