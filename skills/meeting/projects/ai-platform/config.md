---
name: AI 플랫폼 회의 고정 설정
description: LG U+ 대상 AI 플랫폼 PoC 회의의 조직 역할, 참석자, Notion 기준 문서, 요약 규칙 — project:ai-platform 로드
type: project
---

## 프로젝트 개요

- 목적: LG U+ 대상 PoC에서 AI 플랫폼 위의 ML 이상탐지, RCA 연계, MLOps 및 인프라 활용 가능성을 검증한다.
- 주요 범위: CDR/XDR·KPI 기반 이상탐지, 기존 Rule-based RCA 연계, MLflow 기반 모델 관리, Dify/Agent Builder 기반 워크플로우와 LLM 보고서, GPU 운영 검토
- 정리 원칙: 회의록 원문 전체를 복사하지 않고, 반복해서 사용할 역할·용어·결정·검증 기준만 기록한다.
- 일정은 회의별로 변경될 수 있으므로 이 고정 설정에 저장하지 않고 해당 회의록의 결정사항과 액션 아이템에만 기록한다.

## 조직 역할

| 조직 | 역할 |
|------|------|
| LIG Accuver(당사) | PoC 주관·리드, 고객 대응, 시나리오와 검증 범위 조율 |
| LIG System | 고객 대면이 어려우며, AI 플랫폼과 기술 구현을 지원 |
| LG U+ | 고객사, PoC에서 확인할 기능과 운영 요구사항 제시 |

## 확인된 인물

| 이름 | 소속/역할 |
|------|-----------|
| 이주승 | 수석 |
| 이한선 | 프로 |
| 조호진 | LIG Accuver 참석자 |
| 이권우 | LIG Accuver 참석자 |
| 허하람 | LIG Accuver 참석자 |
| 김형민 | LIG Accuver 참석자 |
| 배용호 | LIG Accuver 참석자 |
| 예건희 | LIG Accuver 참석자 |

- 표에 없는 소속·직급·담당 영역은 추정하지 않는다.
- 이주승 수석과 이한선 프로의 소속은 기준 문서에서 명확히 확인되기 전까지 고정하지 않는다.

## Notion 기준 문서

- [AI 플랫폼 회의록 상위 페이지](https://app.notion.com/p/395775f3955e80e88b49d70473ebab6a)
- [2026-07-01 회의록](https://app.notion.com/p/396775f3955e8052943bf788d6665c82)
- [2026-07-07 회의록](https://app.notion.com/p/396775f3955e80fe8119f481d9e7bd5d)
- [2026-07-20 실시간 이상탐지·MLOps PoC 회의록](https://app.notion.com/p/3a3775f3955e81418599e9d75af35431)
- [2026-07-23 이상탐지 PoC·MLOps 구현 회의록](https://app.notion.com/p/3a6775f3955e81359857ccfb2f66d1b8)
- [2026-08-05 LIG PoC 일정·RCA·MLOps 회의록](https://app.notion.com/p/3b3775f3955e813f9db8cde877c8aa49)

## Notion 자동 업로드

```yaml
notion_auto_upload: true
notion_connector: notion-work
notion_parent_page_id: 395775f3955e80e88b49d70473ebab6a
notion_parent_page_url: https://app.notion.com/p/395775f3955e80e88b49d70473ebab6a
notion_duplicate_policy: exact_title_update
notion_content_mode: replace
notion_include_transcript: false
```

- 위 YAML 블록을 자동 업로드의 단일 기준값으로 사용한다. 아래 설명은 설정의 의미만 해설하며 값을 다시 정의하지 않는다.
- `project:ai-platform` 처리가 완료되면 업로드 대상을 묻지 않고 설정된 parent의 일반 자식 페이지를 생성하거나, 같은 `YYYY.MM.DD - {회의제목}`이 정확히 하나 있으면 본문 전체를 교체한다.
- 본문은 `회의 요약` → `주요 결정사항` → `액션 아이템` → `확인 필요` 순서이며 전체 대화록은 제외한다.
- workspace의 목록 조회, 페이지 읽기, 생성, 수정, 최종 검증은 모두 동일한 `notion-work` connector만 사용한다.
- 직계 자식 전체 조회가 완료되지 않거나 정확히 같은 제목이 2개 이상이면 변경하지 않는다. 생성 직전과 변경 후에도 직계 자식 전체를 다시 확인한다.
- 실패 시 공용 Notion DB나 Dooray로 우회하지 않고 원본 JSON을 유지한다.
- 이 정책의 실행 절차는 `../../references/project-notion-auto-upload.md`를 따른다.

## 출처 우선순위

1. 사용자가 직접 확인하거나 수정한 사실
2. 위 Notion 기준 문서에 명시된 결정과 용어
3. 녹음 및 STT 원문

- 출처가 충돌하면 자동으로 합치지 않고 `확인 필요`로 남긴다.
- STT에서 들린 표현만으로 제품명, 직급, 소속, 일정 또는 기술 구성을 확정하지 않는다.

## 요약 형식 규칙

- `회의 요약`에 한 줄 요약과 주요 논의를 포함하고, `주요 결정사항`, `액션 아이템`, `확인 필요` 순서로 정리한다.
- LIG Accuver가 PoC를 주관·리드하고 고객 대응을 맡는다는 역할 구분을 유지한다.
- LIG System은 AI 플랫폼·기술 구현 지원 조직으로 기록하며, 고객 대면 주체로 쓰지 않는다.
- 이상탐지에서 RCA로 이어지는 입력 데이터, 모델, 실행 위치, 결과 전달 흐름을 구분해 적는다.
- `현재 구현`, `PoC에서 검증`, `후보/제안`을 섞지 않는다.
- 확정되지 않은 일정은 날짜를 단정하지 않고, 논의 시점의 목표 또는 확인 필요 항목으로 표시한다.
- 담당자와 기한이 명확할 때만 액션 아이템에 넣고, 직급이 확인되지 않은 참석자에게 직급을 붙이지 않는다.
- 애매한 용어는 `terms.md`의 `확인 필요 용어`를 참고해 원문과 후보를 함께 남긴다.

## 회의록 템플릿

```markdown
# YYYY.MM.DD - {회의제목}

## 회의 요약
- 한 줄 요약: 핵심 결론 1줄
- 주요 논의:
  - PoC 시나리오/고객 요구사항
  - 이상탐지·RCA·MLOps 구현 흐름
  - 플랫폼·인프라 검토 내용

## 주요 결정사항
- 결정: ...
  - 근거: ...

## 액션 아이템
| 담당자 | 할 일 | 기한 | 상태 |
|---|---|---|---|
<!-- 담당자와 기한이 확인된 항목만 추가 -->

## 확인 필요
- 용어, 범위, 일정 또는 담당자 확인 항목
```
