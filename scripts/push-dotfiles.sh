#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

[ -d "$DOTFILES/.git" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0

# Auto-commit any changes (including untracked files)
STATUS_OUTPUT="$(git -C "$DOTFILES" status --porcelain --untracked-files=normal 2>/dev/null || true)"
if [ -n "$STATUS_OUTPUT" ]; then
  HOSTNAME_SHORT="$(hostname -s 2>/dev/null || echo unknown)"
  git -C "$DOTFILES" add -A
  git -C "$DOTFILES" commit -m "chore: auto-sync [$HOSTNAME_SHORT]" --quiet || true
fi

# Pull --rebase if remote has new commits
git -C "$DOTFILES" fetch --quiet 2>/dev/null || true
REMOTE_FETCH="$(git -C "$DOTFILES" rev-parse '@{u}' 2>/dev/null || true)"
LOCAL_HEAD="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null || true)"
MERGE_BASE="$(git -C "$DOTFILES" merge-base HEAD '@{u}' 2>/dev/null || true)"

if [ -n "$REMOTE_FETCH" ] && [ "$MERGE_BASE" != "$REMOTE_FETCH" ]; then
  if ! git -C "$DOTFILES" pull --rebase --quiet 2>/dev/null; then
    printf '[dotfiles] WARNING: pull --rebase conflict during push. Manual resolution needed: %s\n' "$DOTFILES" >&2
    exit 0
  fi
fi

# Push if local is ahead of origin
LOCAL="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null || true)"
REMOTE="$(git -C "$DOTFILES" rev-parse '@{u}' 2>/dev/null || true)"

if [ -n "$LOCAL" ] && [ "$LOCAL" != "$REMOTE" ]; then
  if ! git -C "$DOTFILES" push --quiet 2>/dev/null; then
    printf '[dotfiles] WARNING: push failed. Manual check needed: %s\n' "$DOTFILES" >&2
  fi
fi
