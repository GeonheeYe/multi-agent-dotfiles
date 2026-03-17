#!/bin/bash
# setup.sh — Run once on a new machine to create all symlinks
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "=== dotfiles setup ==="

# Clean up self-referencing circular symlinks (directory pointing to itself)
for dir in "$DOTFILES/commands" "$DOTFILES/skills"; do
  dir_name=$(basename "$dir")
  self_link="$dir/$dir_name"
  if [ -L "$self_link" ]; then
    link_target=$(readlink "$self_link")
    if [ "$link_target" = "$dir" ] || [ "$link_target" = "$(realpath "$dir" 2>/dev/null)" ]; then
      rm "$self_link" && echo "✓ removed circular symlink: $self_link"
    fi
  fi
done

backup_and_link() {
  local target="$1"
  local link="$2"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "backup: $link → $link.bak"
    mv "$link" "$link.bak"
  fi
  ln -sf "$target" "$link" && echo "✓ $link"
}

preserve_codex_system_skills() {
  local source_dir="$HOME/.codex/skills/.system"
  local target_dir="$DOTFILES/skills/.system"
  if [ -d "$source_dir" ] && [ ! -e "$target_dir" ]; then
    mkdir -p "$DOTFILES/skills"
    cp -a "$source_dir" "$target_dir"
    echo "✓ preserved Codex system skills in dotfiles"
  fi
}

preserve_codex_system_skills

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
    # skip "skills" to avoid self-referencing symlink
    [ "$skill_name" = "skills" ] && continue
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

# --- shell aliases (auto-pull dotfiles on claude/codex startup) ---
SOURCE_LINE="source \"$DOTFILES/shell/aliases.sh\""
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
  SHELL_RC="$HOME/.zshrc"
else
  SHELL_RC="$HOME/.bashrc"
fi
if [ -f "$SHELL_RC" ] && ! grep -qF "aliases.sh" "$SHELL_RC"; then
  echo "" >> "$SHELL_RC"
  echo "# dotfiles aliases" >> "$SHELL_RC"
  echo "$SOURCE_LINE" >> "$SHELL_RC"
  echo "✓ added aliases.sh source to $SHELL_RC"
else
  echo "✓ shell aliases already configured"
fi

# --- Claude SessionStart hook (auto-pull dotfiles) ---
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ] && ! grep -qF "ff-only" "$CLAUDE_SETTINGS"; then
  python3 - <<'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
dotfiles = os.path.expanduser("~/dotfiles")

with open(settings_path) as f:
    s = json.load(f)

pull_hook = {"type": "command", "command": f"git -C {dotfiles} pull --ff-only --quiet 2>/dev/null || true"}
hooks = s.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [{"hooks": []}])
existing = session_start[0]["hooks"]

if not any("ff-only" in h.get("command", "") for h in existing):
    existing.insert(0, pull_hook)

with open(settings_path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("✓ Claude SessionStart hook added")
PYEOF
else
  echo "✓ Claude SessionStart hook already configured"
fi

echo ""
echo "=== setup complete ==="
