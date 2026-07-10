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

_path_prepend_once() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
  export PATH
}

_refresh_command_hash() {
  hash -r 2>/dev/null || true
  rehash 2>/dev/null || true
}

_codex_update_cache_fresh() {
  local cache_file="$1"
  local ttl="${CODEX_UPDATE_CACHE_TTL:-86400}"
  local now
  local last

  [ "$ttl" -gt 0 ] 2>/dev/null || return 1
  [ -f "$cache_file" ] || return 1

  now="$(date +%s 2>/dev/null || echo 0)"
  last="$(stat -c '%Y' "$cache_file" 2>/dev/null || stat -f '%m' "$cache_file" 2>/dev/null || echo 0)"
  [ $((now - last)) -lt "$ttl" ]
}

_ensure_latest_codex() {
  local cache_file="${CODEX_UPDATE_CACHE_FILE:-$DOTFILES_HOME/.cache/codex-update-check}"
  local npm_prefix
  local installed_version
  local latest_version

  [ "${CODEX_AUTO_UPDATE:-1}" != "0" ] || return 0
  [ -z "${REAL_CODEX_BIN:-}" ] || return 0
  _require_cmd npm || return 0
  _codex_update_cache_fresh "$cache_file" && return 0

  npm_prefix="$(npm config get prefix 2>/dev/null || true)"
  if [ -z "$npm_prefix" ] || [ "$npm_prefix" = "undefined" ]; then
    npm_prefix="$HOME/.npm-global"
  fi

  if ! mkdir -p "$npm_prefix/bin" "$npm_prefix/lib/node_modules" 2>/dev/null; then
    npm_prefix="$HOME/.npm-global"
    mkdir -p "$npm_prefix/bin" "$npm_prefix/lib/node_modules" 2>/dev/null || return 0
  fi

  _path_prepend_once "$npm_prefix/bin"

  latest_version="$(npm show @openai/codex version 2>/dev/null || true)"
  [ -n "$latest_version" ] || {
    mkdir -p "$(dirname "$cache_file")" 2>/dev/null && : >"$cache_file" 2>/dev/null || true
    return 0
  }

  installed_version="$(npm list -g @openai/codex --depth=0 2>/dev/null | sed -nE 's/.*@openai\/codex@([^[:space:]]+).*/\1/p' | head -n 1 || true)"
  if [ "$installed_version" != "$latest_version" ]; then
    npm_config_prefix="$npm_prefix" npm install -g "@openai/codex@$latest_version" >/dev/null 2>&1 || return 0
    _refresh_command_hash
  fi

  mkdir -p "$(dirname "$cache_file")" 2>/dev/null && : >"$cache_file" 2>/dev/null || true
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
  first_bin=""
  versioned_bins=""
  seen_bins=""
  if [ -n "${BASH_VERSION:-}" ]; then
    codex_bins="$(type -aP codex 2>/dev/null || true)"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    codex_bins="$(whence -ap codex 2>/dev/null || true)"
  else
    codex_bins="$(command -v codex 2>/dev/null || true)"
  fi

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    [ "$candidate" != "$DOTFILES_HOME/bin/codex" ] || continue
    [ -x "$candidate" ] || continue
    case ":$seen_bins:" in
      *":$candidate:"*) continue ;;
    esac
    seen_bins="${seen_bins:-}:$candidate"
    [ -n "$first_bin" ] || first_bin="$candidate"
    candidate_version="$("$candidate" --version 2>/dev/null | sed -nE 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n 1 || true)"
    if [ -n "$candidate_version" ]; then
      versioned_bins="${versioned_bins}${candidate_version}	${candidate}
"
    fi
  done <<EOF
$codex_bins
EOF

  if [ -n "$versioned_bins" ]; then
    real_bin="$(printf '%s' "$versioned_bins" | sort -t '	' -k1,1V | tail -n 1 | cut -f2-)"
  else
    real_bin="$first_bin"
  fi

  if [ -n "${real_bin:-}" ] && [ -x "$real_bin" ]; then
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

  _ensure_latest_codex

  real_bin="$(_find_real_codex_bin)" || {
    printf 'codex command not found\n' >&2
    return 127
  }

  _prepare_codex_profile "$profile_home"

  sessions_dir="$profile_home/.codex/sessions"
  save_session_dir="$profile_home/codex-sessions"

  before_file="$(_latest_codex_session_file "$sessions_dir")"
  before_mtime=0
  if [ -n "${before_file:-}" ] && [ -f "$before_file" ]; then
    before_mtime="$(stat -c '%Y' "$before_file" 2>/dev/null || stat -f '%Sm' -t '%s' "$before_file" 2>/dev/null || echo 0)"
  fi

  case $- in
    *e*) had_errexit=1 ;;
  esac

  set +e
  HOME="$profile_home" \
    CODEX_HOME="$profile_home/.codex" \
    DOTFILES="$DOTFILES" \
    CODEX_SESSIONS_DIR="$sessions_dir" \
    "$real_bin" "$@"
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
  _run_codex_with_home "$CODEX_WORK_HOME" --dangerously-bypass-approvals-and-sandbox "$@"
  local exit_code=$?
  _dotfiles_push
  return "$exit_code"
}

cdd-work() {
  _run_codex_with_home "$CODEX_WORK_HOME" --dangerously-bypass-approvals-and-sandbox "$@"
  local exit_code=$?
  _dotfiles_push
  return "$exit_code"
}

cdd-personal() {
  if [ "${1:-}" = "update" ]; then
    shift
    _run_codex_with_home "$CODEX_PERSONAL_HOME" update "$@"
  else
    _run_codex_with_home "$CODEX_PERSONAL_HOME" --dangerously-bypass-approvals-and-sandbox "$@"
  fi
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
