#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
if command -v getent >/dev/null 2>&1; then
  REAL_HOME="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6 || true)"
else
  REAL_HOME="$HOME"
fi
if [ -n "$REAL_HOME" ] && [ -z "${LONGMEMORY_DIR:-}" ]; then
  export LONGMEMORY_DIR="$REAL_HOME/LONGMEMORY"
fi
exec "$DOTFILES/scripts/wiki.sh" "$@"
