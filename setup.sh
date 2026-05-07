#!/bin/bash
# setup.sh — 최초 1회 실행하면 모든 symlink 생성
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "=== dotfiles setup ==="

# 자기 참조 순환 symlink 정리 (디렉토리가 자기 자신을 가리키는 경우)
for dir in "$DOTFILES/commands" "$DOTFILES/skills"; do
  dir_name=$(basename "$dir")
  self_link="$dir/$dir_name"
  if [ -L "$self_link" ]; then
    link_target=$(readlink "$self_link")
    if [ "$link_target" = "$dir" ] || [ "$link_target" = "$(realpath "$dir" 2>/dev/null)" ]; then
      rm "$self_link" && echo "✓ 순환 symlink 제거: $self_link"
    fi
  fi
done

backup_and_link() {
  local target="$1"
  local link="$2"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "백업: $link → $link.bak"
    mv "$link" "$link.bak"
  fi
  ln -sf "$target" "$link" && echo "✓ $link"
}

ensure_line_in_file() {
  local file_path="$1"
  local line="$2"

  touch "$file_path"
  if ! grep -qF "$line" "$file_path"; then
    printf '\n%s\n' "$line" >> "$file_path"
    echo "✓ $file_path에 설정 추가"
  else
    echo "✓ $file_path 설정 이미 존재"
  fi
}

copy_skill_dir() {
  local source_dir="$1"
  local skill_name="$2"
  local target_dir="$DOTFILES/skills/$skill_name"

  rm -rf "$target_dir"
  mkdir -p "$target_dir"
  cp -a "$source_dir"/. "$target_dir"/
  echo "✓ plugin skill copied: $skill_name"
}

# --- plugins (Claude Code 전용) ---
if [ -d "$HOME/.claude" ]; then
  rm -rf ~/.claude/plugins
  ln -s "$DOTFILES/claude_plugins" ~/.claude/plugins && echo "✓ ~/.claude/plugins"
fi

# --- skills ---
if [ -d "$HOME/.claude" ]; then
  rm -rf ~/.claude/skills
  ln -s "$DOTFILES/skills" ~/.claude/skills && echo "✓ ~/.claude/skills"
fi

if [ -d "$HOME/.codex" ]; then
  rm -rf ~/.codex/skills
  ln -s "$DOTFILES/skills" ~/.codex/skills && echo "✓ ~/.codex/skills"
fi

if [ -d "$HOME/.cursor" ]; then
  ln -sfn "$DOTFILES/skills" ~/.cursor/skills && echo "✓ ~/.cursor/skills"
fi

# --- commands ---
if [ -d "$HOME/.claude" ]; then
  rm -rf ~/.claude/commands
  ln -s "$DOTFILES/commands" ~/.claude/commands && echo "✓ ~/.claude/commands"
fi

if [ -d "$HOME/.codex" ]; then
  ln -sfn "$DOTFILES/commands" ~/.codex/prompts && echo "✓ ~/.codex/prompts"
fi

if [ -d "$HOME/.cursor" ]; then
  ln -sfn "$DOTFILES/commands" ~/.cursor/commands && echo "✓ ~/.cursor/commands"
fi

# --- rules ---
backup_and_link "$DOTFILES/rules/base.md" "$HOME/CLAUDE.md"
backup_and_link "$DOTFILES/rules/base.md" "$HOME/AGENTS.md"

if [ -d "$HOME/.cursor" ]; then
  mkdir -p ~/.cursor/rules
  backup_and_link "$DOTFILES/rules/base.md" "$HOME/.cursor/rules/base.mdc"
fi

