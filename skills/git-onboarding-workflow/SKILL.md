---
name: git-onboarding-workflow
description: 현재 git 상태를 분석하고 GitHub Flow 기준으로 다음 단계를 안내합니다. "다음에 뭐 해야 돼?", "워크플로우", "git 흐름" 같은 질문에 사용됩니다.
---

# GitHub Flow 워크플로우 가이드

현재 git 상태를 분석하고 다음 단계를 안내합니다.

## 상태 수집

아래 3개 명령어를 실행하세요:

1. `git branch --show-current` — 현재 브랜치
2. `git status --short` — 작업 트리 상태
3. `git log @{u}.. --oneline 2>/dev/null` — 미push 커밋 (upstream이 없으면 빈 결과)

## 상태별 안내

결과를 분석하여 아래 5가지 중 해당하는 상황을 안내하세요:

### 1. main 브랜치, 변경 없음

새 작업을 시작할 준비가 되었습니다.

```
git checkout -b feat/<기능명>
```

브랜치 이름은 `feat/`, `fix/`, `chore/` 등 conventional 접두사를 사용하세요.

### 2. main 브랜치, 변경 있음

main에서 직접 작업한 내용이 있습니다. feature 브랜치로 옮기세요.

```
git stash
git checkout -b feat/<기능명>
git stash pop
```

### 3. feature 브랜치, 미커밋 변경 있음

작업 내용을 커밋하세요.

```
git add <파일들>
git commit -m "feat: 변경 내용 설명"
```

커밋 메시지는 conventional commits 형식을 따르세요.

### 4. feature 브랜치, 미push 커밋 있음

원격에 push하고 PR을 생성하세요.

```
git push -u origin HEAD
gh pr create --fill
```

### 5. feature 브랜치, clean 상태

모든 변경이 push된 상태입니다. PR 상태를 확인하세요.

```
gh pr status
```

PR이 없다면 생성하세요: `gh pr create --fill`
