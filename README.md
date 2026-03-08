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

### 2. Fill in `rules/base.md`

This file becomes your `CLAUDE.md`, `AGENTS.md`, and Cursor rules — all in one.

Open Claude Code or Codex CLI and say:

> "Fill in `~/dotfiles/rules/base.md` with my personal info. Ask me one question at a time."

The agent will ask for your name, role, preferred language, and working style — then write the file for you.

The template looks like this:

```markdown
## Who I Am
- {YOUR_NAME}. {YOUR_ROLE}
- Current focus: {YOUR_CURRENT_WORK}

## Communication Style
- {YOUR_LANGUAGE} preferred
...
```

### 3. Set Up MCP

Edit `mcp/servers.json` to define which MCP servers you want, then fill in your actual tokens in `mcp/secrets.json`:

```bash
cp mcp/secrets.json.example mcp/secrets.json
# Open mcp/secrets.json and fill in your tokens manually
```

> For the MCP servers themselves (Slack, Notion, Dooray, etc.), connect them through each agent's own settings UI or follow each service's setup guide.

### 4. Run Setup

```bash
cd ~/dotfiles && ./setup.sh
```

Symlinks are created. MCP config is deployed to all agents automatically.

### 5. Install Claude Code Plugins (optional)

```bash
claude plugin install superpowers@claude-plugins-official
```

### 6. Save to Your Private GitHub Repo

Keep your personal dotfiles in a private repo so you can sync across machines. Open Claude Code or Codex and say:

> "Create a private GitHub repo called `dotfiles` and push `~/dotfiles` to it."

---

Once all steps are done, **Claude Code, Codex CLI, and Cursor will share the exact same rules, skills, and commands** — no matter which agent you use or which machine you're on.

---

## Adding Skills

Skills are shared across all agents automatically.

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
# 1. Add server definition to mcp/servers.json
# 2. Add tokens to mcp/secrets.json
# 3. Apply to all agents
./mcp/apply.sh
# 4. Commit structure only (never commit secrets.json)
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
