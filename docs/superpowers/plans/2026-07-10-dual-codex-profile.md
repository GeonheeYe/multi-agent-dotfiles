# Dual Codex Profile Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep work and personal Codex account state separate while sharing dotfiles skills, prompts, and valid MCP configuration.

**Architecture:** Resolve the real account home independently from the active profile home. Configure work and personal `CODEX_HOME` directories explicitly, link only reusable assets, and generate external MCP entries for both profiles without redefining host-managed `codex_apps`.

**Tech Stack:** Bash, Python configuration generator, TOML, shell regression tests

---

### Task 1: MCP regression

**Files:**
- Modify: `mcp/test_apply.sh`
- Modify: `mcp/servers.json`
- Modify: `mcp/apply.sh`

- [ ] Add a failing test that rejects generated `[mcp_servers.codex_apps]` and verifies both target profiles.
- [ ] Run the test and confirm it fails on the incomplete transport definition.
- [ ] Remove the unsupported `codexMcpServerOverrides` generator and data.
- [ ] Generate MCP configuration for both explicit profile homes.
- [ ] Run the MCP test and confirm it passes.

### Task 2: Dual-profile setup

**Files:**
- Modify: `tests/dotfiles-auto-sync-test.sh`
- Modify: `setup.sh`

- [ ] Add a failing setup test invoked with personal `$HOME` that expects shared links in both profiles.
- [ ] Run the test and confirm it fails.
- [ ] Resolve the account home and create skills/prompts links in work and personal profiles.
- [ ] Apply common MCP configuration to both profiles.
- [ ] Run the setup test and confirm it passes.

### Task 3: Command aliases

**Files:**
- Modify: `tests/aliases-test.sh`
- Modify: `shell/aliases.sh`

- [ ] Test that `cdd` uses the work `CODEX_HOME` and `cdd-personal` uses the personal `CODEX_HOME`.
- [ ] Replace login-shell test calls that overwrite temporary `HOME`.
- [ ] Route `cdd` through the same explicit-profile launcher as `cdd-work`.
- [ ] Run alias tests and confirm both account commands pass.

### Task 4: Apply and verify

**Files:**
- Runtime outputs under both Codex profile homes

- [ ] Run the complete regression suite and shell syntax checks.
- [ ] Run `setup.sh` with explicit real-home context.
- [ ] Confirm both profiles link shared assets while auth/session paths remain distinct.
- [ ] Confirm neither generated config contains `[mcp_servers.codex_apps]`.
