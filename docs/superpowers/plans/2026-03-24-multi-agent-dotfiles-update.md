# multi-agent-dotfiles 템플릿 레포 업데이트 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** public repo GeonheeYe/multi-agent-dotfiles를 private dotfiles의 구조적 개선사항 반영 + 범용 스킬 18개 포함한 템플릿으로 업데이트

**Architecture:** public repo를 로컬에서 수정 후 push. private ~/dotfiles/에서 필요한 파일을 복사/수정하여 반영. 개인용 요소(dooray, 한국어, 토큰 등)는 제거하고 범용 템플릿화.

**Tech Stack:** bash, python3, git, GitHub CLI (gh)

---

## File Map

### 수정 대상 (기존 파일)
- `~/multi-agent-dotfiles/README.md` — 완전 재작성
- `~/multi-agent-dotfiles/setup.sh` — private 기능 반영 + 개인용 제거
- `~/multi-agent-dotfiles/shell/aliases.sh` — private 버전으로 교체 (cu 추가)
- `~/multi-agent-dotfiles/.gitignore` — scripts/, memory/ 등 반영
- `~/multi-agent-dotfiles/rules/base.md` — 템플릿 유지 (현재 상태 OK)
- `~/multi-agent-dotfiles/mcp/apply.sh` — 주석 영어화, 개인용 제거

### 새로 생성
- `~/multi-agent-dotfiles/scripts/sync-dotfiles.sh` — private에서 복사 + 영어화
- `~/multi-agent-dotfiles/scripts/push-dotfiles.sh` — private에서 복사 + 영어화
- `~/multi-agent-dotfiles/commands/mcp-apply.md` — private에서 복사
- `~/multi-agent-dotfiles/skills/` 하위 18개 스킬 디렉토리 (46개 파일)

### 삭제 대상
- `~/multi-agent-dotfiles/skills/.gitkeep` — 스킬이 들어가므로 불필요
- `~/multi-agent-dotfiles/skills/.system/` — 런타임 생성으로 변경 (git rm 필요 — tracked 파일)
- `~/multi-agent-dotfiles/commands/.gitkeep` — mcp-apply.md가 들어가므로 불필요 (git rm 필요 — tracked 파일)

---

## Chunk 1: 레포 준비 및 기존 파일 정리

### Task 1: 작업 브랜치 생성 및 불필요 파일 제거

**Files:**
- Modify: `~/multi-agent-dotfiles/` (git operations)
- Delete: `~/multi-agent-dotfiles/skills/.gitkeep` (tracked)
- Delete: `~/multi-agent-dotfiles/skills/.system/skill-creator/SKILL.md` (tracked)
- Delete: `~/multi-agent-dotfiles/skills/.system/skill-installer/SKILL.md` (tracked)
- Delete: `~/multi-agent-dotfiles/commands/.gitkeep` (tracked)

참고: `mcp/servers.json`은 .gitignore에 있고 tracked가 아님 — 삭제 불필요.

- [ ] **Step 1: 작업 브랜치 생성**

```bash
cd ~/multi-agent-dotfiles
git checkout -b feat/template-update
```

- [ ] **Step 2: tracked 파일 삭제 (git rm 사용)**

```bash
cd ~/multi-agent-dotfiles
git rm -f skills/.gitkeep commands/.gitkeep
git rm -rf skills/.system/
```

- [ ] **Step 3: 커밋**

```bash
cd ~/multi-agent-dotfiles
git commit -m "chore: remove placeholder files and runtime-generated skills

Remove .system/ skills (Codex generates at runtime),
and .gitkeep placeholders that will be replaced with actual content."
```

---

## Chunk 2: 스크립트 파일 추가/업데이트

### Task 2: scripts/ 디렉토리 추가 (sync-dotfiles.sh, push-dotfiles.sh)

**Files:**
- Create: `~/multi-agent-dotfiles/scripts/sync-dotfiles.sh`
- Create: `~/multi-agent-dotfiles/scripts/push-dotfiles.sh`
- Source: `~/dotfiles/scripts/sync-dotfiles.sh`, `~/dotfiles/scripts/push-dotfiles.sh`

- [ ] **Step 1: scripts 디렉토리 생성**

```bash
mkdir -p ~/multi-agent-dotfiles/scripts
```

- [ ] **Step 2: sync-dotfiles.sh 복사 및 영어화**

`~/dotfiles/scripts/sync-dotfiles.sh`를 `~/multi-agent-dotfiles/scripts/sync-dotfiles.sh`에 복사.
한국어 주석/메시지를 영어로 번역. 핵심 로직:
- uncommitted 변경사항 auto-commit (hostname 태그)
- `git pull --rebase`
- HEAD 변경 시 setup.sh 재실행
- rebase 충돌 시 abort + 경고

