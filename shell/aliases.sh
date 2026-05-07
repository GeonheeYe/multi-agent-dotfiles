# dotfiles/shell/aliases.sh
# bash/zsh에서 공통으로 source 가능한 최소 래퍼 함수들

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
DOTFILES_HOME="${DOTFILES_HOME:-$HOME}"
CODEX_WORK_HOME="${CODEX_WORK_HOME:-$DOTFILES_HOME}"
CODEX_PERSONAL_HOME="${CODEX_PERSONAL_HOME:-$DOTFILES_HOME/.codex-personal-home}"

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

_dotfiles_push() {
  if [ -x "$DOTFILES/scripts/push-dotfiles.sh" ]; then
    "$DOTFILES/scripts/push-dotfiles.sh" >/dev/null 2>&1 || true
  fi
}

_s20_openclaw() {
  "$DOTFILES/scripts/s20-openclaw.sh" "$@"
}

_find_real_codex_bin() {
  if [ -n "${REAL_CODEX_BIN:-}" ] && [ -x "$REAL_CODEX_BIN" ]; then
    printf '%s\n' "$REAL_CODEX_BIN"
    return 0
  fi

  real_bin=""
  if [ -n "${BASH_VERSION:-}" ]; then
    real_bin="$(type -aP codex 2>/dev/null | grep -vx "$DOTFILES_HOME/bin/codex" | head -n 1)"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    real_bin="$(whence -ap codex 2>/dev/null | grep -vx "$DOTFILES_HOME/bin/codex" | head -n 1)"
  fi

  if [ -n "$real_bin" ] && [ -x "$real_bin" ]; then
    printf '%s\n' "$real_bin"
    return 0
  fi

  return 1
}

_latest_codex_session_file() {
  local sessions_dir="$1"
  [ -d "$sessions_dir" ] || return 0
  find "$sessions_dir" -type f -name '*.jsonl' 2>/dev/null | while read -r path; do
    stat -c '%Y %n' "$path" 2>/dev/null || stat -f '%Sm %N' -t '%s' "$path" 2>/dev/null || true
  done | sort -n | tail -n 1 | cut -d' ' -f2-
}

_prepare_codex_profile() {
  local profile_home="$1"

  if [ "$profile_home" = "$DOTFILES_HOME" ]; then
    return 0
  fi

  mkdir -p "$profile_home/.codex"
  mkdir -p "$profile_home/.codex/plugins"

  if [ -f "$DOTFILES_HOME/.codex/config.toml" ] && [ ! -L "$profile_home/.codex/config.toml" ]; then
    rm -f "$profile_home/.codex/config.toml"
    ln -s "$DOTFILES_HOME/.codex/config.toml" "$profile_home/.codex/config.toml"
  fi

  if [ -d "$DOTFILES/skills" ] && [ ! -L "$profile_home/.codex/skills" ]; then
    rm -rf "$profile_home/.codex/skills"
    ln -s "$DOTFILES/skills" "$profile_home/.codex/skills"
  fi

  if [ -d "$DOTFILES/commands" ] && [ ! -L "$profile_home/.codex/prompts" ]; then
    rm -rf "$profile_home/.codex/prompts"
    ln -s "$DOTFILES/commands" "$profile_home/.codex/prompts"
  fi

  if [ -d "$DOTFILES_HOME/.codex/plugins/cache" ] && [ ! -L "$profile_home/.codex/plugins/cache" ]; then
    rm -rf "$profile_home/.codex/plugins/cache"
    ln -s "$DOTFILES_HOME/.codex/plugins/cache" "$profile_home/.codex/plugins/cache"
  fi

  if [ -f "$DOTFILES_HOME/.codex/hooks.json" ] || [ -L "$DOTFILES_HOME/.codex/hooks.json" ]; then
    if [ ! -L "$profile_home/.codex/hooks.json" ]; then
      rm -f "$profile_home/.codex/hooks.json"
      ln -s "$DOTFILES_HOME/.codex/hooks.json" "$profile_home/.codex/hooks.json"
    fi
  fi

  if [ -d "$DOTFILES_HOME/.config/ainc" ]; then
    mkdir -p "$profile_home/.config"
    if [ ! -L "$profile_home/.config/ainc" ]; then
      rm -rf "$profile_home/.config/ainc"
      ln -s "$DOTFILES_HOME/.config/ainc" "$profile_home/.config/ainc"
    fi
  fi
}

