# AI 플랫폼 Notion 자동 업로드 설계

## 목적

`/meeting ... project:ai-platform` 실행이 끝나면 별도 업로드 대상 질문 없이 AI 플랫폼의 Notion `회의록` 페이지 아래에 회의록을 저장한다. 같은 날짜와 회의 제목의 페이지가 이미 있으면 새 페이지를 만들지 않고 기존 페이지를 갱신한다.

## 현재 동작의 문제

- 프로젝트 실행 시 `terms.md`만 읽고 `config.md`는 읽지 않는다.
- 요약 후 업로드 대상을 다시 물으므로 자동 업로드가 아니다.
- Notion을 선택해도 프로젝트 페이지가 아닌 공용 회의록 데이터베이스를 사용한다.
- 기존 페이지 검색과 정확 일치 검증이 없어 중복 페이지가 생긴다.

## 설정

`skills/meeting/projects/ai-platform/config.md`에 다음 프로젝트 전용 설정을 둔다.

- YAML 구조화 필드: 자동 업로드, `notion-work` connector, parent page ID·URL
- 중복 정책 `exact_title_update`, 본문 정책 `replace`, 전체 대화록 제외
- 제목 형식: `YYYY.MM.DD - {회의제목}`
- 본문 순서: 회의 요약 → 주요 결정사항 → 액션 아이템 → 확인 필요
- workspace 데이터 작업은 동일한 `notion-work` connector만 사용

긴 실행 프로토콜은 `skills/meeting/references/project-notion-auto-upload.md`에 분리하고, `SKILL.md`는 실행 전 reference 전체 읽기를 필수로 지시한다.

## 처리 흐름

1. `project:ai-platform`을 파싱하면 `terms.md`와 `config.md`를 모두 읽는다.
2. JSON의 날짜와 회의 제목에서 기존 날짜 접두사를 제거하고 `YYYY.MM.DD - {회의제목}`을 만든다.
3. 요약 결과는 사용자에게 보여주되 업로드 대상 질문은 생략한다.
4. `API_get_block_children`을 page size 100으로 호출하고 `has_more=false`까지 cursor를 따라 parent 직계 자식 전체를 열거한다.
5. `child_page.title` 완전 일치 후보를 `API_retrieve_a_page`로 읽어 제목과 parent를 정확히 재검증한다.
   - 정확 일치 0개: parent 아래에 새 자식 페이지 생성
   - 정확 일치 1개: mutation 직전 title·parent를 다시 retrieve해 완전 일치하면 기존 페이지 본문 교체
   - 정확 일치 2개 이상: 임의로 고르지 않고 업로드 중단 후 중복 URL 안내
6. 0개 생성 직전 전체 목록을 다시 조회해 경쟁 생성을 확인한 뒤 create/update 분기를 재판정한다.
7. 생성 또는 수정 후 전체 목록을 다시 조회해 제목 유일성을 확인하고, 최종 Markdown을 정규화해 예상 본문 전체와 일치하는지 검증한다.

## Notion 작업 규칙

- create/update 전에 `notion://docs/enhanced-markdown-spec`을 fetch해 현재 Notion Markdown 규격을 확인한다.
- 중복 조회: `mcp__notion_work__API_get_block_children`을 최대 20페이지/2,000블록까지 페이지네이션한다. cursor 누락·반복, 한도 초과, 일부 실패 시 중단하며 `has_more=false`에서만 완전한 목록으로 인정한다.
- 생성: `mcp__notion_work__API_post_page`에 `parent.type=page_id`와 Notion title property 구조를 전달해 일반 child page를 만든 뒤 `API_update_page_markdown`에 `type=replace_content`, `replace_content.new_str`, `allow_deleting_content=false`를 전달한다.
- 수정: mutation 직전에 기존 페이지를 `API_retrieve_a_page`로 다시 검증한 뒤 생성 후 본문 저장과 동일한 `API_update_page_markdown` payload를 사용한다.
- notion-work mutation은 동기 API이므로 async polling을 사용하지 않는다. 응답이 불명확하면 재시도하지 않고 원격 상태 불명확으로 안내한다.
- 수정 시 `allow_deleting_content`를 켜지 않는다. 자식 페이지 삭제 위험이 감지되면 중단하고 사용자에게 알린다.
- mutation 후 전체 목록의 exact title 유일성을 재검증한다. 2개 이상이면 삭제·추가 수정 없이 모든 URL을 안내한다.
- `API_retrieve_page_markdown` 결과와 예상 본문을 CRLF, trailing whitespace, Unicode NFKC, 문서 끝 개행 기준으로 정규화한 뒤 전체 일치시킨다.
- Notion 도구가 없거나 권한 오류 또는 최종 검증 실패가 나면 공용 DB나 Dooray로 우회하지 않는다. 로컬 JSON을 유지하고, mutation 후 실패는 원격 상태 불명확으로 구분한다.

## 영향 범위

- `project:ai-platform`: 프로젝트 전용 Notion 자동 업로드 적용
- 다른 프로젝트 또는 프로젝트 미지정: 기존 업로드 선택 흐름 유지
- STT, 요약, Dooray 업로드 로직: 변경하지 않음

변경 파일:

- `skills/meeting/SKILL.md`
- `skills/meeting/projects/ai-platform/config.md`
- `skills/meeting/references/project-notion-auto-upload.md`

## 검증 기준

- 현재 스킬에 대한 baseline 시나리오가 자동 업로드·프로젝트 parent·중복 업데이트 항목에서 실패한다.
- 수정 후 동일 시나리오에서 프로젝트 설정 로드, 질문 생략, 정확 일치 create/update 분기를 모두 설명한다.
- parent 직계 자식 전체를 페이지네이션하고 생성 직전·변경 후 재조회해 중복과 경쟁 상태를 검증한다.
- notion-work 동기 mutation 후 title·parent·정규화된 본문 전체가 일치해야 성공이다.
- `config.md`에 parent ID `395775f3955e80e88b49d70473ebab6a`가 기록된다.
- 같은 제목이 여러 개면 임의 업데이트하지 않는 안전 규칙이 존재한다.
- 다른 프로젝트의 기존 업로드 선택 흐름은 유지된다.
