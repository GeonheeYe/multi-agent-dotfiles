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
printf 'real:%s args:%s\n' "$HOME" "$*"
EOF
chmod +x "$temp_home/bin/codex-real"

for script in sync-dotfiles.sh push-dotfiles.sh; do
  cat >"$temp_home/dotfiles/scripts/$script" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$temp_home/dotfiles/scripts/$script"
done

work_output="$(
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -lc '
    source "'"$ALIASES"'"
    cdd-work hello
  '
)"
assert_contains "$work_output" "real:$temp_home args:--dangerously-bypass-approvals-and-sandbox hello" "cdd-work should use current HOME and bypass flag"

personal_output="$(
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -lc '
    source "'"$ALIASES"'"
    cdd-personal world
  '
)"
assert_contains "$personal_output" "real:$temp_home/.codex-personal-home args:--dangerously-bypass-approvals-and-sandbox world" "cdd-personal should use personal HOME and bypass flag"
[ -L "$temp_home/.codex-personal-home/.codex/skills" ] || fail "cdd-personal should link shared skills"
[ -L "$temp_home/.codex-personal-home/.codex/prompts" ] || fail "cdd-personal should link shared prompts"
[ -L "$temp_home/.codex-personal-home/.codex/config.toml" ] || fail "cdd-personal should link shared config"
[ -L "$temp_home/.codex-personal-home/.codex/plugins/cache" ] || fail "cdd-personal should link shared plugin cache"

personal_update_output="$(
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -lc '
    source "'"$ALIASES"'"
    cdd-personal update
  '
)"
assert_contains "$personal_update_output" "real:$temp_home/.codex-personal-home args:update" "cdd-personal update should run codex update with personal HOME"

login_output="$(
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" REAL_CODEX_BIN="$temp_home/bin/codex-real" /bin/bash -lc '
    source "'"$ALIASES"'"
    cdd-personal-login status
  '
)"
assert_contains "$login_output" "real:$temp_home/.codex-personal-home args:login status" "cdd-personal-login should use personal HOME without bypass flag"

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
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" PATH="$temp_home/bin:$temp_home/old-codex/bin:$temp_home/new-codex/bin:$PATH" /bin/bash -lc '
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
  HOME="$temp_home" DOTFILES="$temp_home/dotfiles" FAKE_NPM_PREFIX="$temp_home/fake-npm/prefix" FAKE_NPM_LOG="$temp_home/fake-npm/install.log" PATH="$temp_home/fake-npm/bin:$temp_home/bin:$temp_home/old-codex/bin:$temp_home/new-codex/bin:$PATH" CODEX_UPDATE_CACHE_TTL=0 /bin/bash -lc '
    source "'"$ALIASES"'"
    _ensure_latest_codex
    _find_real_codex_bin
  '
)"
assert_contains "$ensure_latest_output" "$temp_home/fake-npm/prefix/bin/codex" "_ensure_latest_codex should refresh PATH hashing and expose the updated npm codex binary"
assert_contains "$(cat "$temp_home/fake-npm/install.log")" "install:install -g @openai/codex@0.132.0" "_ensure_latest_codex should install the latest codex version when npm reports an update"

echo "PASS"
