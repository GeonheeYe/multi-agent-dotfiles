#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

[ -d "$DOTFILES/.git" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0

export GIT_TERMINAL_PROMPT=0

_with_timeout() {
  local seconds="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
    return
  fi

  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
    return
  fi

  if command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV or die $!' "$seconds" "$@"
    return
  fi

  "$@"
}

_git() {
  _with_timeout 10 git "$@" 2>/dev/null || true
}

# untracked 포함 작업 트리 변경사항이 있으면 auto-commit
STATUS_OUTPUT="$(_git -C "$DOTFILES" status --porcelain --untracked-files=normal)"
if [ -n "$STATUS_OUTPUT" ]; then
  HOSTNAME_SHORT="$(hostname -s 2>/dev/null || echo unknown)"
  _git -C "$DOTFILES" add -A
  _git -C "$DOTFILES" commit -m "chore: auto-sync [$HOSTNAME_SHORT]" --quiet
fi

# 원격에 새 커밋이 있으면 push 전에 pull --rebase
_git -C "$DOTFILES" fetch --quiet
REMOTE_FETCH="$(_git -C "$DOTFILES" rev-parse '@{u}')"
LOCAL_HEAD="$(_git -C "$DOTFILES" rev-parse HEAD)"
MERGE_BASE="$(_git -C "$DOTFILES" merge-base HEAD '@{u}')"

if [ -n "$REMOTE_FETCH" ] && [ "$MERGE_BASE" != "$REMOTE_FETCH" ]; then
  if ! _with_timeout 15 git -C "$DOTFILES" pull --rebase --quiet 2>/dev/null; then
    printf '[dotfiles] ⚠️  push-dotfiles: pull --rebase 충돌 발생. 수동으로 해결 필요: %s\n' "$DOTFILES" >&2
    exit 0
  fi
fi

# origin보다 앞선 커밋 있으면 push
LOCAL="$(_git -C "$DOTFILES" rev-parse HEAD)"
REMOTE="$(_git -C "$DOTFILES" rev-parse '@{u}')"

if [ -n "$LOCAL" ] && [ "$LOCAL" != "$REMOTE" ]; then
  if ! _with_timeout 15 git -C "$DOTFILES" push --quiet 2>/dev/null; then
    printf '[dotfiles] ⚠️  push-dotfiles: push 실패. 수동으로 확인 필요: %s\n' "$DOTFILES" >&2
  fi
fi
