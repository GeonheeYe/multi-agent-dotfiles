---
name: pr-requirement-capture
description: Use when GH starts a message with "PR :" or "PR:". Treat the following text as a requirement that should be captured and worked through a GitHub pull-request workflow instead of remaining only in chat.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [github, pull-request, requirements, workflow, gh]
    related_skills: [github-pr-workflow, github-issues, writing-plans]
---

# PR Requirement Capture

## Overview

GH may send a message beginning with:

```text
PR : <요구사항>
PR: <요구사항>
```

This means: **save and execute the requirement through a GitHub PR workflow**, not just as an ephemeral Discord/chat instruction.

The goal is to make product/app changes traceable:

```text
Discord request → branch → requirement summary → implementation/checks → PR → GH review/merge
```

## When to Use

Use this skill when:

- The message starts with `PR :` or `PR:`.
- GH says in Korean or English that a request should be handled as a PR.
- GH wants a feature/change/bugfix to be preserved for formal development.
- The request targets a local Git project with a GitHub remote.

Do **not** use this skill for:

- Simple questions with no repository change.
- One-off operational checks.
- Emergency hotfixes where GH explicitly says to commit/push directly to `main`.

## Trigger Parsing

Strip only the leading trigger and whitespace:

```text
PR : Cursor dashboard CSV 기준으로 토큰 수집 바꿔줘
```

Requirement body:

```text
Cursor dashboard CSV 기준으로 토큰 수집 바꿔줘
```

If the body is empty, ask GH for the requirement using the clarification tool.

## Default Project Resolution

1. If the conversation is clearly about a current project, use that project path.
   - Example: AI usage board → `/home/geonhee/ai-usage-board`
2. Otherwise inspect the current working directory and `git remote -v`.
3. If multiple projects are plausible, ask one clarification question.

Before making changes, always inspect:

```bash
git status --short --branch
git remote -v
gh repo view <owner>/<repo> --json nameWithOwner,visibility,defaultBranchRef,url
```

## Workflow

### 1. Normalize the request

Create a concise Korean summary:

```text
요구사항: ...
목표: ...
완료 조건:
- ...
- ...
검증 방법:
- ...
```

If the request is ambiguous enough to change implementation, ask exactly one clarification question before editing code.

### 2. Create a branch

Use a short slug from the requirement:

```bash
git checkout -b feat/<slug>
```

For bug fixes:

```bash
git checkout -b fix/<slug>
```

If the request is only to save/track an idea and not implement yet, use:

```bash
git checkout -b chore/pr-request-<slug>
```

### 3. Implement or capture

Preferred behavior:

- If implementation is straightforward and safe, implement the change directly.
- If implementation is large/ambiguous, create a request note first under:

```text
docs/pr-requests/YYYY-MM-DD-<slug>.md
```

Suggested note template:

```markdown
# <PR Request Title>

## 원문 요청

> PR : ...

## 요구사항 정리

- ...

## 완료 조건

- [ ] ...

## 검증 방법

- [ ] ...

## 메모

- ...
```

### 4. Test and verify

Run the smallest relevant test/checks for the project.

Examples:

```bash
python3 -m unittest discover -s tests -q
python3 -m pytest -q
npm test
```

If a check fails because of environment/tooling, report it explicitly and distinguish it from code failure.

### 5. Commit and push branch

Commit message examples:

```text
feat: add cursor dashboard csv collection
fix: prevent duplicate cursor token counting
chore: capture PR request for cursor csv collection
```

Push:

```bash
git push -u origin <branch>
```

### 6. Open PR

Use GitHub CLI:

```bash
gh pr create \
  --title "<concise title>" \
  --body "$(cat /tmp/pr-body.md)" \
  --base main \
  --head <branch>
```

If implementation is not complete yet, create a draft PR:

```bash
gh pr create --draft --title "<title>" --body "$(cat /tmp/pr-body.md)"
```

PR body should include:

```markdown
## 요약
- ...

## 원문 요청
> PR : ...

## 변경 사항
- ...

## 검증
- [x] ...
- [ ] ... 미실행 사유: ...

## 리뷰 포인트
- ...
```

## User-Facing Response Pattern

Keep the final response short in Korean:

```text
PR로 저장/생성했어.

- repo: ...
- branch: ...
- PR: ...
- 상태: draft/open
- 검증: ...
```

If only a draft PR/request note was created:

```text
아직 구현은 안 했고, 요구사항을 draft PR로 저장했어.
다음에 이어서 구현하면 이 PR 기준으로 진행하면 돼.
```

## Common Pitfalls

1. **Treating `PR :` as normal chat.** It is a workflow trigger; create a branch/PR or ask the one missing clarification needed to do so.
2. **Pushing to `main`.** After initial baseline, formal changes should go through branches and PRs unless GH explicitly asks for direct push.
3. **Creating a PR without a useful body.** Preserve the original request and acceptance criteria so GH can review later.
4. **Forgetting repo state.** Always check branch, dirty files, and remote before making changes.
5. **Over-asking.** If the default project is obvious from context, proceed. Ask only if project choice or implementation scope is genuinely ambiguous.
6. **Claiming tests passed without running them.** If tests cannot run due to missing tools, say exactly which tool was missing.

## Verification Checklist

- [ ] Trigger `PR :` / `PR:` was stripped and the requirement body preserved.
- [ ] Correct repository and remote were identified.
- [ ] Work was done on a non-main branch unless GH explicitly requested direct main work.
- [ ] Requirement was implemented or saved under `docs/pr-requests/`.
- [ ] Relevant checks were run or environment failure was reported.
- [ ] Branch was pushed.
- [ ] PR URL was returned to GH.
