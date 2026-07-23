#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALIASES="$ROOT/shell/aliases.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$message"
  fi
}

[ -f "$ALIASES" ] || fail "missing aliases file: $ALIASES"

temp_home="$(mktemp -d)"
trap 'rm -rf "$temp_home"' EXIT

mkdir -p "$temp_home/bin" "$temp_home/dotfiles/scripts"
mkdir -p "$temp_home/dotfiles/skills" "$temp_home/dotfiles/commands"
mkdir -p "$temp_home/.codex/plugins/cache"
echo 'model = "gpt-5.4"' >"$temp_home/.codex/config.toml"

cat >"$temp_home/bin/codex-real" <<'EOF'
#!/usr/bin/env bash
printf 'real:%s codex_home:%s sessions:%s args:%s\n' "$HOME" "$CODEX_HOME" "$CODEX_SESSIONS_DIR" "$*"
EOF
chmod +x "$temp_home/bin/codex-real"

for script in sync-dotfiles.sh push-dotfiles.sh; do
  cat >"$temp_home/dotfiles/scripts/$script" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$temp_home/dotfiles/scripts/$script"
done

work_output_file="$temp_home/work-output"
HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd-work hello
  ' >"$work_output_file"
work_output="$(cat "$work_output_file")"
assert_contains "$work_output" "real:$temp_home " "cdd-work should use current HOME"
assert_contains "$work_output" "args:--dangerously-bypass-approvals-and-sandbox hello" "cdd-work should use the bypass flag"
assert_contains "$work_output" "codex_home:$temp_home/.codex" "cdd-work should use the work CODEX_HOME"
assert_contains "$work_output" "sessions:$temp_home/.codex/sessions" "cdd-work should keep work sessions separate"

cdd_output_file="$temp_home/cdd-output"
HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd short
  ' >"$cdd_output_file"
cdd_output="$(cat "$cdd_output_file")"
assert_contains "$cdd_output" "real:$temp_home " "cdd should use the work profile HOME"
assert_contains "$cdd_output" "args:--dangerously-bypass-approvals-and-sandbox short" "cdd should use the bypass flag"

login_work_output_file="$temp_home/login-work-output"
HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd-login status
  ' >"$login_work_output_file"
login_work_output="$(cat "$login_work_output_file")"
assert_contains "$login_work_output" "real:$temp_home " "cdd-login should use the work profile HOME"
assert_contains "$login_work_output" "args:login status" "cdd-login should run login without bypass flag"

personal_shell_output_file="$temp_home/personal-shell-output"
HOME="$temp_home/.codex-personal-home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd from-personal-shell
  ' >"$personal_shell_output_file"
personal_shell_output="$(cat "$personal_shell_output_file")"
assert_contains "$personal_shell_output" "real:$temp_home " "cdd should recover the work HOME when sourced inside the personal profile"
assert_contains "$personal_shell_output" "codex_home:$temp_home/.codex" "cdd should recover the work CODEX_HOME inside the personal profile"

personal_output_file="$temp_home/personal-output"
HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd-personal world
  ' >"$personal_output_file"
personal_output="$(cat "$personal_output_file")"
assert_contains "$personal_output" "real:$temp_home/.codex-personal-home " "cdd-personal should use personal HOME"
assert_contains "$personal_output" "args:--dangerously-bypass-approvals-and-sandbox world" "cdd-personal should use the bypass flag"
assert_contains "$personal_output" "codex_home:$temp_home/.codex-personal-home/.codex" "cdd-personal should use the personal CODEX_HOME"
assert_contains "$personal_output" "sessions:$temp_home/.codex-personal-home/.codex/sessions" "cdd-personal should keep personal sessions separate"
[ -L "$temp_home/.codex-personal-home/.codex/skills" ] || fail "cdd-personal should link shared skills"
[ -L "$temp_home/.codex-personal-home/.codex/prompts" ] || fail "cdd-personal should link shared prompts"
[ -L "$temp_home/.codex-personal-home/.codex/config.toml" ] || fail "cdd-personal should link shared config"
[ -L "$temp_home/.codex-personal-home/.codex/plugins/cache" ] || fail "cdd-personal should link shared plugin cache"