- [ ] **Step 3: push-dotfiles.sh 복사 및 영어화**

`~/dotfiles/scripts/push-dotfiles.sh`를 `~/multi-agent-dotfiles/scripts/push-dotfiles.sh`에 복사.
한국어 주석/메시지를 영어로 번역. 핵심 로직:
- untracked 포함 auto-commit
- fetch + rebase 필요 시 pull --rebase
- 충돌 시 abort
- 로컬이 앞서면 push

- [ ] **Step 4: 실행 권한 부여**

```bash
chmod +x ~/multi-agent-dotfiles/scripts/sync-dotfiles.sh
chmod +x ~/multi-agent-dotfiles/scripts/push-dotfiles.sh
```

- [ ] **Step 5: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add scripts/
git commit -m "feat: add auto-sync scripts for dotfiles synchronization

sync-dotfiles.sh: auto-commit + pull --rebase + re-run setup on changes
push-dotfiles.sh: auto-commit + pull --rebase + push to remote"
```

### Task 3: shell/aliases.sh 업데이트

**Files:**
- Modify: `~/multi-agent-dotfiles/shell/aliases.sh`
- Source: `~/dotfiles/shell/aliases.sh`

- [ ] **Step 1: aliases.sh 교체**

`~/dotfiles/shell/aliases.sh`의 내용을 `~/multi-agent-dotfiles/shell/aliases.sh`에 복사.
변경사항:
- OS 감지 함수 추가 (_detect_os)
- cu (Cursor CLI) alias 추가
- 주석 영어화
- sync-dotfiles.sh / push-dotfiles.sh 경로 참조

- [ ] **Step 2: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add shell/aliases.sh
git commit -m "feat: upgrade aliases with OS detection and Cursor support

Add _detect_os function, cu alias for Cursor CLI,
upgrade all wrappers to use sync/push scripts."
```

### Task 4: setup.sh 업데이트

**Files:**
- Modify: `~/multi-agent-dotfiles/setup.sh`
- Source: `~/dotfiles/setup.sh`

- [ ] **Step 1: setup.sh 업데이트**

`~/dotfiles/setup.sh`를 기반으로 `~/multi-agent-dotfiles/setup.sh` 재작성.

**Private에서 가져올 기능:**
1. `clean_circular_symlink()` 함수 — 순환 symlink 제거
2. `link_skill_dir()` 함수 — 플러그인 스킬을 dotfiles/skills에 symlink
3. Codex `.system/` 스킬 보존 로직 (`preserve_codex_system_skills`)
4. SessionStart 훅 등록 (Python3 인라인 스크립트로 settings.json 수정)
5. Shell alias 자동 등록 (.zshrc/.bashrc에 source 추가, 중복 방지)
6. `chmod +x scripts/*.sh` 추가
7. 기존 `git -C` 기반 훅 감지 시 자동 제거

**제거할 기능:**
- Dooray MCP 빌드 (`npm ci && npm run build`)
- dooray-mcp 서브모듈 관련 로직
- 개인용 경로 참조

**주석/메시지 영어화.**

**개인용 경로 참조 제거 구체 목록:**
- `dooray-mcp` 관련 모든 경로/변수
- `npm ci && npm run build` dooray 빌드 단계
- `.gitmodules` 참조 (dooray-mcp 서브모듈)

**setup.sh에 `.gitignore` 검증 로직 추가:**
- setup.sh 실행 시 `.gitignore`에 `mcp/secrets.json`이 포함되어 있는지 확인
- 없으면 경고 메시지 출력

- [ ] **Step 2: 실행 테스트 (dry-run 확인)**

```bash
cd ~/multi-agent-dotfiles
# DOTFILES_DIR가 스크립트 위치 기준으로 설정되는지 확인
grep -n 'DOTFILES_DIR' setup.sh

# 하드코딩된 절대경로가 없는지 확인
grep -n '/home/geonhee\|/Users/geonhee' setup.sh

# dooray 관련 코드가 남아있지 않은지 확인
grep -ni 'dooray' setup.sh

# python3 인라인 스크립트 구문 확인
python3 -c "print('python3 available')"
```

Expected: DOTFILES_DIR는 `$(cd "$(dirname "$0")" && pwd)` 형태, 하드코딩 경로 없음, dooray 없음, python3 사용 가능.

- [ ] **Step 3: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add setup.sh
git commit -m "feat: upgrade setup.sh with plugin sync, hooks, and migration

Add circular symlink cleanup, plugin skill linking,
SessionStart hook registration via python3,
shell alias auto-registration, and chmod for scripts.
Remove Dooray-specific build steps."
```

### Task 5: mcp/apply.sh 주석 영어화

**Files:**
- Modify: `~/multi-agent-dotfiles/mcp/apply.sh`

- [ ] **Step 1: apply.sh 주석 영어화**

`~/multi-agent-dotfiles/mcp/apply.sh`의 한국어 주석을 영어로 번역.
로직은 변경하지 않음.

- [ ] **Step 2: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add mcp/apply.sh
git commit -m "docs: translate apply.sh comments to English"
```

