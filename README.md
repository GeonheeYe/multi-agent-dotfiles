# multi-agent-dotfiles

[![GitHub stars](https://img.shields.io/github/stars/GeonheeYe/multi-agent-dotfiles?style=flat-square)](https://github.com/GeonheeYe/multi-agent-dotfiles/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

**One repo. Claude Code, Codex CLI, and Cursor all share the same rules, skills, and commands.**

No more re-configuring each tool separately. Change something once — it applies everywhere.

---

## The Problem

You're using multiple AI coding agents: Claude Code for chat, Codex CLI in the terminal, Cursor in your editor. But each one has its own config files, its own skills directory, its own rules. Every time you add a skill or update a rule, you have to do it three times. On a new machine, you start from scratch.

## The Solution

This repo holds everything in one place. `setup.sh` creates symlinks so each agent reads from the same source. Push a change, pull it on another machine, run `setup.sh` — done.

```
dotfiles/
├── rules/base.md    → CLAUDE.md, AGENTS.md, .cursor/rules/base.mdc
├── skills/          → ~/.claude/skills/, ~/.codex/skills/, ~/.cursor/skills/
├── commands/        → ~/.claude/commands/, ~/.codex/prompts/, ~/.cursor/commands/
└── mcp/             → ~/.claude.json, ~/.codex/config.toml, ~/.cursor/mcp.json
```

---

## Just tell your agent

Already have Claude Code, Codex, or Cursor installed? Just say this:

> "Set up my dotfiles using https://github.com/GeonheeYe/multi-agent-dotfiles as a template. Follow the README."

The agent will handle the rest.

---

## Requirements

- A [GitHub account](https://github.com/signup)
- At least one agent installed: [Claude Code](https://claude.ai/code) · [Codex CLI](https://github.com/openai/codex) · [Cursor](https://cursor.com)
- **Linux or macOS** — Windows users must use WSL (see below)

### Windows: Install WSL

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

This installs Ubuntu by default. Restart your machine, then follow the rest of this guide inside the WSL terminal.

---

## Quick Start

### 1. Install an agent

Install at least one agent, then open it and say:

> "Install git, python3, and gh CLI on my machine if not already installed. Then authenticate gh CLI with GitHub."

**Verify:** `git --version && gh auth status`

### 2. Create your private dotfiles repo

Say to your agent:

> "Create a private GitHub repo called `dotfiles` from the `GeonheeYe/multi-agent-dotfiles` template and clone it to `~/dotfiles`."

**Verify:** `ls ~/dotfiles`

### 3. Fill in `rules/base.md`

This file becomes your `CLAUDE.md`, `AGENTS.md`, and Cursor rules — all in one. Say:

> "Fill in `~/dotfiles/rules/base.md` with my personal info. Ask me one question at a time."

### 4. Set Up MCP (optional)

```bash
cd ~/dotfiles
cp mcp/servers.json.example mcp/servers.json
cp mcp/secrets.json.example mcp/secrets.json
# Edit both files with your MCP server config and tokens
```

> For MCP servers (Slack, Notion, etc.), connect them through each agent's own settings UI or follow each service's setup guide.

### 5. Run Setup

```bash
cd ~/dotfiles && ./setup.sh
```

**Verify:** `ls ~/.claude/skills/ && ls ~/.claude/commands/`

Symlinks are created for whichever agents are installed. MCP config is deployed automatically if `secrets.json` exists.

### 6. Install Plugins / Skills (optional)

> **What is `superpowers`?**
> A plugin that adds structured workflow skills — `brainstorming`, `writing-plans`, `systematic-debugging`, `test-driven-development`, and more. These guide the agent through consistent, step-by-step processes. Highly recommended.

#### Claude Code

Claude Code manages skills through its plugin system.

**Option 1 — Natural language:**
> "Install the superpowers plugin, then run `~/dotfiles/setup.sh`."

**Option 2 — `/plugin` command:**
Type `/plugin` in the chat to open the plugin browser and install from the marketplace.

**Option 3 — CLI:**
```bash
claude plugin install superpowers@claude-plugins-official
./setup.sh   # syncs plugin skills to Codex and Cursor
```

**Verify:** Type `/` in the chat — you should see skills listed.

#### Codex CLI

Codex CLI has no plugin system, but you can install skills via natural language:

> "Add the superpowers skills to `~/dotfiles/skills/` from `~/.claude/plugins/cache/`, then run `~/dotfiles/setup.sh`."

Or if Claude Code is not installed:

> "Clone the superpowers skills from `https://github.com/anthropics/claude-plugins-official` and add them to `~/dotfiles/skills/`, then run `~/dotfiles/setup.sh`."

**Verify:** `ls ~/.codex/skills/`

### 7. Push your changes

```bash
cd ~/dotfiles && git add . && git push
```

---

Once all steps are done, **Claude Code, Codex CLI, and Cursor will share the exact same rules, skills, and commands** — no matter which agent you use or which machine you're on.

---

## Agent Mapping

| Item | Claude Code | Codex CLI | Cursor |
|------|------------|-----------|--------|
| rules | `~/CLAUDE.md` | `~/AGENTS.md` | `~/.cursor/rules/base.mdc` |
| skills | `~/.claude/skills/` | `~/.codex/skills/` | `~/.cursor/skills/` |
| commands | `~/.claude/commands/` | `~/.codex/prompts/` | `~/.cursor/commands/` |
| MCP | `~/.claude.json` | `~/.codex/config.toml` | `~/.cursor/mcp.json` |

---

## Memory (Personal, Not Committed)

The `memory/` directory is gitignored — it stores personal data that should not be shared publicly.

The main use case is a **questions bank** (`memory/questions.json`) that saves key Q&A from your sessions for later review. Use the `/save-q` command (in `commands/`) to add entries from any agent.

```
memory/
└── questions.json    # Personal Q&A learning records — gitignored
```

> This directory exists locally on each machine but is never pushed to GitHub. Back it up separately if needed.

---

## Adding Skills

Skills are shared across all agents automatically.

> **Path convention:** Always use `~` or `$HOME` for home directory paths in skills, commands, and scripts — never hardcode absolute paths like `/Users/yourname/` or `/home/yourname/`. This keeps your dotfiles portable across machines and users.

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

## Troubleshooting

### Skills not showing in Cursor

Cursor has a known bug where it may not follow symlinks to discover skills. If your skills don't appear in Cursor, copy them manually instead:

```bash
rsync -av ~/dotfiles/skills/ ~/.cursor/skills/
```

Run this whenever you add new skills. Then restart Cursor.

### skills/ and commands/ are empty after setup

The template ships with empty `skills/` and `commands/` directories by design — they're yours to fill. To get started quickly, install the `superpowers` plugin (see Step 6) which adds skills like `brainstorming`, `writing-plans`, and more. After installing, run `./setup.sh` again to sync them.

---

If this saves you time, consider giving it a star ⭐
