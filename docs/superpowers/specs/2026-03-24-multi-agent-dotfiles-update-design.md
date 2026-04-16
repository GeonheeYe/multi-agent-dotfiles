# multi-agent-dotfiles 템플릿 레포 업데이트 설계

## 핵심 컨셉

사용자가 Claude Code에게 레포 URL만 주면, Claude가 README를 읽고 clone → setup.sh → 완료까지 자동 수행하는 원커맨드 셋업 경험.

타겟: Claude Code를 처음 쓰는 개발자.

## 디렉토리 구조

```
multi-agent-dotfiles/
├── README.md                    # Claude Code가 읽고 실행할 수 있는 설정 가이드
├── setup.sh                     # 개선된 설치 스크립트
├── rules/
│   └── base.md                  # 에이전트 공유 규칙 (템플릿)
├── skills/                      # 범용 스킬 18개 포함
│   ├── brainstorming/
│   ├── writing-plans/
│   ├── writing-skills/
│   ├── test-driven-development/
│   ├── systematic-debugging/
│   ├── using-git-worktrees/
│   ├── executing-plans/
│   ├── subagent-driven-development/
│   ├── receiving-code-review/
│   ├── requesting-code-review/
│   ├── verification-before-completion/
│   ├── dispatching-parallel-agents/
│   ├── unknown/
│   ├── vague/
│   ├── metamedium/
│   ├── find-skills/
│   ├── using-superpowers/
│   └── finishing-a-development-branch/
├── commands/
│   └── mcp-apply.md
├── mcp/
│   ├── apply.sh
│   ├── servers.json.example
│   └── secrets.json.example
├── scripts/
│   ├── sync-dotfiles.sh
│   └── push-dotfiles.sh
├── shell/
│   └── aliases.sh
├── memory/
│   └── .gitkeep
└── .gitignore
```

**참고**: `.system/` 디렉토리는 레포에 포함하지 않음. Codex CLI가 런타임에 자동 생성하며, setup.sh가 기존 `.system/`을 보존하는 로직을 포함.

## README 구조

현재 public README(298줄, 영어)를 **완전히 대체**. Claude Code가 파싱하기 좋게 단계별 명령어 블록으로 구성하되, 기존 README의 유용한 섹션(Windows WSL 가이드, Troubleshooting)도 포함.

### 1. Prerequisites
- git, node (>= 18), python3 설치 확인
- Claude Code / Codex CLI / Cursor 중 하나 이상 설치

### 2. Quick Setup
```bash
git clone https://github.com/GeonheeYe/multi-agent-dotfiles.git ~/dotfiles
cd ~/dotfiles
cp mcp/secrets.json.example mcp/secrets.json
# secrets.json에 본인의 API 토큰 입력
./setup.sh
```

### 3. What setup.sh does
- 순환 symlink 자동 정리
- 에이전트별 symlink 생성 (skills, commands, rules)
- 플러그인 스킬 symlink 연결 (Claude Code 플러그인 → dotfiles, symlink 방식)
- MCP 설정 배포 (apply.sh 실행)
- SessionStart 훅 등록 (세션 시작 시 dotfiles 자동 pull)
- shell alias 등록 (.zshrc/.bashrc)

### 4. Customization
- 스킬 추가: skills/[이름]/SKILL.md 생성
- MCP 추가: mcp/servers.json 수정 → secrets.json 추가 → ./mcp/apply.sh
- 규칙 수정: rules/base.md 편집

### 5. Troubleshooting
- Windows: WSL 필수
- Cursor 스킬 미표시: rsync로 수동 복사 권장
- 경로: ~ 또는 $HOME 사용 (절대경로 하드코딩 금지)

## setup.sh 변경 상세

현재 public의 setup.sh 대비 변경사항을 구체적으로 명시:

### 추가할 기능
1. **순환 symlink 정리** (private 4-21행): `clean_circular_symlink()` 함수 — 자기 자신을 참조하는 symlink 제거
2. **플러그인 스킬 symlink** (private 61-89행): `link_skill_dir()` 함수 — Claude Code 플러그인 스킬을 dotfiles/skills에 symlink로 연결. **symlink 방식 채택** (copy가 아닌 ln -sf)
3. **SessionStart 훅 등록** (private 120-155행): Python3 인라인 스크립트로 ~/.claude/settings.json에 sync-dotfiles.sh 호출 훅 추가. 기존 `git -C` 기반 훅이 있으면 자동 제거 후 교체.
4. **shell alias 등록** (private 160-170행): .zshrc/.bashrc에 `source ~/dotfiles/shell/aliases.sh` 추가 (중복 방지)
5. **scripts/ chmod** : setup.sh 실행 시 `chmod +x scripts/*.sh` 자동 적용

