#!/bin/bash
# mcp/apply.sh — secrets.json의 값을 servers.json에 주입해서 각 에이전트에 적용
# 대상: ~/.claude.json (Claude Code), ~/.codex/config.toml (Codex CLI)

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$DOTFILES/mcp/secrets.json"
SERVERS="$DOTFILES/mcp/servers.json"
CLAUDE_JSON="$HOME/.claude.json"
CODEX_TOML="$HOME/.codex/config.toml"

if [ ! -f "$SECRETS" ]; then
  echo "❌ mcp/secrets.json 없음 — secrets.json.example 참고해서 만들어주세요"
  exit 1
fi

echo "MCP 설정 적용 중..."

python3 - <<EOF
import json, re

with open('$SECRETS') as f:
    secrets = json.load(f)

with open('$SERVERS') as f:
    servers_str = f.read()

# \${VAR} 치환
for key, val in secrets.items():
    servers_str = servers_str.replace('\${' + key + '}', val)

servers = json.loads(servers_str)

# --- Claude Code: ~/.claude.json ---
with open('$CLAUDE_JSON') as f:
    claude = json.load(f)

claude['mcpServers'] = servers['mcpServers']

with open('$CLAUDE_JSON', 'w') as f:
    json.dump(claude, f, indent=2, ensure_ascii=False)

print("✓ ~/.claude.json 업데이트 완료")

# --- Codex CLI: ~/.codex/config.toml ---
import os

# 기존 config.toml 읽기 (mcp_servers 섹션만 교체)
toml_path = '$CODEX_TOML'
if os.path.exists(toml_path):
    with open(toml_path) as f:
        lines = f.readlines()
    # mcp_servers 섹션 제거
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

# mcp_servers 섹션 추가
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

print("✓ ~/.codex/config.toml 업데이트 완료")
print("  서버:", list(servers['mcpServers'].keys()))
EOF
