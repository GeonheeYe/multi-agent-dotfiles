#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/dotfiles-auto-sync.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [ "$actual" != "$expected" ]; then
    fail "$message (expected: $expected, actual: $actual)"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$message"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    fail "$message"
  fi
}

path_entry_count() {
  local path_value="$1"
  local needle="$2"
  local count=0
  local entry
  IFS=: read -r -a entries <<<"$path_value"
  for entry in "${entries[@]}"; do
    if [ "$entry" = "$needle" ]; then
      count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

run_sync_case() {
  local status_output="$1"
  local pull_output="${2-}"
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN
  mkdir -p "$temp_dir/repo/.git"

  local git_log="$temp_dir/git.log"
  cat >"$temp_dir/git" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$git_log"
if [ "\${1-}" = "-C" ]; then
  shift 2
fi
case "\${1-}" in
  status)
    printf '%s' "$status_output"
    ;;
  pull)
    printf '%s' "$pull_output"
    ;;
  *)
    ;;
esac
EOF
  chmod +x "$temp_dir/git"

  PATH="$temp_dir:$PATH" DOTFILES_DIR="$temp_dir/repo" bash "$SCRIPT" >/dev/null 2>&1 || fail "sync script should exit successfully"

  cat "$git_log"
}

[ -f "$SCRIPT" ] || fail "missing sync script: $SCRIPT"

clean_log="$(run_sync_case "")"
assert_contains "$clean_log" "status --porcelain" "clean repo should check git status"
assert_contains "$clean_log" "pull --ff-only" "clean repo should run git pull --ff-only"

dirty_log="$(run_sync_case " M README.md")"
assert_contains "$dirty_log" "status --porcelain" "dirty repo should check git status"
if [[ "$dirty_log" == *"pull --ff-only"* ]]; then
  fail "dirty repo should skip git pull"
fi

temp_home="$(mktemp -d)"
trap 'rm -rf "$temp_home"' EXIT
mkdir -p "$temp_home/.codex" "$temp_home/bin"
HOME="$temp_home" DOTFILES_SKIP_LAUNCHD=1 bash "$ROOT/setup.sh" >/dev/null 2>&1 || true
HOME="$temp_home" DOTFILES_SKIP_LAUNCHD=1 bash "$ROOT/setup.sh" >/dev/null 2>&1 || true

[ -f "$temp_home/bin/claude" ] || fail "setup should install ~/bin/claude wrapper"
[ -f "$temp_home/bin/codex" ] || fail "setup should install ~/bin/codex wrapper"
[ -f "$temp_home/bin/cdd-work" ] || fail "setup should install ~/bin/cdd-work wrapper"
[ -f "$temp_home/bin/cdd-personal" ] || fail "setup should install ~/bin/cdd-personal wrapper"
[ -f "$temp_home/bin/cdd-personal-login" ] || fail "setup should install ~/bin/cdd-personal-login wrapper"
[ -f "$temp_home/.profile" ] || fail "setup should create ~/.profile for PATH bootstrap"
[ -f "$temp_home/.bashrc" ] || fail "setup should create ~/.bashrc for PATH bootstrap"

claude_wrapper="$(cat "$temp_home/bin/claude")"
assert_not_contains "$claude_wrapper" "dotfiles-auto-sync.sh" "claude wrapper should not pull dotfiles on startup"
assert_contains "$claude_wrapper" "push-dotfiles.sh" "claude wrapper should run push script after exit"
assert_contains "$claude_wrapper" 'type -aP "claude"' "claude wrapper should resolve the real binary"
assert_contains "$claude_wrapper" '"$real_bin" "$@"' "claude wrapper should invoke the real binary"

codex_wrapper="$(cat "$temp_home/bin/codex")"
assert_not_contains "$codex_wrapper" "dotfiles-auto-sync.sh" "codex wrapper should not pull dotfiles on startup"
assert_contains "$codex_wrapper" "push-dotfiles.sh" "codex wrapper should run push script after exit"
assert_contains "$codex_wrapper" "save-session-scp.sh" "codex wrapper should save sessions after exit"
assert_contains "$codex_wrapper" 'type -aP "codex"' "codex wrapper should resolve the real binary"
assert_contains "$codex_wrapper" '"$real_bin" "$@"' "codex wrapper should invoke the real binary"

cdd_work_wrapper="$(cat "$temp_home/bin/cdd-work")"
assert_contains "$cdd_work_wrapper" 'source "$DOTFILES/shell/aliases.sh"' "cdd-work wrapper should source aliases"
assert_contains "$cdd_work_wrapper" 'cdd-work "$@"' "cdd-work wrapper should delegate to cdd-work function"

cdd_personal_wrapper="$(cat "$temp_home/bin/cdd-personal")"
assert_contains "$cdd_personal_wrapper" 'source "$DOTFILES/shell/aliases.sh"' "cdd-personal wrapper should source aliases"
assert_contains "$cdd_personal_wrapper" 'cdd-personal "$@"' "cdd-personal wrapper should delegate to cdd-personal function"

cdd_personal_login_wrapper="$(cat "$temp_home/bin/cdd-personal-login")"
assert_contains "$cdd_personal_login_wrapper" 'source "$DOTFILES/shell/aliases.sh"' "cdd-personal-login wrapper should source aliases"
assert_contains "$cdd_personal_login_wrapper" 'cdd-personal-login "$@"' "cdd-personal-login wrapper should delegate to cdd-personal-login function"

profile_contents="$(cat "$temp_home/.profile")"
assert_contains "$profile_contents" 'export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"' "~/.profile should prepend local tool paths to PATH"

bashrc_contents="$(cat "$temp_home/.bashrc")"
assert_contains "$bashrc_contents" 'export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"' "~/.bashrc should prepend local tool paths to PATH"

login_path="$(HOME="$temp_home" bash -lc 'source "$HOME/.profile"; source "$HOME/.bashrc"; printf "%s\n" "$PATH"')"
assert_eq "$(path_entry_count "$login_path" "$temp_home/bin")" "1" "setup should dedupe ~/bin in login PATH"
assert_eq "$(path_entry_count "$login_path" "$temp_home/.local/bin")" "1" "setup should dedupe ~/.local/bin in login PATH"
assert_eq "$(path_entry_count "$login_path" "$temp_home/.npm-global/bin")" "1" "setup should dedupe ~/.npm-global/bin in login PATH"

echo "PASS"
