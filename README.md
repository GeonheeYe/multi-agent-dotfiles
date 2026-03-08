# multi-agent-dotfiles

Shared environment for Claude Code, Codex CLI, and Cursor — managed from a single repo with symlinks.

Fork this repo, fill in your info, run `setup.sh`. Done.

## Structure

```
dotfiles/
├── rules/
│   └── base.md          # Your identity & rules → CLAUDE.md / AGENTS.md / .cursor/rules/base.mdc
├── skills/              # SKILL.md-based skills (shared across all agents)
├── commands/            # Slash command prompts
├── mcp/
│   ├── servers.json     # MCP server definitions (uses ${ENV_VAR} placeholders)
│   ├── secrets.json     # Your actual tokens — never committed (gitignored)
│   ├── secrets.json.example
│   └── apply.sh         # Injects secrets and deploys to each agent
└── setup.sh             # Run once on a new machine
```

## Agent Mapping

| Item | Claude Code | Codex CLI | Cursor |
|------|------------|-----------|--------|
| rules | `~/CLAUDE.md` | `~/AGENTS.md` | `~/.cursor/rules/base.mdc` |
| skills | `~/.claude/skills/` | `~/.codex/skills/` | `~/.cursor/skills/` |
| commands | `~/.claude/commands/` | `~/.codex/prompts/` | `~/.cursor/commands/` |
| MCP | `~/.claude.json` | `~/.codex/config.toml` | — |

---

## Quick Start

### 1. Fork & Clone

```bash
# Fork this repo on GitHub first, then:
git clone https://github.com/{YOUR_USERNAME}/dotfiles ~/dotfiles
```

### 2. Edit `rules/base.md`

This file becomes your `CLAUDE.md`, `AGENTS.md`, and Cursor rules — all in one.

```markdown
# CLAUDE.md

## Who I Am
- {YOUR_NAME}. {YOUR_ROLE}
- Current focus: {YOUR_CURRENT_WORK}

## Communication Style
- {YOUR_LANGUAGE} preferred
- Explain the "why" behind decisions briefly
- Break tasks into steps, confirm one at a time
- When unclear, ask with AskUserQuestion tool — never assume

## Code Style
- Practical first: working code over perfect code
- Avoid unnecessary abstractions
- Use clear, meaningful variable and function names

## Response Style
- Keep it short and clear: only what's needed
- One line explanation before showing code
- Ask one question at a time via AskUserQuestion

## Rules
- No auto git commit/push — only when explicitly asked
- No unrequested refactoring — stay within scope
- No guessing — always ask when ambiguous

## Environment
- MCP servers: edit ~/dotfiles/mcp/servers.json → run ./mcp/apply.sh
- New skills: add to ~/dotfiles/skills/ (auto-synced to Claude Code, Codex, Cursor)
```

### 3. Set Up MCP Secrets

```bash
cp mcp/secrets.json.example mcp/secrets.json
# Edit mcp/secrets.json with your actual tokens
```

### 4. Run Setup

```bash
cd ~/dotfiles && ./setup.sh
```

Symlinks are created. MCP config is deployed to all agents.

### 5. Install Claude Code Plugins (optional)

```bash
claude plugin install superpowers@claude-plugins-official
claude plugin install clarify@team-attention-plugins
```

---

## Adding Skills

Skills are shared across Claude Code, Codex CLI, and Cursor automatically.

```bash
mkdir ~/dotfiles/skills/my-skill
cat > ~/dotfiles/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
---

Skill instructions here.
EOF

git add . && git commit -m "feat: add my-skill" && git push
```

## Adding MCP Servers

```bash
# 1. Add server to mcp/servers.json
# 2. Add tokens to mcp/secrets.json
# 3. Apply
./mcp/apply.sh
# 4. Commit servers.json (not secrets.json)
git add mcp/servers.json && git commit -m "feat: add new MCP server"
```

## Syncing Across Machines

```bash
git pull
./mcp/apply.sh   # only if MCP config changed
```

---

## Requirements

- git
- python3
- [Claude Code](https://claude.ai/code) — optional
- [Codex CLI](https://github.com/openai/codex) — optional
- [Cursor](https://cursor.com) — optional