### Task 6: commands/mcp-apply.md 추가

**Files:**
- Create: `~/multi-agent-dotfiles/commands/mcp-apply.md`
- Source: `~/dotfiles/commands/mcp-apply.md`

- [ ] **Step 1: mcp-apply.md 복사**

`~/dotfiles/commands/mcp-apply.md`를 `~/multi-agent-dotfiles/commands/mcp-apply.md`에 복사.

- [ ] **Step 2: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add commands/mcp-apply.md
git commit -m "feat: add mcp-apply command prompt"
```

### Task 7: .gitignore 업데이트

**Files:**
- Modify: `~/multi-agent-dotfiles/.gitignore`

- [ ] **Step 1: .gitignore 완전 재작성**

현재 .gitignore 내용:
```
mcp/secrets.json
mcp/servers.json
.DS_Store
memory/
meeting_tools/.env
```

다음으로 교체 (개인용 `meeting_tools/.env` 제거, `memory/` → `memory/*` + `!memory/.gitkeep`):
```
# Secrets
mcp/secrets.json
mcp/servers.json

# Memory (personal data)
memory/*
!memory/.gitkeep

# OS
.DS_Store

# Codex system skills (runtime generated)
skills/.system/

# Claude plugins (personal)
claude_plugins/cache/
claude_plugins/marketplaces/
claude_plugins/install-counts-cache.json
claude_plugins/blocklist.json
```

- [ ] **Step 2: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add .gitignore
git commit -m "chore: update .gitignore for scripts, memory, and secrets"
```

---

## Chunk 3: 범용 스킬 18개 추가

### Task 8: 스킬 디렉토리 일괄 복사

**Files:**
- Create: `~/multi-agent-dotfiles/skills/` 하위 18개 디렉토리 (43개 파일)
- Source: `~/dotfiles/skills/` 하위 해당 디렉토리

스킬 목록 (실제 파일 수 확인 완료):
1. brainstorming (3 files)
2. writing-plans (2 files)
3. writing-skills (7 files)
4. test-driven-development (2 files)
5. systematic-debugging (11 files)
6. using-git-worktrees (1 file)
7. executing-plans (1 file)
8. subagent-driven-development (4 files)
9. receiving-code-review (1 file)
10. requesting-code-review (2 files)
11. verification-before-completion (1 file)
12. dispatching-parallel-agents (1 file)
13. unknown (3 files)
14. vague (1 file)
15. metamedium (2 files)
16. find-skills (1 file)
17. using-superpowers (2 files)
18. finishing-a-development-branch (1 file)

- [ ] **Step 1: 18개 스킬 디렉토리 복사**

```bash
cd ~/multi-agent-dotfiles

SKILLS=(
  brainstorming
  writing-plans
  writing-skills
  test-driven-development
  systematic-debugging
  using-git-worktrees
  executing-plans
  subagent-driven-development
  receiving-code-review
  requesting-code-review
  verification-before-completion
  dispatching-parallel-agents
  unknown
  vague
  metamedium
  find-skills
  using-superpowers
  finishing-a-development-branch
)

for skill in "${SKILLS[@]}"; do
  cp -r ~/dotfiles/skills/"$skill" skills/
done
```

- [ ] **Step 2: 복사 결과 확인**

```bash
ls -la ~/multi-agent-dotfiles/skills/
# 18개 디렉토리가 있어야 함

find ~/multi-agent-dotfiles/skills/ -type f | wc -l
# 46개 파일이 있어야 함
```

- [ ] **Step 3: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add skills/
git commit -m "feat: add 18 universal skills for development workflow

Include: brainstorming, writing-plans, writing-skills,
test-driven-development, systematic-debugging, using-git-worktrees,
executing-plans, subagent-driven-development, receiving-code-review,
requesting-code-review, verification-before-completion,
dispatching-parallel-agents, unknown, vague, metamedium,
find-skills, using-superpowers, finishing-a-development-branch"
```

---

## Chunk 4: README 재작성 및 최종 검증

### Task 9: README.md 완전 재작성

**Files:**
- Modify: `~/multi-agent-dotfiles/README.md`

- [ ] **Step 1: README.md 재작성**

현재 README를 완전히 대체. 구조:

```markdown
# multi-agent-dotfiles

Shared dotfiles for Claude Code, Codex CLI, and Cursor.
One repo, one setup — all three agents share the same rules, skills, commands, and MCP config.

## Prerequisites

- git
- node >= 18
- python3
- At least one of: Claude Code, Codex CLI, Cursor

## Quick Setup

\```bash
git clone https://github.com/GeonheeYe/multi-agent-dotfiles.git ~/dotfiles
cd ~/dotfiles
cp mcp/secrets.json.example mcp/secrets.json
# Edit mcp/secrets.json with your API tokens
./setup.sh
\```

That's it. setup.sh handles everything:
- Creates symlinks for all three agents (skills, commands, rules)
- Syncs Claude Code plugin skills to dotfiles
- Deploys MCP server config to each agent
- Registers SessionStart hook for auto-sync
- Adds shell aliases to .zshrc/.bashrc

## What Gets Linked

| Item | Claude Code | Codex CLI | Cursor |
|------|------------|-----------|--------|
| Rules | ~/CLAUDE.md | ~/AGENTS.md | ~/.cursor/rules/base.mdc |
| Skills | ~/.claude/skills/ | ~/.codex/skills/ | ~/.cursor/skills/ |
| Commands | ~/.claude/commands/ | ~/.codex/prompts/ | ~/.cursor/commands/ |
| MCP | ~/.claude.json | ~/.codex/config.toml | ~/.cursor/mcp.json |

## Included Skills (18)

[스킬 테이블 — 이름, 한줄 설명]

## Shell Aliases

| Alias | Description |
|-------|-------------|
| cc | Claude Code (auto-sync before/after) |
| ccd | Claude Code (skip permission checks) |
| ccr | Claude Code (resume previous session) |
| cdd | Codex CLI (bypass approvals) |
| cu | Cursor CLI |

## Auto-Sync

- **On session start:** SessionStart hook runs sync-dotfiles.sh (pull latest)
- **On alias use:** cc/ccd/ccr/cdd/cu pull before, push after
- **scripts/sync-dotfiles.sh:** auto-commit + pull --rebase + re-run setup if changed
- **scripts/push-dotfiles.sh:** auto-commit + pull --rebase + push

## Customization

### Add a skill
Create `skills/my-skill/SKILL.md` — instantly available in all agents.

### Add an MCP server
1. Edit `mcp/servers.json.example` (or create `mcp/servers.json`)
2. Add tokens to `mcp/secrets.json`
3. Run `./mcp/apply.sh`

### Edit rules
Modify `rules/base.md` — symlinked to all agents.

## Troubleshooting

- **Windows:** WSL required
- **Cursor skills not showing:** Use rsync instead of symlink
- **Paths:** Always use ~ or $HOME, never hardcode absolute paths
- **MCP not working:** Check secrets.json exists and has valid tokens

## License

MIT
```

- [ ] **Step 2: 커밋**

```bash
cd ~/multi-agent-dotfiles
git add README.md
git commit -m "docs: rewrite README for one-command setup experience

Restructure for clarity: prerequisites, quick setup, what gets linked,
included skills, aliases, auto-sync, customization, troubleshooting.
Designed to be parseable by Claude Code for automated setup."
```

### Task 10: 최종 검증

- [ ] **Step 1: 파일 구조 확인**

```bash
cd ~/multi-agent-dotfiles
find . -not -path './.git/*' -not -path './.git' | sort
```

설계 문서의 디렉토리 구조와 일치하는지 확인.

- [ ] **Step 2: 실행 권한 확인**

```bash
ls -la setup.sh scripts/*.sh mcp/apply.sh
# 모두 -rwxr-xr-x 여야 함
```

- [ ] **Step 3: .gitignore 동작 확인**

```bash
cd ~/multi-agent-dotfiles
git status
# secrets.json, memory/*, skills/.system/ 등이 표시되지 않아야 함
```

- [ ] **Step 4: 커밋 히스토리 확인**

```bash
cd ~/multi-agent-dotfiles
git log --oneline
# 깔끔한 커밋 히스토리
```

### Task 11: Push 및 PR 생성

- [ ] **Step 1: 원격 push**

```bash
cd ~/multi-agent-dotfiles
git push -u origin feat/template-update
```

- [ ] **Step 2: PR 생성**

```bash
cd ~/multi-agent-dotfiles
gh pr create \
  --title "feat: upgrade template with skills, scripts, and auto-sync" \
  --body "## Summary
- Add 18 universal development skills
- Add sync/push scripts for auto-synchronization
- Upgrade setup.sh with plugin sync, hooks, migration
- Add Cursor CLI alias (cu)
- Rewrite README for one-command setup experience
- Translate all comments/messages to English

## What changed
- skills/: 18 directories, 46 files (brainstorming, TDD, debugging, etc.)
- scripts/: sync-dotfiles.sh, push-dotfiles.sh
- setup.sh: circular symlink cleanup, plugin linking, SessionStart hook
- shell/aliases.sh: OS detection, cu alias
- README.md: complete rewrite
- .gitignore: updated for new structure
- Removed: personal Dooray config, .system/ skills, .gitkeep placeholders"
```
