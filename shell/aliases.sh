# dotfiles/shell/aliases.sh
# bash/zsh에서 공통으로 source 가능한 최소 래퍼 함수들

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# OS 감지 (mac / wsl / linux / unknown)
_detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)
      grep -qi microsoft /proc/version 2>/dev/null && echo "wsl" || echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

_require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

_dotfiles_pull() {
  if [ -x "$DOTFILES/scripts/sync-dotfiles.sh" ]; then
    "$DOTFILES/scripts/sync-dotfiles.sh" >/dev/null 2>&1 || true
  fi
}

_dotfiles_push() {
  if [ -x "$DOTFILES/scripts/push-dotfiles.sh" ]; then
    "$DOTFILES/scripts/push-dotfiles.sh" >/dev/null 2>&1 || true
  fi
}

_s20_openclaw() {
  "$DOTFILES/scripts/s20-openclaw.sh" "$@"
}

# 기존 interactive alias가 함수 정의 토큰을 깨뜨리지 않도록 정리
unalias cc ccd ccr cdd cu 2>/dev/null || true

# Claude Code
cc() {
  _dotfiles_pull
  if _require_cmd claude; then
    claude "$@"
    _dotfiles_push
  else
    printf 'claude command not found\n' >&2
    return 127
  fi
}

ccd() {
  _dotfiles_pull
  if _require_cmd claude; then
    claude --dangerously-skip-permissions "$@"
    _dotfiles_push
  else
    printf 'claude command not found\n' >&2
    return 127
  fi
}

ccr() {
  _dotfiles_pull
  if _require_cmd claude; then
    claude --resume --dangerously-skip-permissions "$@"
    _dotfiles_push
  else
    printf 'claude command not found\n' >&2
    return 127
  fi
}

# Codex
cdd() {
  _dotfiles_pull
  if _require_cmd codex; then
    codex --dangerously-bypass-approvals-and-sandbox "$@"
    _dotfiles_push
  else
    printf 'codex command not found\n' >&2
    return 127
  fi
}

# Cursor CLI
cu() {
  _dotfiles_pull
  if _require_cmd cursor; then
    cursor "$@"
    _dotfiles_push
  else
    printf 'cursor command not found\n' >&2
    return 127
  fi
}

# S20 / OpenClaw
s20oc() {
  _s20_openclaw "$@"
}

s20tg() {
  _s20_openclaw telegram-send "$@"
}

s20gw() {
  _s20_openclaw gateway-up
}
