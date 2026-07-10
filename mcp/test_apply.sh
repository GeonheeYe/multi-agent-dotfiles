#!/bin/bash
set -euo pipefail

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
mkdir -p "$tmp_home/.codex"

MCP_TARGET_HOME="$tmp_home" "$(dirname "$0")/apply.sh" >/dev/null

grep -Fq '[mcp_servers.codex_apps]' "$tmp_home/.codex/config.toml"
grep -Fq 'startup_timeout_sec = 120' "$tmp_home/.codex/config.toml"