# --- Claude Code 플러그인 스킬 → dotfiles/skills 동기화 ---
# 플러그인 스킬(예: superpowers/brainstorming)을 Codex/Cursor에서도 사용 가능하게
if [ -d "$HOME/.claude/plugins/cache" ]; then
  echo "플러그인 스킬 동기화 중..."
  find "$HOME/.claude/plugins/cache" -path "*/skills/*/SKILL.md" | while read skill_md; do
    skill_dir=$(dirname "$skill_md")
    skill_name=$(basename "$skill_dir")
    # "skills" 이름은 자기 참조 symlink를 만들므로 제외
    [ "$skill_name" = "skills" ] && continue
    target="$DOTFILES/skills/$skill_name"
    if [ ! -e "$target" ] || [ -L "$target" ]; then
      copy_skill_dir "$skill_dir" "$skill_name"
    fi
  done
fi

# --- mcp ---
if [ -f "$DOTFILES/mcp/secrets.json" ]; then
  if [ -f "$DOTFILES/.gitmodules" ] && [ -d "$DOTFILES/.git" ]; then
    git -C "$DOTFILES" submodule update --init --recursive -- mcp/dooray-mcp || \
      echo "⚠ dooray-mcp submodule 초기화 실패 — 계속 진행"
  fi

  if [ -f "$DOTFILES/mcp/dooray-mcp/package.json" ] && [ ! -f "$DOTFILES/mcp/dooray-mcp/dist/index.js" ]; then
    if command -v npm >/dev/null 2>&1; then
      echo "Dooray MCP 빌드 중..."
      (cd "$DOTFILES/mcp/dooray-mcp" && npm ci && npm run build) || \
        echo "⚠ dooray-mcp 빌드 실패 — 계속 진행"
    else
      echo "⚠ npm 없음 — dooray-mcp 빌드 건너뜀"
    fi
  fi

  "$DOTFILES/mcp/apply.sh" || echo "⚠ MCP 설정 적용 실패 — 계속 진행"
else
  echo "⚠ mcp/secrets.json 없음 — MCP 설정 건너뜀"
fi

# --- shell aliases (dotfiles pull 자동화) ---
SOURCE_LINE="source \"$DOTFILES/shell/aliases.sh\""
PATH_LINE='export PATH="$HOME/bin:$PATH"'
# 현재 쉘 기준으로 rc 파일 결정, 없으면 bash 기본값
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
  SHELL_RC="$HOME/.zshrc"
else
  SHELL_RC="$HOME/.bashrc"
fi
touch "$SHELL_RC"
if ! grep -qF "aliases.sh" "$SHELL_RC"; then
  echo "" >> "$SHELL_RC"
  echo "# dotfiles aliases" >> "$SHELL_RC"
  echo "$SOURCE_LINE" >> "$SHELL_RC"
  echo "✓ $SHELL_RC에 aliases.sh source 추가"
else
  echo "✓ shell aliases 이미 설정됨"
fi
ensure_line_in_file "$SHELL_RC" "$PATH_LINE"
ensure_line_in_file "$HOME/.bashrc" "$PATH_LINE"
ensure_line_in_file "$HOME/.profile" "$PATH_LINE"

# --- ~/bin wrappers (push/save automation) ---
mkdir -p "$HOME/bin"

cat > "$HOME/bin/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
WRAPPER_PATH="$HOME/bin/claude"

real_bin="$(type -aP "claude" | grep -vx "$WRAPPER_PATH" | head -n 1 || true)"
if [ -z "$real_bin" ]; then
  printf 'claude command not found\n' >&2
  exit 127
fi

set +e
"$real_bin" "$@"
status=$?
set -e

if [ -x "$DOTFILES/scripts/push-dotfiles.sh" ]; then
  "$DOTFILES/scripts/push-dotfiles.sh" >/dev/null 2>&1 || true
fi

exit "$status"
EOF
chmod +x "$HOME/bin/claude"
echo "✓ ~/bin/claude"

cat > "$HOME/bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
WRAPPER_PATH="$HOME/bin/codex"
CODEX_SESSIONS_DIR="${CODEX_SESSIONS_DIR:-$HOME/.codex/sessions}"

latest_session_file() {
  find "$CODEX_SESSIONS_DIR" -type f -name '*.jsonl' 2>/dev/null | while read -r path; do
    stat -c '%Y %n' "$path" 2>/dev/null || true
  done | sort -n | tail -n 1 | cut -d' ' -f2-
}

