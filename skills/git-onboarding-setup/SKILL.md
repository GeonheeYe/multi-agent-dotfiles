---
name: git-onboarding-setup
description: Git과 GitHub 초기 설정을 단계별로 진행합니다. "git 설정", "처음 시작", "GitHub 로그인", "깃 세팅" 같은 요청에 사용됩니다.
---

# Git 초기 설정 가이드

Git과 GitHub를 처음 사용하기 위한 설정을 단계별로 진행합니다.
이미 완료된 단계는 자동으로 건너뜁니다.

## 상태 수집

아래 9개 명령어를 **모두 병렬로** 실행하세요:

1. `which git` — Git 설치 여부
2. `git config --global user.name` — 사용자 이름
3. `git config --global user.email` — 이메일
4. `which gh 2>/dev/null && echo "installed" || echo "none"` — GitHub CLI 설치 여부
5. `gh auth status 2>&1` — GitHub 인증 상태 (출력에 "Logged in"이 포함되면 성공)
6. `git rev-parse --git-dir 2>/dev/null && echo "repo" || echo "no-repo"` — Git 저장소 여부
7. `git remote get-url origin 2>/dev/null || echo "no-remote"` — 원격 저장소 연결 여부
8. `git ls-remote --heads origin main 2>/dev/null | grep -q main && echo "remote-branch: exists" || echo "remote-branch: none"` — 원격 main 브랜치 여부
9. `for hook in pre-commit commit-msg pre-push; do test -x .git/hooks/$hook && echo "$hook: exists" || echo "$hook: none"; done` — git hooks 설치 여부

## 진행 규칙

- 결과를 분석하여 이미 완료된 단계는 건너뛰세요.
- 첫 번째 미완료 단계부터 순서대로 진행하세요.
- 각 단계를 하나씩 완료한 후 다음 단계로 넘어가세요.
- 사용자 입력이 필요한 단계에서는 반드시 AskUserQuestion을 사용하세요.
- 모든 설명은 한국어로, Git을 처음 쓰는 사용자 눈높이에 맞추세요.

## 단계 1: Git 설치 확인

**완료 조건:** `which git`이 경로를 반환함

미설치인 경우 안내하세요:

```
Git이 설치되어 있지 않습니다.

터미널에서 아래 명령어를 직접 실행하세요:
  xcode-select --install

설치 팝업이 나타나면 "설치" 버튼을 클릭하세요.
설치가 완료되면 다시 /git-onboarding-setup 을 실행해주세요.
```

xcode-select는 GUI 팝업이 필요하므로 Claude가 직접 실행하지 마세요. 안내만 제공하고 이 단계에서 멈추세요.

## 단계 2: 사용자 이름 설정

**완료 조건:** `git config --global user.name`이 비어있지 않음

AskUserQuestion으로 이름을 물어보세요:

- question: "Git에서 사용할 이름을 입력하세요. 커밋 기록에 남는 이름입니다."
- header: "이름"
- options:
  - 현재 시스템 사용자 이름을 기본 옵션으로 제안

이름을 받으면 실행하세요:

```
git config --global user.name "<입력받은 이름>"
```

## 단계 3: 이메일 설정

**완료 조건:** `git config --global user.email`이 비어있지 않음

AskUserQuestion으로 이메일을 물어보세요:

- question: "Git에서 사용할 이메일을 입력하세요. GitHub 계정과 같은 이메일을 권장합니다. 이메일을 공개하고 싶지 않다면 GitHub의 noreply 이메일을 사용할 수 있습니다 (GitHub > Settings > Emails에서 확인)."
- header: "이메일"
- options:
  - "noreply 이메일 사용" — GitHub Settings > Emails에서 제공하는 비공개 이메일 (username@users.noreply.github.com)
  - "직접 입력" — 본인 이메일 주소를 직접 입력

이메일을 받으면 실행하세요:

```
git config --global user.email "<입력받은 이메일>"
```

## 단계 4: GitHub CLI 설치 확인

