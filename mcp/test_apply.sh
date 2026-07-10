#!/bin/bash
set -euo pipefail

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
mkdir -p "$tmp_home/.codex"

MCP_TARGET_HOME="$tmp_home" "$(dirname "$0")/apply.sh" >/dev/null

if grep -Fq '[mcp_servers.codex_apps]' "$tmp_home/.codex/config.toml"; then
  echo "FAIL: host-managed codex_apps must not be emitted as a standalone MCP server" >&2
  exit 1
fi

grep -Fq '[mcp_servers.dooray]' "$tmp_home/.codex/config.toml"
grep -Fq 'command = "node"' "$tmp_home/.codex/config.toml"