before_file="$(latest_session_file)"
before_mtime=0
if [ -n "${before_file:-}" ] && [ -f "$before_file" ]; then
  before_mtime="$(stat -c '%Y' "$before_file" 2>/dev/null || echo 0)"
fi

real_bin="$(type -aP "codex" | grep -vx "$WRAPPER_PATH" | head -n 1 || true)"
if [ -z "$real_bin" ]; then
  printf 'codex command not found\n' >&2
  exit 127
fi

set +e
"$real_bin" "$@"
status=$?
set -e

if [ -x "$DOTFILES/scripts/push-dotfiles.sh" ]; then
  "$DOTFILES/scripts/push-dotfiles.sh" >/dev/null 2>&1 || true
fi

after_file="$(latest_session_file)"
after_mtime=0
if [ -n "${after_file:-}" ] && [ -f "$after_file" ]; then
  after_mtime="$(stat -c '%Y' "$after_file" 2>/dev/null || echo 0)"
fi

if [ -x "$DOTFILES/scripts/save-session-scp.sh" ] && [ -n "${after_file:-}" ] && { [ "$after_file" != "${before_file:-}" ] || [ "$after_mtime" -gt "$before_mtime" ]; }; then
  session_id="$(basename "$after_file" .jsonl | sed -E 's/.*-([0-9a-f-]{8,})$/\1/')"
  python3 - "$session_id" "$after_file" <<'PYEOF' | SAVE_SESSION_DIR="${SAVE_SESSION_DIR:-$HOME/codex-sessions}" "$DOTFILES/scripts/save-session-scp.sh" >/dev/null 2>&1 || true
import json, sys
session_id, transcript_path = sys.argv[1], sys.argv[2]
print(json.dumps({
    "session_id": session_id,
    "transcript_path": transcript_path,
    "source": "codex",
}, ensure_ascii=False))
PYEOF
fi

exit "$status"
EOF
chmod +x "$HOME/bin/codex"
echo "✓ ~/bin/codex"

cat > "$HOME/bin/wiki" <<'EOF'
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
EOF
chmod +x "$HOME/bin/wiki"
echo "✓ ~/bin/wiki"

cat > "$HOME/bin/cdd-work" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
source "$DOTFILES/shell/aliases.sh"

cdd-work "$@"
EOF
chmod +x "$HOME/bin/cdd-work"
echo "✓ ~/bin/cdd-work"

cat > "$HOME/bin/cdd-personal" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
source "$DOTFILES/shell/aliases.sh"

cdd-personal "$@"
EOF
chmod +x "$HOME/bin/cdd-personal"
echo "✓ ~/bin/cdd-personal"

cat > "$HOME/bin/cdd-personal-login" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
source "$DOTFILES/shell/aliases.sh"

cdd-personal-login "$@"
EOF
chmod +x "$HOME/bin/cdd-personal-login"
echo "✓ ~/bin/cdd-personal-login"

