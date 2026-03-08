# multi-agent-dotfiles

Shared environment for Claude Code, Codex CLI, and Cursor — managed from a single repo with symlinks.

---

## Requirements

- A [GitHub account](https://github.com/signup)
- At least one agent installed: [Claude Code](https://claude.ai/code) · [Codex CLI](https://github.com/openai/codex) · [Cursor](https://cursor.com)

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

### 1. Install an agent

Install at least one agent, then open it and say:

> "Install git, python3, and gh CLI on my machine if not already installed. Then authenticate gh CLI with GitHub."

### 2. Create your private dotfiles repo

Say to your agent:

> "Create a private GitHub repo called `dotfiles` from the `GeonheeYe/multi-agent-dotfiles` template and clone it to `~/dotfiles`."

### 3. Fill in `rules/base.md`

This file becomes your `CLAUDE.md`, `AGENTS.md`, and Cursor rules — all in one. Say:

> "Fill in `~/dotfiles/rules/base.md` with my personal info. Ask me one question at a time."

### 4. Set Up MCP (optional)

```bash
cd ~/dotfiles
cp mcp/secrets.json.example mcp/secrets.json
# Open mcp/secrets.json and fill in your tokens manually
```

> For MCP servers (Slack, Notion, etc.), connect them through each agent's own settings UI or follow each service's setup guide.

### 5. Run Setup

```bash
cd ~/dotfiles && ./setup.sh
```

Symlinks are created for whichever agents are installed. MCP config is deployed automatically if `secrets.json` exists.

### 6. Install Plugins (optional)

Plugins are packages of skills, commands, and workflows. In **Claude Code**, they are managed through the plugin system. In **Codex CLI**, plugins are not natively supported — but thanks to `setup.sh`, any skills inside a Claude Code plugin are automatically extracted and added to Codex as regular skills.

Say to your agent:

> "Install the superpowers plugin for Claude Code, then run `~/dotfiles/setup.sh`."

> **What is superpowers?**
> `superpowers` adds structured workflow skills — `brainstorming`, `writing-plans`, `systematic-debugging`, `test-driven-development`, and more. These skills guide the agent through consistent, step-by-step processes for complex tasks. Highly recommended.
>
> In Claude Code, use `/plugin` in the chat to browse and install more plugins.
> In Codex CLI, installed plugin skills are available automatically after running `./setup.sh`.

### 7. Push your changes

```bash
cd ~/dotfiles && git add . && git push
```

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
