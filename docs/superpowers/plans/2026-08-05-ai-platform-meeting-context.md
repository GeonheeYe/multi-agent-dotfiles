# AI 플랫폼 회의 프로젝트 문맥 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Notion의 AI 플랫폼 회의록에서 검증된 프로젝트 문맥과 용어를 meeting skill용 설정 파일로 만든다.

**Architecture:** `config.md`는 프로젝트 범위와 회의록 작성 규칙을 담당하고, `terms.md`는 용어와 STT 교정을 담당한다. 확정 정보와 확인 필요 정보를 분리해 애매한 표현이 자동 교정에 사용되지 않게 한다.

**Tech Stack:** Markdown, meeting skill 프로젝트 설정, Notion 회의록

---

## Chunk 1: 프로젝트 문맥 파일 생성

### Task 1: 프로젝트 설정

**Files:**
- Create: `skills/meeting/projects/ai-platform/config.md`

- [ ] **Step 1: 기존 프로젝트 설정 형식 확인**

Run: `sed -n '1,240p' skills/meeting/projects/aegis-ap/config.md`

Expected: YAML frontmatter와 프로젝트 개요·담당자·요약 규칙 구조가 확인된다.

- [ ] **Step 2: AI 플랫폼 프로젝트 설정 작성**

Notion 출처, LIG Accuver/LIG System 역할, 확인된 인물, 요약 규칙을 작성한다.

- [ ] **Step 3: 설정 구조 검증**

Run: `rg -n '^(name|description|type):|LIG Accuver|LIG System|이주승|Notion' skills/meeting/projects/ai-platform/config.md`

Expected: frontmatter와 필수 역할·인물·출처가 모두 출력된다.

### Task 2: 용어 및 교정표

**Files:**
- Create: `skills/meeting/projects/ai-platform/terms.md`

- [ ] **Step 1: 확정 용어 작성**

여러 회의에서 반복 확인된 조직·통신·ML·플랫폼·인프라 용어와 짧은 정의를 작성한다.

- [ ] **Step 2: 확인 필요 용어 작성**

원문 표현, 가능한 의미, 근거 회의, 확인할 내용을 별도 표로 작성한다.

- [ ] **Step 3: 확정 STT 교정표 작성**

고유명사와 오인식 패턴 중 확정된 항목만 자동 교정표에 작성한다.

- [ ] **Step 4: 분리 원칙 검증**

Run: `rg -n '^## (확인 필요 용어|STT 오인식 교정 패턴)|확인 필요|ModelFlow|라이피' skills/meeting/projects/ai-platform/terms.md`

Expected: 확인 필요 표가 별도 존재하며 애매한 후보는 확정 교정으로 단정되지 않는다.

### Task 3: 변경 범위 확인

**Files:**
- Verify: `skills/meeting/projects/ai-platform/config.md`
- Verify: `skills/meeting/projects/ai-platform/terms.md`

- [ ] **Step 1: 내용과 Git 변경 범위 확인**

Run: `git diff --check && git status --short -- skills/meeting/projects/ai-platform docs/superpowers`

Expected: 공백 오류가 없고 새 프로젝트 파일과 설계·계획 문서만 표시된다.

- [ ] **Step 2: 커밋하지 않고 사용자에게 결과 보고**

사용자 지침에 따라 `git commit`과 `git push`는 실행하지 않는다.