**완료 조건:** `which gh`가 경로를 반환함

미설치인 경우, AskUserQuestion으로 설치 방법을 안내하세요:

- question: "GitHub CLI(gh)가 설치되어 있지 않습니다. 어떤 방법으로 설치하시겠습니까?"
- header: "gh 설치"
- options:
  - "Homebrew로 설치 (Recommended)" — Mac 사용자에게 권장. `brew install gh`
  - "직접 설치" — https://cli.github.com 에서 다운로드

Homebrew를 선택한 경우:

```bash
brew install gh
```

직접 설치를 선택한 경우, 사용자에게 안내하세요:

```
아래 링크에서 GitHub CLI를 다운로드하여 설치하세요:
  https://cli.github.com

설치가 완료되면 다시 /git-onboarding-setup 을 실행해주세요.
```

직접 설치는 Claude가 실행할 수 없으므로 안내만 제공하고 이 단계에서 멈추세요.

## 단계 5: GitHub 로그인

**완료 조건:** `gh auth status 2>&1` 출력에 "Logged in"이 포함됨

GitHub에 로그인되어 있지 않은 경우, 사용자에게 안내하세요:

```
GitHub에 로그인해야 합니다.

터미널에서 아래 명령어를 직접 실행하세요:
  gh auth login --hostname github.com --git-protocol https --web

브라우저가 자동으로 열리고 인증 코드가 표시됩니다:
  1. 터미널에 나오는 코드를 확인
  2. 브라우저에서 코드를 입력하고 인증 완료

완료되면 다시 /git-onboarding-setup 을 실행해주세요.
```

`gh auth login`은 브라우저 인터랙션이 필요하므로 Claude가 직접 실행하지 마세요. 안내만 제공하고 이 단계에서 멈추세요.

사용자가 완료를 알리면 인증 상태를 확인하세요:

```bash
gh auth status 2>&1
```

"Logged in" 메시지가 나오면 성공입니다. 실패하면 로그인 과정을 다시 안내하세요.

## 단계 6: 저장소 준비

**완료 조건:** `git rev-parse --git-dir`이 성공 (현재 디렉토리가 Git 저장소)

Git 저장소가 아닌 경우, AskUserQuestion으로 방법을 물어보세요:

- question: "현재 디렉토리는 Git 저장소가 아닙니다. 어떻게 시작하시겠습니까?"
- header: "저장소"
- options:
  - "기존 저장소 clone" — GitHub에 이미 있는 저장소를 가져옴
  - "새 저장소 만들기" — 현재 폴더를 Git 저장소로 초기화

clone을 선택한 경우:
저장소 URL을 물어본 후 실행하세요:

```bash
git clone <URL>
```

새 저장소를 선택한 경우:

```bash
git init
```

## 단계 7: GitHub 원격 저장소 연결

**완료 조건:** `git remote get-url origin`이 GitHub URL을 반환함

원격 저장소가 없는 경우 (`no-remote`), AskUserQuestion으로 방법을 물어보세요:

- question: "GitHub에 원격 저장소를 만들겠습니까?"
- header: "원격 저장소"
- options:
  - "새 저장소 만들기 (Recommended)" — GitHub에 저장소를 생성하고 자동으로 연결합니다
  - "기존 저장소 연결" — 이미 GitHub에 있는 저장소 URL을 직접 입력

### 새 저장소 만들기

AskUserQuestion으로 공개 여부를 물어보세요:

- question: "저장소를 공개(public)로 만들까요, 비공개(private)로 만들까요?"
- header: "공개 여부"
- options:
  - "Public" — 누구나 볼 수 있음
  - "Private (Recommended)" — 나만 볼 수 있음 (나중에 변경 가능)

현재 디렉토리 이름을 저장소 이름으로 사용합니다:

```bash
gh repo create $(basename "$PWD") --source=. --remote=origin --<public|private>
```

`--source=.`는 현재 디렉토리를 소스로 사용하고, `--remote=origin`은 자동으로 remote를 추가합니다.

