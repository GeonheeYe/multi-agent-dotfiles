# multi-agent-dotfiles

Shared environment for Claude Code, Codex CLI, and Cursor — managed from a single repo with symlinks.

Fork this repo, fill in your info, run `setup.sh`. Done.

---

## Requirements

### Step 0 — Install an agent first

You need at least one AI agent installed. Claude Code is recommended as a starting point — it doesn't require git or python3 to install.

- [Claude Code](https://claude.ai/code) ← start here
- [Codex CLI](https://github.com/openai/codex)
- [Cursor](https://cursor.com)

You also need a [GitHub account](https://github.com/signup) to fork and save your dotfiles.

### Step 0.5 — Install git and python3

Once you have Claude Code or Codex running, say:

> "Install git and python3 on my machine if they're not already installed."

The agent will detect your OS and run the right commands for you.

---

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

Fork this repo on GitHub, then clone your fork:

```bash
git clone https://github.com/{YOUR_USERNAME}/multi-agent-dotfiles ~/dotfiles
cd ~/dotfiles
```

### 2. Fill in `rules/base.md`

This file becomes your `CLAUDE.md`, `AGENTS.md`, and Cursor rules — all in one.

Open Claude Code or Codex CLI from the `~/dotfiles` directory and say:

> "Fill in `~/dotfiles/rules/base.md` with my personal info. Ask me one question at a time."

The agent will ask for your name, role, preferred language, and working style — then write the file for you.

### 3. Set Up MCP (optional)

```bash
cd ~/dotfiles
cp mcp/secrets.json.example mcp/secrets.json
# Open mcp/secrets.json and fill in your tokens manually
```

> For MCP servers (Slack, Notion, etc.), connect them through each agent's own settings UI or follow each service's setup guide.

### 4. Run Setup

```bash
cd ~/dotfiles && ./setup.sh
```

Symlinks are created for whichever agents are installed. MCP config is deployed automatically if `secrets.json` exists.

### 5. Install Claude Code Plugins (optional)

```bash
claude plugin install superpowers@claude-plugins-official
```

### 6. Make Your Fork Private & Push

Your dotfiles contain personal info — keep them private. Go to your fork on GitHub:

**Settings → Danger Zone → Change repository visibility → Private**

Then push your changes:

> "Push my dotfiles changes to GitHub."

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
