#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/push-dotfiles.sh"

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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    fail "$message"
  fi
}

run_push_case() {
  local porcelain_output="$1"
  local worktree_diff_exit="$2"
  local index_diff_exit="$3"
  local local_rev="${4:-local-sha}"
  local remote_rev="${5:-remote-sha}"

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
    if [ "\${2-}" = "--porcelain" ]; then
      printf '%s' "$porcelain_output"
    fi
    ;;
  diff)
    if [ "\${2-}" = "--cached" ]; then
      exit "$index_diff_exit"
    fi
    exit "$worktree_diff_exit"
    ;;
  rev-parse)
    case "\${2-}" in
      HEAD)
        printf '%s\n' "$local_rev"
        ;;
      "@{u}")
        printf '%s\n' "$remote_rev"
        ;;
    esac
    ;;
  *)
    ;;
esac
EOF
  chmod +x "$temp_dir/git"

  PATH="$temp_dir:$PATH" DOTFILES="$temp_dir/repo" bash "$SCRIPT" >/dev/null 2>&1 || fail "push script should exit successfully"

  cat "$git_log"
}

[ -f "$SCRIPT" ] || fail "missing push script: $SCRIPT"

untracked_log="$(run_push_case "?? new-file.txt" 0 0)"
assert_contains "$untracked_log" "status --porcelain --untracked-files=normal" "untracked 파일 확인을 위해 git status를 호출해야 함"
assert_contains "$untracked_log" "add -A" "untracked 파일만 있어도 git add -A를 호출해야 함"
assert_contains "$untracked_log" "commit -m chore: auto-sync" "untracked 파일만 있어도 commit을 시도해야 함"
assert_contains "$untracked_log" "push --quiet" "로컬과 원격 rev가 다르면 push를 시도해야 함"

clean_log="$(run_push_case \"\" 0 0 same-sha same-sha)"
assert_contains "$clean_log" "status --porcelain --untracked-files=normal" "clean 상태에서도 git status를 호출해야 함"
assert_not_contains "$clean_log" "add -A" "변경이 없으면 git add -A를 호출하면 안 됨"

echo "PASS"
