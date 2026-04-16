#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

[ -d "$DOTFILES/.git" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0

# uncommitted 변경사항 있으면 auto-commit (pull --rebase 충돌 방지)
if ! git -C "$DOTFILES" diff --quiet || ! git -C "$DOTFILES" diff --cached --quiet; then
  HOSTNAME_SHORT="$(hostname -s 2>/dev/null || echo unknown)"
  git -C "$DOTFILES" add -A
  git -C "$DOTFILES" commit -m "chore: auto-sync [$HOSTNAME_SHORT] before pull" --quiet || true
fi

before="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null || true)"
if ! git -C "$DOTFILES" pull --rebase --quiet 2>/dev/null; then
  git -C "$DOTFILES" rebase --abort 2>/dev/null || true
  printf '[dotfiles] ⚠️  pull --rebase 충돌. 수동으로 해결 필요: %s\n' "$DOTFILES" >&2
fi
after="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null || true)"

if [ -n "$before" ] && [ "$before" != "$after" ] && [ -x "$DOTFILES/setup.sh" ]; then
  "$DOTFILES/setup.sh" >/dev/null 2>&1 || true
fi
