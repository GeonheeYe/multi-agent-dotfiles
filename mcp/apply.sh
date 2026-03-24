#!/bin/bash
# mcp/apply.sh — Inject secrets.json values into servers.json and deploy to each agent
# Targets: ~/.claude.json (Claude Code), ~/.codex/config.toml (Codex CLI), ~/.cursor/mcp.json (Cursor)

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$DOTFILES/mcp/secrets.json"
SERVERS="$DOTFILES/mcp/servers.json"
CLAUDE_JSON="$HOME/.claude.json"
CODEX_TOML="$HOME/.codex/config.toml"

if [ ! -f "$SECRETS" ]; then
  echo "ERROR: mcp/secrets.json not found — copy secrets.json.example and fill in your tokens"
  exit 1
fi

echo "Applying MCP configuration..."

python3 - <<EOF
import json, os, re

with open('$SECRETS') as f:
    secrets = json.load(f)

with open('$SERVERS') as f:
    servers_str = f.read()

# Replace \${VAR} placeholders with secret values
for key, val in secrets.items():
    servers_str = servers_str.replace('\${' + key + '}', val)

servers = json.loads(servers_str)

# --- Claude Code: ~/.claude.json ---
if os.path.exists('$CLAUDE_JSON'):
    with open('$CLAUDE_JSON') as f:
        claude = json.load(f)
    claude['mcpServers'] = servers['mcpServers']
    with open('$CLAUDE_JSON', 'w') as f:
        json.dump(claude, f, indent=2, ensure_ascii=False)
    print("✓ ~/.claude.json updated")
else:
    print("↷ ~/.claude.json not found — skipping Claude Code")

# --- Codex CLI: ~/.codex/config.toml ---

# Read existing config.toml (replace only mcp_servers section)
toml_path = '$CODEX_TOML'
if os.path.exists(toml_path):
    with open(toml_path) as f:
        lines = f.readlines()
    # Remove existing mcp_servers section
    new_lines = []
    skip = False
    for line in lines:
        if line.strip().startswith('[mcp_servers'):
            skip = True
        elif skip and line.strip().startswith('[') and not line.strip().startswith('[mcp_servers'):
            skip = False
        if not skip:
            new_lines.append(line)
    base_toml = ''.join(new_lines).rstrip() + '\n'
else:
    base_toml = ''

# Build mcp_servers section
mcp_toml = ''
for name, cfg in servers['mcpServers'].items():
    mcp_toml += f'\n[mcp_servers.{name}]\n'
    mcp_toml += f'command = "{cfg["command"]}"\n'
    if cfg.get('args'):
        args_str = ', '.join(f'"{a}"' for a in cfg['args'])
        mcp_toml += f'args = [{args_str}]\n'
    if cfg.get('env'):
        mcp_toml += f'\n[mcp_servers.{name}.env]\n'
        for k, v in cfg['env'].items():
            mcp_toml += f'{k} = "{v}"\n'

with open(toml_path, 'w') as f:
    f.write(base_toml + mcp_toml)

print("✓ ~/.codex/config.toml updated")

# --- Cursor: ~/.cursor/mcp.json ---
cursor_mcp_path = os.path.expanduser('~/.cursor/mcp.json')
if os.path.exists(os.path.dirname(cursor_mcp_path)):
    if os.path.exists(cursor_mcp_path):
        with open(cursor_mcp_path) as f:
            cursor = json.load(f)
    else:
        cursor = {}
    cursor['mcpServers'] = servers['mcpServers']
    with open(cursor_mcp_path, 'w') as f:
        json.dump(cursor, f, indent=2, ensure_ascii=False)
    print("✓ ~/.cursor/mcp.json updated")

print("  servers:", list(servers['mcpServers'].keys()))
EOF
