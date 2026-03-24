# multi-agent-dotfiles

**One repo. Claude Code, Codex CLI, and Cursor all share the same rules, skills, commands, and MCP config.**

No more re-configuring each tool separately. Change something once — it applies everywhere.

---

## Just Tell Your Agent

Already have Claude Code, Codex, or Cursor installed? Just say:

> "Set up my dotfiles using https://github.com/GeonheeYe/multi-agent-dotfiles as a template. Follow the README."

The agent will handle the rest.

---

## Prerequisites

- **git**
- **node** >= 18
- **python3**
- At least one agent installed: [Claude Code](https://claude.ai/code) · [Codex CLI](https://github.com/openai/codex) · [Cursor](https://cursor.com)
- **Windows users:** WSL required (`wsl --install` in PowerShell as Administrator)

## Quick Setup

```bash
git clone https://github.com/GeonheeYe/multi-agent-dotfiles.git ~/dotfiles
cd ~/dotfiles
cp mcp/secrets.json.example mcp/secrets.json
# Edit mcp/secrets.json with your API tokens
./setup.sh
```

That's it. `setup.sh` handles everything:

- Creates symlinks for all three agents (skills, commands, rules)
- Syncs Claude Code plugin skills to dotfiles (available in Codex/Cursor too)
- Deploys MCP server config to each agent
- Registers SessionStart hook for auto-sync on every session
- Adds shell aliases to `.zshrc` / `.bashrc`

---

## What Gets Linked

```
dotfiles/
├── rules/base.md    → CLAUDE.md, AGENTS.md, .cursor/rules/base.mdc
├── skills/          → ~/.claude/skills/, ~/.codex/skills/, ~/.cursor/skills/
├── commands/        → ~/.claude/commands/, ~/.codex/prompts/, ~/.cursor/commands/
└── mcp/             → ~/.claude.json, ~/.codex/config.toml, ~/.cursor/mcp.json
```

| Item | Claude Code | Codex CLI | Cursor |
|------|------------|-----------|--------|
| Rules | `~/CLAUDE.md` | `~/AGENTS.md` | `~/.cursor/rules/base.mdc` |
| Skills | `~/.claude/skills/` | `~/.codex/skills/` | `~/.cursor/skills/` |
| Commands | `~/.claude/commands/` | `~/.codex/prompts/` | `~/.cursor/commands/` |
| MCP | `~/.claude.json` | `~/.codex/config.toml` | `~/.cursor/mcp.json` |

---

## Included Skills (18)

These skills are ready to use out of the box:

| Skill | Description |
|-------|-------------|
| brainstorming | Turn ideas into fully formed designs through collaborative dialogue |
| writing-plans | Create detailed, step-by-step implementation plans |
| writing-skills | Guide for creating and testing new skills |
| executing-plans | Execute implementation plans with review checkpoints |
| subagent-driven-development | Parallelize implementation with independent subagents |
| dispatching-parallel-agents | Coordinate 2+ independent tasks in parallel |
| test-driven-development | Red-green-refactor TDD workflow |
| systematic-debugging | Root cause analysis with structured debugging |
| using-git-worktrees | Isolated feature work with git worktrees |
| finishing-a-development-branch | Merge, PR, or cleanup when implementation is done |
| requesting-code-review | Structure and submit code for review |
| receiving-code-review | Handle review feedback with technical rigor |
| verification-before-completion | Run verification before claiming work is done |
| find-skills | Discover and install new skills |
| using-superpowers | Guide for using plugin skills effectively |
| unknown | Surface hidden assumptions with Known/Unknown 4-quadrant analysis |
| vague | Turn ambiguous requirements into concrete specs |
| metamedium | Reframe problems by changing form, not just content |

---

## Shell Aliases

After setup, these aliases are available in your terminal:

| Alias | Description |
|-------|-------------|
| `cc` | Claude Code (auto-sync dotfiles before/after) |
| `ccd` | Claude Code (skip permission checks) |
| `ccr` | Claude Code (resume previous session) |
| `cdd` | Codex CLI (bypass approvals and sandbox) |
| `cu` | Cursor CLI |

Each alias automatically pulls latest dotfiles before running and pushes changes after.

---

## Auto-Sync

Your dotfiles stay in sync automatically:

- **On session start:** Claude Code's SessionStart hook runs `sync-dotfiles.sh` (pulls latest changes)
- **On alias use:** `cc` / `ccd` / `ccr` / `cdd` / `cu` pull before and push after each session
- **`scripts/sync-dotfiles.sh`:** auto-commit local changes + `pull --rebase` + re-run setup if HEAD changed
- **`scripts/push-dotfiles.sh`:** auto-commit + `pull --rebase` + push to remote

### Syncing across machines

```bash
cd ~/dotfiles
git pull && ./setup.sh    # only needed if setup.sh itself changed
```

---

## Customization

### Fill in your rules

Edit `rules/base.md` with your personal info — it becomes your `CLAUDE.md`, `AGENTS.md`, and Cursor rules all at once.

### Add a skill

Create `skills/my-skill/SKILL.md` — instantly available in all three agents.

```bash
mkdir ~/dotfiles/skills/my-skill
cat > ~/dotfiles/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
---

Skill instructions here.
EOF
```

### Add an MCP server

1. Copy `mcp/servers.json.example` to `mcp/servers.json` (if not already done)
2. Add your server definition to `mcp/servers.json`
3. Add tokens to `mcp/secrets.json`
4. Run `./mcp/apply.sh`

The example ships with a **Notion MCP** configuration:

```jsonc
// mcp/servers.json
{
  "mcpServers": {
    "notionApi": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "NOTION_TOKEN": "${NOTION_TOKEN}"
      }
    }
  }
}
```

References:
- Notion MCP docs: https://developers.notion.com/docs/mcp
- Official server: https://github.com/makenotion/notion-mcp-server

### Install more skills via plugins

Claude Code's plugin system can add more skills:

```bash
claude plugin install superpowers@claude-plugins-official
./setup.sh   # syncs plugin skills to Codex and Cursor
```

---

## Memory (Personal, Not Committed)

The `memory/` directory is gitignored — use it for personal data that shouldn't be shared.

---

## Troubleshooting

- **Windows:** WSL required. Run `wsl --install` in PowerShell as Administrator.
- **Cursor skills not showing:** Cursor may not follow symlinks. Copy manually: `rsync -av ~/dotfiles/skills/ ~/.cursor/skills/`
- **Paths:** Always use `~` or `$HOME`, never hardcode absolute paths.
- **MCP not working:** Check that `mcp/secrets.json` exists and has valid tokens.
- **SessionStart hook not firing:** Re-run `./setup.sh` to register the hook.

---

## License

MIT

---

If this saves you time, consider giving it a star.
