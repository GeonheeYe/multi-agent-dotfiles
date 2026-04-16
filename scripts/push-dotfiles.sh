#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

[ -d "$DOTFILES/.git" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0

# untracked 포함 작업 트리 변경사항이 있으면 auto-commit
STATUS_OUTPUT="$(git -C "$DOTFILES" status --porcelain --untracked-files=normal 2>/dev/null || true)"
if [ -n "$STATUS_OUTPUT" ]; then
  HOSTNAME_SHORT="$(hostname -s 2>/dev/null || echo unknown)"
  git -C "$DOTFILES" add -A
  git -C "$DOTFILES" commit -m "chore: auto-sync [$HOSTNAME_SHORT]" --quiet || true
fi

# 원격에 새 커밋이 있으면 push 전에 pull --rebase
git -C "$DOTFILES" fetch --quiet 2>/dev/null || true
REMOTE_FETCH="$(git -C "$DOTFILES" rev-parse '@{u}' 2>/dev/null || true)"
LOCAL_HEAD="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null || true)"
MERGE_BASE="$(git -C "$DOTFILES" merge-base HEAD '@{u}' 2>/dev/null || true)"

if [ -n "$REMOTE_FETCH" ] && [ "$MERGE_BASE" != "$REMOTE_FETCH" ]; then
  if ! git -C "$DOTFILES" pull --rebase --quiet 2>/dev/null; then
    printf '[dotfiles] ⚠️  push-dotfiles: pull --rebase 충돌 발생. 수동으로 해결 필요: %s\n' "$DOTFILES" >&2
    exit 0
  fi
fi

# origin보다 앞선 커밋 있으면 push
LOCAL="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null || true)"
REMOTE="$(git -C "$DOTFILES" rev-parse '@{u}' 2>/dev/null || true)"

if [ -n "$LOCAL" ] && [ "$LOCAL" != "$REMOTE" ]; then
  if ! git -C "$DOTFILES" push --quiet 2>/dev/null; then
    printf '[dotfiles] ⚠️  push-dotfiles: push 실패. 수동으로 확인 필요: %s\n' "$DOTFILES" >&2
  fi
fi