_run_codex_with_home() {
  local profile_home="$1"
  shift

  local real_bin
  local sessions_dir
  local save_session_dir
  local before_file
  local before_mtime
  local after_file
  local after_mtime
  local session_id
  local exit_code
  local had_errexit=0

  real_bin="$(_find_real_codex_bin)" || {
    printf 'codex command not found\n' >&2
    return 127
  }

  _prepare_codex_profile "$profile_home"

  sessions_dir="${CODEX_SESSIONS_DIR:-$profile_home/.codex/sessions}"
  save_session_dir="${SAVE_SESSION_DIR:-$profile_home/codex-sessions}"

  before_file="$(_latest_codex_session_file "$sessions_dir")"
  before_mtime=0
  if [ -n "${before_file:-}" ] && [ -f "$before_file" ]; then
    before_mtime="$(stat -c '%Y' "$before_file" 2>/dev/null || stat -f '%Sm' -t '%s' "$before_file" 2>/dev/null || echo 0)"
  fi

  case $- in
    *e*) had_errexit=1 ;;
  esac

  set +e
  HOME="$profile_home" DOTFILES="$DOTFILES" CODEX_SESSIONS_DIR="$sessions_dir" "$real_bin" "$@"
  exit_code=$?
  if [ "$had_errexit" -eq 1 ]; then
    set -e
  fi

  after_file="$(_latest_codex_session_file "$sessions_dir")"
  after_mtime=0
  if [ -n "${after_file:-}" ] && [ -f "$after_file" ]; then
    after_mtime="$(stat -c '%Y' "$after_file" 2>/dev/null || stat -f '%Sm' -t '%s' "$after_file" 2>/dev/null || echo 0)"
  fi

  if [ -x "$DOTFILES/scripts/save-session-scp.sh" ] && [ -n "${after_file:-}" ] && { [ "$after_file" != "${before_file:-}" ] || [ "$after_mtime" -gt "$before_mtime" ]; }; then
    session_id="$(basename "$after_file" .jsonl | sed -E 's/.*-([0-9a-f-]{8,})$/\1/')"
    python3 - "$session_id" "$after_file" <<'PYEOF' | SAVE_SESSION_DIR="$save_session_dir" "$DOTFILES/scripts/save-session-scp.sh" >/dev/null 2>&1 || true
import json, sys
session_id, transcript_path = sys.argv[1], sys.argv[2]
print(json.dumps({
    "session_id": session_id,
    "transcript_path": transcript_path,
    "source": "codex",
}, ensure_ascii=False))
PYEOF
  fi

  return "$exit_code"
}

# 기존 interactive alias가 함수 정의 토큰을 깨뜨리지 않도록 정리
unalias cc ccd ccr cdd cdd-work cdd-personal cdd-personal-login cu 2>/dev/null || true

# Claude Code
cc() {
  if _require_cmd claude; then
    claude "$@"
    _dotfiles_push
  else
    printf 'claude command not found\n' >&2
    return 127
  fi
}

ccd() {
  if _require_cmd claude; then
    claude --dangerously-skip-permissions "$@"
    _dotfiles_push
  else
    printf 'claude command not found\n' >&2
    return 127
  fi
}

ccr() {
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
  if _require_cmd codex; then
    codex --dangerously-bypass-approvals-and-sandbox "$@"
    _dotfiles_push
  else
    printf 'codex command not found\n' >&2
    return 127
  fi
}

cdd-work() {
  _run_codex_with_home "$CODEX_WORK_HOME" --dangerously-bypass-approvals-and-sandbox "$@"
  local exit_code=$?
  _dotfiles_push
  return "$exit_code"
}

cdd-personal() {
  _run_codex_with_home "$CODEX_PERSONAL_HOME" --dangerously-bypass-approvals-and-sandbox "$@"
  local exit_code=$?
  _dotfiles_push
  return "$exit_code"
}

cdd-personal-login() {
  _run_codex_with_home "$CODEX_PERSONAL_HOME" login "$@"
  local exit_code=$?
  _dotfiles_push
  return "$exit_code"
}

# Cursor CLI
cu() {
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