### 기존 저장소 연결

저장소 URL을 물어본 후 실행하세요:

```bash
git remote add origin <URL>
```

### 확인

연결 후 확인하세요:

```bash
git remote -v
```

origin의 fetch/push URL이 출력되면 성공입니다.

## 단계 8: 원격 브랜치 초기화 (첫 push)

**완료 조건:** `git ls-remote --heads origin main 2>/dev/null`이 결과를 반환함 (원격에 main 브랜치가 존재)

아래 명령어로 확인하세요:

```bash
git ls-remote --heads origin main 2>/dev/null | grep -q main && echo "remote-branch: exists" || echo "remote-branch: none"
```

원격에 main 브랜치가 없는 경우 (새로 만든 저장소), 초기 커밋을 만들고 push하세요:

```bash
git log --oneline -1 2>/dev/null
```

커밋이 하나도 없으면 초기 커밋을 만드세요:

```bash
git add -A
git commit -m "chore: initial commit"
```

원격에 push하세요:

```bash
git push -u origin main
```

사용자에게 설명하세요:

```
GitHub에 main 브랜치를 생성했습니다.
이제 원격 저장소와 로컬이 연결되었습니다.
```

## 단계 9: 작업 환경 선택

AskUserQuestion으로 작업 환경을 물어보세요:

- question: "이 저장소는 혼자 사용하나요, 팀으로 사용하나요?"
- header: "작업 환경"
- options:
  - "개인 프로젝트" — 혼자 작업하는 저장소 (git hooks 설치 생략)
  - "팀 프로젝트 (Recommended)" — 여러 명이 함께 작업 (git hooks로 브랜치 보호)

### 팀 프로젝트를 선택한 경우

**완료 조건:** `.git/hooks/pre-commit`, `.git/hooks/commit-msg`, `.git/hooks/pre-push` 파일이 모두 존재하고 실행 권한이 있음

아래 명령어로 확인하세요:

```bash
for hook in pre-commit commit-msg pre-push; do test -x .git/hooks/$hook && echo "$hook: exists" || echo "$hook: none"; done
```

없는 hook이 있으면, 플러그인의 템플릿 파일을 복사하여 설치하세요.
`PLUGIN_ROOT`는 이 플러그인의 `git-hooks/` 디렉토리 경로입니다: `${CLAUDE_PLUGIN_ROOT}/git-hooks`

```bash
cp ${CLAUDE_PLUGIN_ROOT}/git-hooks/pre-commit .git/hooks/pre-commit
cp ${CLAUDE_PLUGIN_ROOT}/git-hooks/commit-msg .git/hooks/commit-msg
cp ${CLAUDE_PLUGIN_ROOT}/git-hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/commit-msg .git/hooks/pre-push
```

이미 존재하는 hook은 덮어쓰지 마세요. 없는 것만 복사하세요.

각 hook의 역할을 사용자에게 설명하세요:

```
Git hook을 설치했습니다.

  pre-commit:  main/master에서 commit 차단 → 새 브랜치로 안내
  commit-msg:  conventional commits 형식 검증 (feat:, fix:, docs: 등)
  pre-push:    main/master로 push 차단 → 새 브랜치로 안내

터미널에서 직접 git을 사용할 때도 동일하게 보호됩니다.
```

### 개인 프로젝트를 선택한 경우

Git hooks 설치를 건너뛰고 바로 완료 메시지로 넘어가세요.

## 완료 메시지

모든 단계가 완료되면 설정 요약을 출력하세요:

```
Git 초기 설정이 완료되었습니다.

  이름:    <user.name>
  이메일:  <user.email>
  GitHub:  로그인됨
  저장소:  <현재 디렉토리>
  원격:    <origin URL>
  보호:    <"팀 — main 보호 + conventional commits (git hooks)" 또는 "개인 — 없음">

다음 단계: /git-onboarding-workflow 를 실행하면 브랜치 생성부터 PR까지 안내합니다.
```
