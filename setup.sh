#!/bin/bash
# setup.sh — Run once on a new machine to create all symlinks
set -e

DOTFILES="$HOME/dotfiles"

echo "=== dotfiles setup ==="

# --- skills ---
backup_and_link() {
  local target="$1"
  local link="$2"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "backup: $link → $link.bak"
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
  echo "⚠ mcp/secrets.json not found — skipping MCP setup"
fi

echo ""
echo "=== setup complete ==="