# --- Cursor agent-transcripts watcher (launchd, macOS) ---
if [ "$(uname -s)" = "Darwin" ]; then
  mkdir -p "$DOTFILES/launchd" "$HOME/Library/LaunchAgents" "$HOME/cursor-sessions"
  WATCH_PLIST_SRC="$DOTFILES/launchd/com.geonhee.cursor-agent-transcripts-to-s20.plist"
  WATCH_PLIST_DST="$HOME/Library/LaunchAgents/com.geonhee.cursor-agent-transcripts-to-s20.plist"
  LAUNCH_DOMAIN="gui/$(id -u)"

  if [ -f "$WATCH_PLIST_SRC" ]; then
    # launchd는 plist 내부의 "~" 를 확장하지 않으므로, 설치 시점에 절대경로로 치환한다.
    sed "s|__HOME__|$HOME|g" "$WATCH_PLIST_SRC" > "$WATCH_PLIST_DST"
    echo "✓ LaunchAgent 설치: $WATCH_PLIST_DST"

    # load/reload (사용자 GUI 세션 기준)
    launchctl bootout "$LAUNCH_DOMAIN" "$WATCH_PLIST_DST" >/dev/null 2>&1 || true
    launchctl bootstrap "$LAUNCH_DOMAIN" "$WATCH_PLIST_DST" >/dev/null 2>&1 || true
    launchctl enable "$LAUNCH_DOMAIN/com.geonhee.cursor-agent-transcripts-to-s20" >/dev/null 2>&1 || true
    launchctl kickstart -k "$LAUNCH_DOMAIN/com.geonhee.cursor-agent-transcripts-to-s20" >/dev/null 2>&1 || true

    echo "✓ Cursor 세션 자동 전송 watcher 활성화"
  else
    # 예전 plist는 KeepAlive=true라서 소스 삭제 후에도 실패 재시작 루프가 남을 수 있다.
    launchctl bootout "$LAUNCH_DOMAIN" "$WATCH_PLIST_DST" >/dev/null 2>&1 || true
    rm -f "$WATCH_PLIST_DST"
    echo "✓ legacy Cursor watcher 정리: $WATCH_PLIST_DST"
  fi
fi

# --- Claude SessionStart 자동 pull 훅 정리 ---
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
  python3 - <<'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
dotfiles = os.path.expanduser("~/dotfiles")
sync_script = f"{dotfiles}/scripts/sync-dotfiles.sh"

with open(settings_path) as f:
    s = json.load(f)

hooks = s.get("hooks", {})
session_start = hooks.get("SessionStart", [])

for entry in session_start:
    if not isinstance(entry, dict) or not isinstance(entry.get("hooks"), list):
        continue
    entry["hooks"] = [
        h for h in entry["hooks"]
        if sync_script not in h.get("command", "")
        and not ("git -C" in h.get("command", "") and "dotfiles" in h.get("command", ""))
    ]

hooks["SessionStart"] = [
    entry for entry in session_start
    if isinstance(entry, dict) and entry.get("hooks")
]
if not hooks["SessionStart"]:
    hooks.pop("SessionStart", None)

