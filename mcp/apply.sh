#!/bin/bash
# mcp/apply.sh — secrets.json의 값을 servers.json에 주입해서 각 에이전트에 적용
# 대상: ~/.claude.json (Claude Code), ~/.codex/config.toml (Codex CLI), ~/.cursor/mcp.json (Cursor)

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$DOTFILES/mcp/secrets.json"
SERVERS="$DOTFILES/mcp/servers.json"
TARGET_HOME="${MCP_TARGET_HOME:-$(cd "$DOTFILES/.." && pwd)}"
CLAUDE_JSON="$TARGET_HOME/.claude.json"
CODEX_TOML="$TARGET_HOME/.codex/config.toml"

if [ ! -f "$SECRETS" ]; then
  echo "❌ mcp/secrets.json 없음 — secrets.json.example 참고해서 만들어주세요"
  exit 1
fi

echo "MCP 설정 적용 중..."

python3 - <<EOF
import json
import os

with open('$SECRETS') as f:
    secrets = json.load(f)

default_dooray_path = os.path.join('$DOTFILES', 'mcp', 'dooray-mcp', 'dist', 'index.js')
if not secrets.get('DOORAY_MCP_PATH') or not os.path.exists(secrets['DOORAY_MCP_PATH']):
    secrets['DOORAY_MCP_PATH'] = default_dooray_path

with open('$SERVERS') as f:
    servers_str = f.read()

# \${VAR} 치환
for key, val in secrets.items():
    servers_str = servers_str.replace('\${' + key + '}', val)

servers = json.loads(servers_str)

# --- Claude Code: ~/.claude.json ---
claude_path = '$CLAUDE_JSON'
if os.path.exists(claude_path):
    with open(claude_path) as f:
        claude = json.load(f)
else:
    claude = {}

claude['mcpServers'] = servers['mcpServers']

with open(claude_path, 'w') as f:
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
def toml_escape(value):
    slash = chr(92)
    quote = chr(34)
    return value.replace(slash, slash * 2).replace(quote, slash + quote)

for name, cfg in servers['mcpServers'].items():
    mcp_toml += f'\n[mcp_servers.{name}]\n'
    if cfg.get('url'):
        mcp_toml += f'url = "{toml_escape(cfg["url"])}"\n'
    else:
        mcp_toml += f'command = "{toml_escape(cfg["command"])}"\n'
    if cfg.get('args'):
        args_str = ', '.join(f'"{toml_escape(a)}"' for a in cfg['args'])
        mcp_toml += f'args = [{args_str}]\n'
    if cfg.get('headers'):
        header_str = ', '.join(
            f'"{toml_escape(str(k))}" = "{toml_escape(str(v))}"'
            for k, v in cfg['headers'].items()
        )
        mcp_toml += f'http_headers = {{ {header_str} }}\n'
    if cfg.get('env'):
        mcp_toml += f'\n[mcp_servers.{name}.env]\n'
        for k, v in cfg['env'].items():
            mcp_toml += f'{k} = "{toml_escape(v)}"\n'

# Codex가 내부 등록하는 MCP 서버에는 Codex 전용 옵션만 덮어쓴다.
for name, cfg in servers.get('codexMcpServerOverrides', {}).items():
    mcp_toml += f'\n[mcp_servers.{name}]\n'
    if cfg.get('startup_timeout_sec') is not None:
        mcp_toml += f'startup_timeout_sec = {int(cfg["startup_timeout_sec"])}\n'

with open(toml_path, 'w') as f:
    f.write(base_toml + mcp_toml)

print("✓ ~/.codex/config.toml 업데이트 완료")

# --- Cursor: ~/.cursor/mcp.json ---
cursor_mcp_path = os.path.join('$TARGET_HOME', '.cursor', 'mcp.json')
if os.path.exists(os.path.dirname(cursor_mcp_path)):
    if os.path.exists(cursor_mcp_path):
        with open(cursor_mcp_path) as f:
            cursor = json.load(f)
    else:
        cursor = {}
    cursor['mcpServers'] = servers['mcpServers']
    with open(cursor_mcp_path, 'w') as f:
        json.dump(cursor, f, indent=2, ensure_ascii=False)
    print("✓ ~/.cursor/mcp.json 업데이트 완료")

print("  서버:", list(servers['mcpServers'].keys()))
EOF
