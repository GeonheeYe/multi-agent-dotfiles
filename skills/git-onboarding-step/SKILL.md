---
name: git-onboarding-step
description: Git 설정부터 PR까지의 전체 진행 상황을 체크리스트로 보여주고 현재 단계를 안내합니다. "어디까지 했지?", "진행 상황", "다음 단계" 같은 질문에 사용됩니다.
---

# Git 진행 상황 체크리스트

전체 10단계의 진행 상황을 확인하고 현재 단계를 안내합니다.
이 스킬은 상태만 보여주고, 실제 실행은 /git-onboarding-setup 또는 /git-onboarding-workflow에 위임합니다.

## 상태 수집

아래 명령어를 **모두 병렬로** 실행하세요:

1. `which git` — Git 설치 여부
2. `git config --global user.name` — 사용자 이름
3. `git config --global user.email` — 이메일
4. `which gh 2>/dev/null && echo "installed" || echo "none"` — GitHub CLI 설치 여부
5. `gh auth status 2>&1` — GitHub 인증 상태
6. `git rev-parse --git-dir 2>/dev/null && echo "repo" || echo "no-repo"` — 저장소 여부
7. `git branch --show-current 2>/dev/null` — 현재 브랜치
8. `git log --oneline -1 2>/dev/null` — 커밋 존재 여부
9. `git log @{u}.. --oneline 2>/dev/null` — 미push 커밋
10. `which gh >/dev/null 2>&1 && gh pr list --head "$(git branch --show-current 2>/dev/null)" --json number --jq '.[0].number' 2>/dev/null || echo "gh-unavailable"` — PR 존재 여부

## 체크리스트 판정

각 항목의 완료 조건:

| 단계 | 항목 | 완료 조건 |
|---|---|---|
| 1 | Git 설치 | `which git`이 경로를 반환 |
| 2 | 사용자 이름 설정 | `git config --global user.name`이 비어있지 않음 |
| 3 | 이메일 설정 | `git config --global user.email`이 비어있지 않음 |
| 4 | GitHub CLI 설치 | `which gh`가 경로를 반환 |
| 5 | GitHub 로그인 | `gh auth status` 출력에 "Logged in" 포함 |
| 6 | 저장소 준비 | `git rev-parse --git-dir` 성공 |
| 7 | 브랜치 생성 | 현재 브랜치가 main/master가 아닌 feature 브랜치 |
| 8 | 첫 번째 커밋 | `git log --oneline -1`이 결과를 반환 |
| 9 | Push | `git log @{u}..`이 빈 결과 (미push 커밋 없음) |
| 10 | Pull Request 생성 | gh CLI로 현재 브랜치의 PR 번호가 확인됨 |

### 특수 판정 규칙

- **단계 7**: main/master에 있으면 미완료. 단, 저장소가 없으면(단계 6 미완료) 판정 불가 → 미완료 처리
- **단계 9**: upstream이 설정되지 않아 명령어가 실패하면 미완료
- **단계 10**: gh CLI가 미설치(`gh-unavailable`)이면 "확인 불가"로 표시

## 출력 형식

코드 블록 안에 아래 형식으로 출력하세요.
- 완료된 항목: `[x]`
- 미완료 항목: `[ ]`
- 첫 번째 미완료 항목 옆에: `<-- 현재 단계`
- 단계 2, 3은 완료 시 설정값을 괄호 안에 표시
- 단계 10이 확인 불가면: `[?]`로 표시

```
Git 시작하기 — 현재 진행 상황

  [x] 1. Git 설치
  [x] 2. 사용자 이름 설정 (홍길동)
  [x] 3. 이메일 설정 (user@email.com)
  [x] 4. GitHub CLI 설치
  [ ] 5. GitHub 로그인            <-- 현재 단계
  [ ] 6. 저장소 준비
  [ ] 7. 브랜치 생성
  [ ] 8. 첫 번째 커밋
  [ ] 9. Push
  [ ] 10. Pull Request 생성
```

## 현재 단계 설명

체크리스트 출력 후, 첫 번째 미완료 단계에 대해 아래 내용을 안내하세요:

### 단계 1: Git 설치
- **왜 필요한지:** Git은 코드의 변경 이력을 관리하는 도구입니다. 모든 작업의 기반이 됩니다.
- **해결 방법:** `/git-onboarding-setup` 을 실행하세요.

### 단계 2: 사용자 이름 설정
- **왜 필요한지:** 커밋할 때 "누가 이 변경을 했는지" 기록됩니다. 협업 시 필수입니다.
- **해결 방법:** `/git-onboarding-setup` 을 실행하세요.

### 단계 3: 이메일 설정
- **왜 필요한지:** GitHub가 커밋과 계정을 연결하는 데 사용됩니다. GitHub 계정 이메일과 일치해야 잔디(contribution)가 심어집니다.
- **해결 방법:** `/git-onboarding-setup` 을 실행하세요.

### 단계 4: GitHub CLI 설치
- **왜 필요한지:** GitHub CLI(gh)는 터미널에서 GitHub 로그인, PR 생성 등을 쉽게 할 수 있는 도구입니다.
- **해결 방법:** `/git-onboarding-setup` 을 실행하세요.

### 단계 5: GitHub 로그인
- **왜 필요한지:** GitHub에 로그인해야 push/pull과 PR 생성이 가능합니다.
- **해결 방법:** `/git-onboarding-setup` 을 실행하세요.

### 단계 6: 저장소 준비
- **왜 필요한지:** Git으로 관리할 프로젝트 폴더가 필요합니다. clone(기존 프로젝트) 또는 init(새 프로젝트)으로 시작합니다.
- **해결 방법:** `/git-onboarding-setup` 을 실행하세요.

### 단계 7: 브랜치 생성
- **왜 필요한지:** main 브랜치는 완성된 코드만 유지합니다. 새 기능은 별도 브랜치에서 작업해야 안전합니다.
- **해결 방법:** `/git-onboarding-workflow` 를 실행하세요.

### 단계 8: 첫 번째 커밋
- **왜 필요한지:** 커밋은 작업의 "저장 지점"입니다. 언제든 이 시점으로 돌아올 수 있습니다.
- **해결 방법:** `/git-onboarding-workflow` 를 실행하세요.

### 단계 9: Push
- **왜 필요한지:** 로컬 커밋을 GitHub에 올려야 다른 사람이 볼 수 있고, 백업도 됩니다.
- **해결 방법:** `/git-onboarding-workflow` 를 실행하세요.

### 단계 10: Pull Request 생성
- **왜 필요한지:** PR은 "이 변경을 main에 합쳐주세요"라는 요청입니다. 코드 리뷰를 받을 수 있습니다.
- **해결 방법:** `/git-onboarding-workflow` 를 실행하세요.

## 전체 완료 시

10개 항목이 모두 완료되면:

```
Git 시작하기 — 전체 완료!

  [x] 1. Git 설치
  [x] 2. 사용자 이름 설정 (...)
  [x] 3. 이메일 설정 (...)
  [x] 4. GitHub CLI 설치
  [x] 5. GitHub 로그인
  [x] 6. 저장소 준비
  [x] 7. 브랜치 생성
  [x] 8. 첫 번째 커밋
  [x] 9. Push
  [x] 10. Pull Request 생성

축하합니다! Git 설정부터 PR 생성까지 모든 과정을 완료했습니다.
이제 GitHub Flow에 따라 자유롭게 개발하세요.
```
