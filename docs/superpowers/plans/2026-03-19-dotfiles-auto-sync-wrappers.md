# Dotfiles Auto Sync Wrappers Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `claude` and `codex` wrapper commands that attempt a safe `~/dotfiles` fast-forward sync right before launching the real CLI.

**Architecture:** Keep sync logic in one reusable shell script under `scripts/`, install lightweight wrappers into `~/bin/`, and document the PATH requirement in the README. The sync script must skip pulls when the repo is dirty or fast-forward is not possible.

**Tech Stack:** Bash, git

---

## Chunk 1: Test and Script Layout

### Task 1: Define sync behavior in a shell test

**Files:**
- Create: `tests/dotfiles-auto-sync-test.sh`
- Create: `scripts/dotfiles-auto-sync.sh`

- [ ] **Step 1: Write the failing test**

Add shell tests that expect:
- clean repo path triggers `git -C <repo> pull --ff-only`
- dirty repo skips pull
- sync command returns success even when it skips

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/dotfiles-auto-sync-test.sh`
Expected: FAIL because `scripts/dotfiles-auto-sync.sh` does not exist yet

- [ ] **Step 3: Write minimal implementation**

Add a reusable sync script with a `run_dotfiles_sync` function and a direct execution path.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/dotfiles-auto-sync-test.sh`
Expected: PASS

## Chunk 2: Wrapper Installation

### Task 2: Install `claude` and `codex` wrappers from `setup.sh`

**Files:**
- Modify: `setup.sh`

- [ ] **Step 1: Write the failing assertion**

Extend the shell test or add setup verification that expects generated wrappers to call the sync script and then `exec` the real binary.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/dotfiles-auto-sync-test.sh`
Expected: FAIL because wrappers are not created by `setup.sh`

- [ ] **Step 3: Write minimal implementation**

Teach `setup.sh` to:
- create `~/bin`
- install wrappers for `claude` and `codex`
- remind the user to put `~/bin` before the original binary in `PATH`

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/dotfiles-auto-sync-test.sh && bash -n setup.sh`
Expected: PASS

## Chunk 3: Docs

### Task 3: Document behavior and limits

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add README updates**

Document:
- wrappers are installed into `~/bin`
- sync runs right before `claude` and `codex`
- dirty repos skip sync safely
- `~/bin` must come first in `PATH`

- [ ] **Step 2: Verify docs match behavior**

Run: `rg -n "자동 동기화|~/bin|--ff-only" README.md setup.sh scripts/dotfiles-auto-sync.sh`
Expected: matching wording across files
