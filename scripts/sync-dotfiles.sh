#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

[ -d "$DOTFILES/.git" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0

# 로컬 변경사항이 있으면 자동 commit하지 않고 동기화를 건너뛴다.
if [ -n "$(git -C "$DOTFILES" status --porcelain --untracked-files=normal 2>/dev/null)" ]; then
  printf '[dotfiles] 로컬 변경 감지, 자동 pull 건너뜀: %s\n' "$DOTFILES" >&2
  exit 0
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
