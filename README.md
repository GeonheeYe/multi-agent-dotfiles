# dotfiles

Claude Code, Codex CLI, Cursor 공통 환경 관리.
skills, commands, rules, MCP를 단일 저장소에서 관리하고 각 에이전트에 symlink로 연결합니다.

## 구조

```
dotfiles/
├── rules/
│   └── base.md          # CLAUDE.md / AGENTS.md / .cursor/rules/base.mdc
├── skills/              # SKILL.md 기반 스킬 (세 에이전트 공유)
├── commands/            # 슬래시 커맨드 프롬프트
├── claude_plugins/      # Claude Code 플러그인 설정 (Claude Code 전용)
├── mcp/
│   ├── servers.json     # MCP 서버 구조 정의 (${ENV_VAR} placeholder)
│   ├── secrets.json     # 실제 토큰값 (private repo에서 관리)
│   ├── secrets.json.example
│   └── apply.sh         # secrets 주입 후 각 에이전트에 배포
└── setup.sh             # 최초 1회 실행
```

## 에이전트별 연결 위치

| 항목 | Claude Code | Codex CLI | Cursor |
|------|------------|-----------|--------|
| rules | `~/CLAUDE.md` | `~/AGENTS.md` | `~/.cursor/rules/base.mdc` |
| skills | `~/.claude/skills/` | `~/.codex/skills/` | `~/.cursor/skills/` |
| commands | `~/.claude/commands/` | `~/.codex/prompts/` | `~/.cursor/commands/` |
| claude_plugins | `~/.claude/plugins/` | - | - |
| MCP | `~/.claude.json` | `~/.codex/config.toml` | - |

## 새 환경 세팅

### 요구사항

- git
- python3
- [Claude Code](https://claude.ai/code)
- [Codex CLI](https://github.com/openai/codex) (선택)
- [Cursor](https://cursor.com) (선택)

### 1. 저장소 클론

```bash
git clone https://github.com/GeonheeYe/dotfiles ~/dotfiles
```

### 2. MCP secrets 설정

`secrets.json`은 이미 repo에 포함되어 있습니다. 새 머신에서는 별도 설정 없이 `./setup.sh`를 실행하면 됩니다.

### 3. setup.sh 실행

```bash
cd ~/dotfiles && ./setup.sh
```

아래를 자동으로 처리합니다:

- `~/.claude`, `~/.codex`, `~/.cursor`에 skills/commands/rules symlink 생성
- MCP 서버 설정 및 dooray-mcp 빌드
- `.zshrc`/`.bashrc`에 shell aliases 등록 (`cc`, `ccd`, `ccr`, `cdd`, `cu`)
- Claude SessionStart 훅 등록 (세션 시작 시 dotfiles 자동 pull)

설치 후 새 터미널을 열거나 `source ~/.zshrc`를 실행하면 aliases가 활성화됩니다.

### 4. Claude Code 플러그인 설치

```bash
claude plugin install superpowers@claude-plugins-official
claude plugin install clarify@team-attention-plugins
claude plugin install git-onboarding@git-for-everyone
```

> Codex CLI는 플러그인 시스템이 없으므로 skills로만 동작합니다.

---

## 스킬 추가

어느 에이전트에서 만들든 `~/dotfiles/skills/`에 저장됩니다:

```bash
mkdir ~/dotfiles/skills/my-skill
cat > ~/dotfiles/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: 스킬 설명
---

스킬 내용
EOF

cd ~/dotfiles && git add . && git commit -m "feat: add my-skill" && git push
```

## MCP 서버 추가

```bash
# 1. servers.json에 서버 추가
vim ~/dotfiles/mcp/servers.json

# 2. secrets.json에 토큰 추가
vim ~/dotfiles/mcp/secrets.json

# 3. 적용
./mcp/apply.sh

# 4. 커밋
git add mcp/servers.json && git commit -m "feat: add new MCP server"
```

## 다른 머신과 동기화

```bash
~/dotfiles/scripts/sync-dotfiles.sh
```

에이전트 실행용 셸 함수(`cc`, `cdd`, `cu`)와 Claude `SessionStart` 훅은 이 스크립트를 자동 호출합니다.
원격 변경으로 `HEAD`가 바뀐 경우에만 `setup.sh`를 다시 실행해 symlink, rules, MCP 설정을 재적용합니다.
