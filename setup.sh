#!/bin/bash
# setup.sh — Run once on a new machine to create all symlinks
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "=== dotfiles setup ==="

backup_and_link() {
  local target="$1"
  local link="$2"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "backup: $link → $link.bak"
    mv "$link" "$link.bak"
  fi
  ln -sf "$target" "$link" && echo "✓ $link"
}

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
  ln -sf "$DOTFILES/skills" ~/.cursor/skills && echo "✓ ~/.cursor/skills"
fi

# --- commands ---
if [ -d "$HOME/.claude" ]; then
  rm -rf ~/.claude/commands
  ln -s "$DOTFILES/commands" ~/.claude/commands && echo "✓ ~/.claude/commands"
fi

if [ -d "$HOME/.codex" ]; then
  ln -sf "$DOTFILES/commands" ~/.codex/prompts && echo "✓ ~/.codex/prompts"
fi

if [ -d "$HOME/.cursor" ]; then
  ln -sf "$DOTFILES/commands" ~/.cursor/commands && echo "✓ ~/.cursor/commands"
fi

# --- rules ---
backup_and_link "$DOTFILES/rules/base.md" "$HOME/CLAUDE.md"
backup_and_link "$DOTFILES/rules/base.md" "$HOME/AGENTS.md"

if [ -d "$HOME/.cursor" ]; then
  mkdir -p ~/.cursor/rules
  backup_and_link "$DOTFILES/rules/base.md" "$HOME/.cursor/rules/base.mdc"
fi

# --- sync Claude Code plugin skills to dotfiles/skills ---
# Makes plugin skills (e.g. superpowers/brainstorming) available in Codex and Cursor too
if [ -d "$HOME/.claude/plugins/cache" ]; then
  echo "Syncing plugin skills..."
  find "$HOME/.claude/plugins/cache" -path "*/skills/*/SKILL.md" | while read skill_md; do
    skill_dir=$(dirname "$skill_md")
    skill_name=$(basename "$skill_dir")
    target="$DOTFILES/skills/$skill_name"
    if [ ! -e "$target" ]; then
      ln -sf "$skill_dir" "$target" && echo "✓ plugin skill: $skill_name"
    fi
  done
fi

# --- mcp ---
if [ -f "$DOTFILES/mcp/secrets.json" ]; then
  "$DOTFILES/mcp/apply.sh"
else
  echo "⚠ mcp/secrets.json not found — skipping MCP setup"
fi

echo ""
echo "=== setup complete ==="
