#!/usr/bin/env bash

run_dotfiles_sync() {
  local repo_dir="${1:-${DOTFILES_DIR:-$HOME/dotfiles}}"

  if ! command -v git >/dev/null 2>&1; then
    return 0
  fi

  if [ ! -d "$repo_dir/.git" ]; then
    return 0
  fi

  local status_output
  if ! status_output="$(git -C "$repo_dir" status --porcelain 2>/dev/null)"; then
    echo "[dotfiles] git status 확인 실패, 자동 동기화 건너뜀" >&2
    return 0
  fi

  if [ -n "$status_output" ]; then
    echo "[dotfiles] 로컬 변경 감지, 자동 동기화 건너뜀" >&2
    return 0
  fi

  if git -C "$repo_dir" pull --ff-only >/dev/null 2>&1; then
    echo "[dotfiles] 최신 상태 확인 완료" >&2
  else
    echo "[dotfiles] fast-forward 불가, 자동 동기화 건너뜀" >&2
  fi

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  run_dotfiles_sync "$@"
fi
