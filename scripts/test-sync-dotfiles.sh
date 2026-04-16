#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC_SCRIPT="$ROOT_DIR/scripts/sync-dotfiles.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [ "$expected" != "$actual" ]; then
    fail "$message (expected=$expected actual=$actual)"
  fi
}

test_runs_setup_when_head_changes() {
  local tmpdir remote repo
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  remote="$tmpdir/remote.git"
  repo="$tmpdir/repo"

  git init --bare "$remote" >/dev/null
  git clone "$remote" "$repo" >/dev/null 2>&1

  (
    cd "$repo"
    git config user.name test
    git config user.email test@example.com
    printf 'one\n' > tracked.txt
    git add tracked.txt
    git commit -m 'init' >/dev/null
    git push origin HEAD >/dev/null 2>&1
  )

  local setup_stub
  setup_stub="$tmpdir/setup.sh"
  cat > "$setup_stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count_file="${SETUP_COUNT_FILE:?}"
count=0
if [ -f "$count_file" ]; then
  count="$(cat "$count_file")"
fi
printf '%s\n' "$((count + 1))" > "$count_file"
EOF
  chmod +x "$setup_stub"

  local clone before
  clone="$tmpdir/clone"
  git clone "$remote" "$clone" >/dev/null 2>&1
  cp "$setup_stub" "$clone/setup.sh"
  chmod +x "$clone/setup.sh"

  before="$(git -C "$clone" rev-parse HEAD)"

  (
    cd "$repo"
    printf 'two\n' >> tracked.txt
    git add tracked.txt
    git commit -m 'update' >/dev/null
    git push origin HEAD >/dev/null 2>&1
  )

  SETUP_COUNT_FILE="$tmpdir/count" DOTFILES="$clone" "$SYNC_SCRIPT"

  assert_eq "1" "$(cat "$tmpdir/count")" "setup.sh should run once after pull"
  if [ "$before" = "$(git -C "$clone" rev-parse HEAD)" ]; then
    fail "expected HEAD to change after sync"
  fi
}

test_skips_setup_when_head_unchanged() {
  local tmpdir remote repo
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  remote="$tmpdir/remote.git"
  repo="$tmpdir/repo"

  git init --bare "$remote" >/dev/null
  git clone "$remote" "$repo" >/dev/null 2>&1

  (
    cd "$repo"
    git config user.name test
    git config user.email test@example.com
    printf 'one\n' > tracked.txt
    git add tracked.txt
    git commit -m 'init' >/dev/null
    git push origin HEAD >/dev/null 2>&1
  )

  local setup_stub
  setup_stub="$tmpdir/setup.sh"
  cat > "$setup_stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count_file="${SETUP_COUNT_FILE:?}"
count=0
if [ -f "$count_file" ]; then
  count="$(cat "$count_file")"
fi
printf '%s\n' "$((count + 1))" > "$count_file"
EOF
  chmod +x "$setup_stub"

  local clone
  clone="$tmpdir/clone"
  git clone "$remote" "$clone" >/dev/null 2>&1
  cp "$setup_stub" "$clone/setup.sh"
  chmod +x "$clone/setup.sh"

  SETUP_COUNT_FILE="$tmpdir/count" DOTFILES="$clone" "$SYNC_SCRIPT"

  if [ -f "$tmpdir/count" ]; then
    fail "setup.sh should not run when HEAD is unchanged"
  fi
}

test_runs_setup_when_head_changes
test_skips_setup_when_head_unchanged

printf 'PASS: sync-dotfiles\n'
