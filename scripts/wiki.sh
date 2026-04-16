#!/usr/bin/env bash
# LONGMEMORY wiki 조회 - Cursor/Claude 스킬에서 직접 호출 가능한 독립 스크립트
# 사용법: wiki [키워드]
#   인수 없음  → 전체 프로젝트 목록
#   인수 있음  → 키워드 퍼지 매칭 후 context.md 출력

WIKI_INDEX_REMOTE="/data/data/com.termux/files/home/LONGMEMORY/wiki/index.md"
WIKI_BASE_REMOTE="/data/data/com.termux/files/home/LONGMEMORY/wiki/projects"
WIKI_BASE_LOCAL="/data/data/com.termux/files/home/LONGMEMORY/wiki/projects"
S20_HOST="YOUR_S20_HOST"

# S20(Termux) 위에서 직접 실행 중이면 로컬 경로 사용
_on_s20=false
[ -d "$WIKI_BASE_LOCAL" ] && _on_s20=true

# index.md 파싱: "- [project-name](./projects/..." 형식
_parse_index() {
  grep -E '^\- \[' "$1" | grep '\./projects/' | sed 's/^- \[//;s/\].*//'
}

_get_project_list() {
  if $_on_s20; then
    _parse_index "/data/data/com.termux/files/home/LONGMEMORY/wiki/index.md"
  else
    local tmp; tmp="$(mktemp)"
    if scp -q -o ConnectTimeout=5 "${S20_HOST}:${WIKI_INDEX_REMOTE}" "$tmp" 2>/dev/null; then
      _parse_index "$tmp"
      rm -f "$tmp"
    else
      rm -f "$tmp"
      printf '(S20 연결 실패)\n' >&2
      return 1
    fi
  fi
}

_fetch_context() {
  local proj="$1"
  if $_on_s20; then
    cat "${WIKI_BASE_LOCAL}/${proj}/context.md" 2>/dev/null || return 1
  else
    local tmp; tmp="$(mktemp)"
    if scp -q -o ConnectTimeout=5 \
        "${S20_HOST}:${WIKI_BASE_REMOTE}/${proj}/context.md" "$tmp" 2>/dev/null; then
      cat "$tmp"; rm -f "$tmp"; return 0
    fi
    rm -f "$tmp"; return 1
  fi
}

# ──────────────────────────────────────────
if [ $# -eq 0 ]; then
  _get_project_list
  exit 0
fi

keyword="$1"
all_projects="$(_get_project_list 2>/dev/null)"

if [ -z "$all_projects" ]; then
  printf 'S20에 연결하거나 프로젝트 목록을 가져올 수 없습니다.\n' >&2
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
    printf 'context.md를 가져올 수 없습니다: %s\n' "$matched" >&2; exit 1
  }
else
  printf '여러 프로젝트가 매칭됩니다:\n%s\n\n정확한 이름을 지정해 주세요.\n' "$matches" >&2
  exit 1
fi
