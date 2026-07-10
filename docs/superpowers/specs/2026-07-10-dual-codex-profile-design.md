# Dual Codex Profile Design

## Goal

Keep work and personal Codex accounts isolated while sharing dotfiles-managed skills, prompts, and MCP definitions.

## Profile boundaries

- Work profile: `/Users/geonhee/.codex`
- Personal profile: `/Users/geonhee/.codex-personal-home/.codex`
- Shared skills: `/Users/geonhee/dotfiles/skills`
- Shared prompts: `/Users/geonhee/dotfiles/commands`

Authentication, sessions, and account-local state remain inside each profile. Only reusable configuration assets are shared.

## Commands

- `cdd` launches the work profile.
- `cdd-personal` launches the personal profile.
- `cdd-personal-login` authenticates the personal profile without mixing credentials with the work profile.

The command wrappers set `HOME` and `CODEX_HOME` explicitly for the selected profile.

## Setup and MCP behavior

`setup.sh` discovers the account home independently of the current `$HOME`, then configures both work and personal profiles. Both profiles receive symlinks to shared skills and prompts.

The MCP generator writes configured external MCP servers to both profiles. It must not emit an incomplete `[mcp_servers.codex_apps]` table: `codex_apps` is host-managed, and declaring only `startup_timeout_sec` causes Codex to reject the table because it has neither a stdio `command` nor an HTTP `url` transport.

## Verification

Tests verify that:

- both profiles link skills and prompts to dotfiles;
- work and personal commands select distinct `CODEX_HOME` values;
- generated config contains external MCP servers but no standalone `codex_apps` table;
- setup works even when invoked from the personal profile's `$HOME`.
