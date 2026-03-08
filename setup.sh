#!/bin/bash
# dotfiles setup.sh — 최초 1회 실행하면 모든 symlink 생성
set -e

DOTFILES="$HOME/dotfiles"

echo "=== dotfiles setup 시작 ==="

# --- plugins ---
rm -rf ~/.claude/plugins
ln -s "$DOTFILES/claude_plugins" ~/.claude/plugins && echo "✓ ~/.claude/plugins"

# --- skills ---
backup_and_link() {
  local target="$1"
  local link="$2"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "백업: $link → $link.bak"
    mv "$link" "$link.bak"
  fi
  ln -sf "$target" "$link" && echo "✓ $link"
}

# ~/.claude/skills
rm -rf ~/.claude/skills
ln -s "$DOTFILES/skills" ~/.claude/skills && echo "✓ ~/.claude/skills"

# ~/.codex/skills
rm -rf ~/.codex/skills
ln -s "$DOTFILES/skills" ~/.codex/skills && echo "✓ ~/.codex/skills"

# ~/.cursor/skills (symlink 버그 있으면 아래 주석 해제 후 sync.sh 사용)
ln -sf "$DOTFILES/skills" ~/.cursor/skills && echo "✓ ~/.cursor/skills"

# --- commands ---
rm -rf ~/.claude/commands
ln -s "$DOTFILES/commands" ~/.claude/commands && echo "✓ ~/.claude/commands"
ln -sf "$DOTFILES/commands" ~/.codex/prompts && echo "✓ ~/.codex/prompts"
ln -sf "$DOTFILES/commands" ~/.cursor/commands && echo "✓ ~/.cursor/commands"

# --- rules ---
mkdir -p ~/.cursor/rules
backup_and_link "$DOTFILES/rules/base.md" "$HOME/CLAUDE.md"
backup_and_link "$DOTFILES/rules/base.md" "$HOME/AGENTS.md"
backup_and_link "$DOTFILES/rules/base.md" "$HOME/.cursor/rules/base.mdc"

# --- mcp ---
if [ -f "$DOTFILES/mcp/secrets.json" ]; then
  "$DOTFILES/mcp/apply.sh"
else
  echo "⚠ mcp/secrets.json 없음 — MCP 설정 건너뜀"
fi

echo ""
echo "=== setup 완료 ==="