### 제거할 기능
- Dooray MCP 빌드 (npm ci && npm run build) — 개인용
- dooray-mcp 서브모듈 관련 로직

### 마이그레이션 처리
- 기존 SessionStart 훅 (`git -C ~/dotfiles pull` 패턴) 감지 시 자동 제거 후 sync-dotfiles.sh 호출로 교체
- 기존 사용자가 git pull → setup.sh 재실행하면 자연스럽게 마이그레이션됨

## scripts/ 추가

### sync-dotfiles.sh
- 로컬 변경사항 auto-commit (hostname 태그)
- git pull --rebase
- HEAD 변경 시 setup.sh 재실행
- rebase 충돌 시 abort + 알림
- 모든 메시지 영어로 출력 (public 템플릿)

### push-dotfiles.sh
- 로컬 변경사항 auto-commit
- git pull --rebase
- 충돌 시 abort + 알림
- 로컬이 앞서면 push
- 모든 메시지 영어로 출력

**보안 참고**: 두 스크립트 모두 `git add -A` 사용. `.gitignore`에 `secrets.json`, `memory/` 등 민감 파일이 이미 포함되어 있으므로 안전. `.gitignore` 검증은 setup.sh에서 수행.

## shell/aliases.sh 개선

현재 public: cc, ccd, ccr, cdd (4개)
추가: cu (Cursor CLI)

각 함수는 실행 전 dotfiles pull, 실행 후 dotfiles push 자동 수행.

## 스킬 포함 방식

**레포에 직접 포함** — 각 스킬의 SKILL.md와 관련 파일을 skills/ 디렉토리에 직접 커밋.

superpowers 플러그인 스킬의 경우: 이 스킬들은 사용자가 superpowers 플러그인을 설치하면 자동 생성되는 것이지만, 플러그인 없이도 사용 가능하도록 템플릿에 직접 포함. MIT 라이선스 호환 확인 필요 — 만약 라이선스 문제가 있으면 README에 "superpowers 플러그인 설치 후 setup.sh 실행" 안내로 대체.

### 포함 스킬 (18개)

| 스킬 | 용도 |
|------|------|
| brainstorming | 아이디어 → 설계 협업 |
| writing-plans | 구조화된 구현 계획 |
| writing-skills | 스킬 작성 가이드 |
| test-driven-development | TDD 프로세스 |
| systematic-debugging | 체계적 디버깅 |
| using-git-worktrees | Git worktree 활용 |
| executing-plans | 계획 실행 관리 |
| subagent-driven-development | 병렬 에이전트 작업 |
| receiving-code-review | 코드 리뷰 피드백 처리 |
| requesting-code-review | 코드 리뷰 요청 |
| verification-before-completion | 완료 전 검증 |
| dispatching-parallel-agents | 병렬 작업 분배 |
| unknown | Known/Unknown 4분면 분석 |
| vague | 모호한 요구사항 명확화 |
| metamedium | 콘텐츠 vs 형식 분석 |
| find-skills | 스킬 검색 |
| using-superpowers | 플러그인 사용 가이드 |
| finishing-a-development-branch | 개발 완료 및 통합 |

## 제외 항목

- 개인용 스킬: apply, gcal, meeting, quiz, save-q, yt-quiz, ai-daily-news, my-context-sync
- git-onboarding-* 5개
- chrome-devtools 관련 4개 (chrome-devtools, a11y-debugging, debug-optimize-lcp, troubleshooting)
- claude_plugins/ 디렉토리 (개인 플러그인 설정 — setup.sh의 플러그인 symlink 로직은 유지하되, 디렉토리 자체는 레포에 포함하지 않음)
- meeting_tools/ (개인 도구)
- docs/ (개인 문서)
- memory/questions/ (개인 데이터, memory/.gitkeep만 포함)
- token_calendar.json (개인)

## 에이전트별 매핑 (변경 없음)

| 항목 | Claude Code | Codex CLI | Cursor |
|------|------------|-----------|--------|
| 규칙 | ~/CLAUDE.md | ~/AGENTS.md | ~/.cursor/rules/base.mdc |
| 스킬 | ~/.claude/skills/ | ~/.codex/skills/ | ~/.cursor/skills/ |
| 명령어 | ~/.claude/commands/ | ~/.codex/prompts/ | ~/.cursor/commands/ |
| MCP | ~/.claude.json | ~/.codex/config.toml | ~/.cursor/mcp.json |
