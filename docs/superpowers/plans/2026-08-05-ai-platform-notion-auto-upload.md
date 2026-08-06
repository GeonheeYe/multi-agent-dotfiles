# AI 플랫폼 Notion 자동 업로드 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `project:ai-platform` 회의가 지정된 Notion parent 아래에 자동 생성되고 같은 날짜·제목이면 기존 페이지를 업데이트하도록 meeting 스킬을 확장한다.

**Architecture:** 프로젝트 `config.md`가 구조화된 자동 업로드 대상과 정책을 선언하고, `meeting/SKILL.md`가 일반 업로드 선택보다 먼저 reference 프로토콜을 로드한다. `notion-work`의 paginated block children API로 직계 자식 전체를 열거하고, 생성 직전과 mutation 후 다시 조회해 경쟁 상태를 검증한다. 최종 title·parent·정규화된 본문 전체가 일치해야 성공이다.

**Tech Stack:** Markdown skill instructions, notion-work MCP block/page/markdown APIs

---

## Chunk 1: 프로젝트 자동 업로드 설정과 스킬 동작

### Task 1: RED baseline 기록

**Files:**
- Read: `skills/meeting/SKILL.md`
- Read: `skills/meeting/projects/ai-platform/config.md`

- [x] **Step 1: 수정 전 시나리오 실행**

Scenario: `/meeting audio.wav LIG PoC 회의 project:ai-platform`, 날짜 `2026-08-06`, 사용자 추가 입력 없음.

Expected baseline: 프로젝트 config 미로드, 업로드 대상 질문, 공용 DB 신규 생성, 중복 업데이트 없음.

- [x] **Step 2: 실패 원인 기록**

Observed: 기대 요구사항 세 항목이 모두 충족되지 않음.

### Task 2: 프로젝트 설정 추가

**Files:**
- Modify: `skills/meeting/projects/ai-platform/config.md`

- [x] **Step 1: Notion 자동 업로드 설정 작성**

자동 업로드, connector, parent ID·URL, 중복 정책, replace 모드, 대화록 제외를 YAML 단일 기준값으로 추가한다.

- [x] **Step 2: 설정 검증**

Run: `rg -n 'notion_auto_upload|notion_connector|notion_parent_page_id|notion_duplicate_policy|notion_content_mode|notion_include_transcript' skills/meeting/projects/ai-platform/config.md`

Expected: 자동 업로드 대상과 중복 정책이 모두 출력된다.

### Task 3: meeting 스킬 동작 변경

**Files:**
- Modify: `skills/meeting/SKILL.md`
- Create: `skills/meeting/references/project-notion-auto-upload.md`

- [x] **Step 1: 프로젝트 설정 로드 규칙 추가**

`project`가 있을 때 `terms.md`와 `config.md`를 모두 읽고, config의 자동 업로드가 활성화되면 프로젝트 정책을 적용하도록 명시한다.

- [x] **Step 2: 프로젝트 전용 자동 업로드 분기 추가**

SKILL에는 trigger와 필수 reference 로드만 두고, reference에 유효한 ISO 날짜·NFKC 제목 정규화와 `API_get_block_children`의 page size 100 페이지네이션을 작성한다. 최대 20페이지/2,000블록, cursor 누락·반복, `has_more=false` 완료 조건을 적용하고 `child_page` exact title 후보만 `API_retrieve_a_page`로 검증한다. 1개 update는 mutation 직전 title·parent를 다시 retrieve해 완전 일치시킨다.

- [x] **Step 3: 안전·오류 처리 추가**

업로드 대상 질문 생략, 전체 대화록 제외, create/update 전 `notion://docs/enhanced-markdown-spec` 조회, 생성 직전 전체 재조회, mutation 후 exact title 유일성 재조회, 정규화된 본문 전체 검증을 명시한다. child 생성은 `API_post_page`의 page parent·title property payload를, 본문 교체는 `API_update_page_markdown`의 `type=replace_content`와 `allow_deleting_content=false` payload를 사용한다. notion-work mutation은 동기 API이므로 async polling을 두지 않으며, 권한 오류나 검증 실패 시 우회 금지와 로컬 JSON 보존을 적용한다.

- [x] **Step 4: 정적 검증**

Run: `rg -n 'config.md|프로젝트 전용 Notion 자동 업로드|REQUIRED|project-notion-auto-upload|AskUserQuestion 흐름' skills/meeting/SKILL.md && rg -n 'API_get_block_children|page_size=100|2,000|생성 직전|API_post_page|API_update_page_markdown|API_retrieve_page_markdown|본문 전체|원격 상태 불명확' skills/meeting/references/project-notion-auto-upload.md`

Expected: 로드·create/update·중복·안전 규칙이 모두 출력된다.

### Task 4: GREEN 시나리오 검증

**Files:**
- Verify: `skills/meeting/SKILL.md`
- Verify: `skills/meeting/projects/ai-platform/config.md`
- Verify: `skills/meeting/references/project-notion-auto-upload.md`

- [x] **Step 1: 동일 시나리오를 수정된 스킬로 재실행**

Expected: `project:ai-platform` 설정을 읽고 질문 없이 지정 parent에 저장한다. paginated 직계 자식 전체에서 0개면 생성 직전 재확인 후 생성하고, 1개면 덮어쓰기 안내 후 수정하며, 2개 이상이면 중단한다. mutation 후 유일성과 title·parent·본문 전체를 검증한다.

Observed: 실제 Notion mutation 없이 정적 시뮬레이션으로 `✅ GREEN PASS`를 확인했다.

- [x] **Step 2: 비대상 프로젝트 회귀 확인**

Expected: `project:팀회의` 또는 프로젝트 미지정 시 기존 업로드 선택 질문을 유지한다.

Observed: 실제 Notion mutation 없이 정적 시뮬레이션으로 `✅ REGRESSION PASS`를 확인했다.

- [x] **Step 3: Git 및 문서 형식 검증**

Run: `git diff --check && git status --short -- skills/meeting/SKILL.md skills/meeting/projects/ai-platform/config.md skills/meeting/references/project-notion-auto-upload.md docs/superpowers/specs/2026-08-05-ai-platform-notion-auto-upload-design.md docs/superpowers/plans/2026-08-05-ai-platform-notion-auto-upload.md`

Expected: 공백 오류가 없고 승인된 파일만 변경된다. 사용자 지침에 따라 commit/push는 실행하지 않는다.

검증 결과: 정적 필수 항목 검사와 `git diff --check`가 통과했으며, 실제 Notion mutation은 수행하지 않았다.