with open(settings_path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("✓ Claude SessionStart 자동 pull 훅 정리")
PYEOF
else
  echo "✓ Claude settings 없음 — SessionStart 훅 건너뜀"
fi

# --- Claude SessionEnd 훅 (세션 요약 → SCP) ---
if [ -f "$CLAUDE_SETTINGS" ]; then
  python3 - <<'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
dotfiles = os.path.expanduser("~/dotfiles")
save_script = f"{dotfiles}/scripts/save-session-scp.sh"

with open(settings_path) as f:
    s = json.load(f)

save_hook = {"type": "command", "command": save_script}
hooks = s.setdefault("hooks", {})
session_end = hooks.setdefault("SessionEnd", [{"hooks": []}])
existing = session_end[0]["hooks"]

if not any(save_script in h.get("command", "") for h in existing):
    existing.append(save_hook)

session_end[0]["hooks"] = existing

with open(settings_path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("✓ Claude SessionEnd 훅 추가")
PYEOF
else
  echo "✓ Claude settings 없음 — SessionEnd 훅 건너뜀"
fi

# --- Claude 자동 git push 훅 정리 ---
if [ -f "$CLAUDE_SETTINGS" ]; then
  python3 - <<'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")

with open(settings_path) as f:
    s = json.load(f)

changed = False
hooks = s.get("hooks", {})

for event, entries in list(hooks.items()):
    if not isinstance(entries, list):
        continue
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("hooks"), list):
            continue
        before = len(entry["hooks"])
        entry["hooks"] = [
            h for h in entry["hooks"]
            if "push-dotfiles.sh" not in h.get("command", "")
        ]
        changed = changed or len(entry["hooks"]) != before

if changed:
    with open(settings_path, "w") as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
        f.write("\n")

print("✓ Claude 자동 push 훅 정리")
PYEOF
fi

# --- ssh config ---
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
SSH_CONFIG="$HOME/.ssh/config"
INCLUDE_LINE="Include $DOTFILES/ssh/config"
if [ ! -f "$SSH_CONFIG" ] || ! grep -qF "$DOTFILES/ssh/config" "$SSH_CONFIG"; then
  # Include는 반드시 파일 맨 위에 있어야 적용됨
  if [ -f "$SSH_CONFIG" ]; then
    tmp=$(mktemp)
    { echo "$INCLUDE_LINE"; echo ""; cat "$SSH_CONFIG"; } > "$tmp"
    mv "$tmp" "$SSH_CONFIG"
  else
    echo "$INCLUDE_LINE" > "$SSH_CONFIG"
  fi
  chmod 600 "$SSH_CONFIG"
  echo "✓ ~/.ssh/config에 dotfiles/ssh/config Include 추가"
else
  echo "✓ ssh config 이미 설정됨"
fi

# --- S20 SSH 키 설정 ---
S20_KEY="$HOME/.ssh/id_ed25519_s20"
if [ ! -f "$S20_KEY" ]; then
  echo ""
  echo "S20 SSH 키가 없습니다. 새로 생성합니다..."
  ssh-keygen -t ed25519 -f "$S20_KEY" -N "" -C "$(hostname)-$(date +%Y%m%d)"
  chmod 600 "$S20_KEY"
  echo "✓ 키 생성: $S20_KEY"

  echo ""
  echo "S20에 공개키를 등록합니다. S20 비밀번호를 입력하세요:"
  ssh-copy-id -i "${S20_KEY}.pub" -p 8022 YOUR_S20_USER@YOUR_S20_IP \
    && echo "✓ S20 공개키 등록 완료 — 이후 passwordless 접속 가능" \
    || echo "⚠ 공개키 등록 실패. 수동으로 등록하세요: ssh-copy-id -i ${S20_KEY}.pub -p 8022 YOUR_S20_USER@YOUR_S20_IP"
else
  echo "✓ S20 SSH 키 이미 존재: $S20_KEY"
fi

# --- Cursor agent-transcripts watcher (launchd 등록) ---
if [[ "$(uname -s)" == "Darwin" ]]; then
  PLIST_DIR="$HOME/Library/LaunchAgents"
  PLIST_PATH="$PLIST_DIR/com.geonhee.watch-agent-transcripts.plist"
  WATCH_SCRIPT="$DOTFILES/scripts/watch-agent-transcripts.sh"
  mkdir -p "$PLIST_DIR"

  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.geonhee.watch-agent-transcripts</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${WATCH_SCRIPT}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${HOME}/cursor-sessions/watch-agent.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/cursor-sessions/watch-agent.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>DOTFILES</key>
        <string>${DOTFILES}</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
PLIST

  mkdir -p "$HOME/cursor-sessions"
  # 기존에 로드되어 있으면 언로드 후 재로드
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
  launchctl load "$PLIST_PATH" && echo "✓ watch-agent-transcripts launchd 등록 완료"
fi

# --- codex 최신 버전 유지 ---
if command -v npm >/dev/null 2>&1; then
  INSTALLED_CODEX="$(npm list -g @openai/codex --prefix "$(npm root -g)/.." 2>/dev/null | grep '@openai/codex@' | sed 's/.*@//' || echo '')"
  LATEST_CODEX="$(npm show @openai/codex version 2>/dev/null || echo '')"
  if [ -n "$LATEST_CODEX" ] && [ "$INSTALLED_CODEX" != "$LATEST_CODEX" ]; then
    echo "codex 업그레이드 중: ${INSTALLED_CODEX:-없음} → $LATEST_CODEX"
    npm install -g "@openai/codex@$LATEST_CODEX" || echo "⚠ codex 업그레이드 실패 — 계속 진행"
  else
    echo "✓ codex 최신 버전: ${INSTALLED_CODEX}"
  fi
else
  echo "⚠ npm 없음 — codex 업그레이드 건너뜀"
fi

echo ""
echo "=== setup 완료 ==="