personal_update_output_file="$temp_home/personal-update-output"
HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd-personal update
  ' >"$personal_update_output_file"
personal_update_output="$(cat "$personal_update_output_file")"
assert_contains "$personal_update_output" "real:$temp_home/.codex-personal-home " "cdd-personal update should use personal HOME"
assert_contains "$personal_update_output" "args:update" "cdd-personal update should run codex update"

login_output_file="$temp_home/login-output"
HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -c '
    source "'"$ALIASES"'"
    cdd-personal-login status
  ' >"$login_output_file"
login_output="$(cat "$login_output_file")"
assert_contains "$login_output" "real:$temp_home/.codex-personal-home " "cdd-personal-login should use personal HOME"
assert_contains "$login_output" "args:login status" "cdd-personal-login should run login without bypass flag"

mkdir -p "$temp_home/old-codex/bin" "$temp_home/new-codex/bin"
cat >"$temp_home/bin/codex" <<'EOF'
#!/usr/bin/env bash
echo wrapper
EOF
cat >"$temp_home/old-codex/bin/codex" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "codex-cli 0.130.0"
  exit 0
fi
echo old-codex
EOF
cat >"$temp_home/new-codex/bin/codex" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "codex-cli 0.131.0"
  exit 0
fi
echo new-codex
EOF
chmod +x "$temp_home/bin/codex" "$temp_home/old-codex/bin/codex" "$temp_home/new-codex/bin/codex"
latest_codex_output="$(
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" PATH="$temp_home/bin:$temp_home/old-codex/bin:$temp_home/new-codex/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" /bin/bash -c '
    source "'"$ALIASES"'"
    _find_real_codex_bin
  '
)"
assert_contains "$latest_codex_output" "$temp_home/new-codex/bin/codex" "_find_real_codex_bin should select the newest codex version on PATH"

mkdir -p "$temp_home/fake-npm/bin" "$temp_home/fake-npm/prefix/bin" "$temp_home/fake-npm/prefix/lib/node_modules/@openai/codex/bin"
cat >"$temp_home/fake-npm/bin/npm" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "config get prefix")
    printf '%s\n' "$FAKE_NPM_PREFIX"
    ;;
  "show @openai/codex version")
    echo "0.132.0"
    ;;
  "list -g @openai/codex --depth=0")
    echo "$FAKE_NPM_PREFIX/lib"
    echo "└── @openai/codex@0.131.0"
    ;;
  "install -g @openai/codex@0.132.0")
    printf 'install:%s\n' "$*" >>"$FAKE_NPM_LOG"
    ln -sfn ../lib/node_modules/@openai/codex/bin/codex.js "$FAKE_NPM_PREFIX/bin/codex"
    ;;
  *)
    echo "unexpected npm args: $*" >&2
    exit 2
    ;;
esac
EOF
cat >"$temp_home/fake-npm/prefix/lib/node_modules/@openai/codex/bin/codex.js" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "codex-cli 0.132.0"
  exit 0
fi
echo updated-codex
EOF
chmod +x "$temp_home/fake-npm/bin/npm" "$temp_home/fake-npm/prefix/lib/node_modules/@openai/codex/bin/codex.js"
ensure_latest_output="$(
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" FAKE_NPM_PREFIX="$temp_home/fake-npm/prefix" FAKE_NPM_LOG="$temp_home/fake-npm/install.log" PATH="$temp_home/fake-npm/bin:$temp_home/bin:$temp_home/old-codex/bin:$temp_home/new-codex/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" CODEX_UPDATE_CACHE_TTL=0 /bin/bash -c '
    source "'"$ALIASES"'"
    _ensure_latest_codex
    _find_real_codex_bin
  '
)"
assert_contains "$ensure_latest_output" "$temp_home/fake-npm/prefix/bin/codex" "_ensure_latest_codex should refresh PATH hashing and expose the updated npm codex binary"
assert_contains "$(cat "$temp_home/fake-npm/install.log")" "install:install -g @openai/codex@0.132.0" "_ensure_latest_codex should install the latest codex version when npm reports an update"

echo "PASS"
