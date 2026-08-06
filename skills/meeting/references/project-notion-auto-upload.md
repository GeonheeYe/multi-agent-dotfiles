# 프로젝트 전용 Notion 자동 업로드

프로젝트 `config.md`가 자동 업로드를 활성화한 경우에만 사용하는 필수 실행 절차다. 이 분기에 진입한 뒤에는 성공·실패와 관계없이 공용 Notion DB 또는 Dooray 선택 흐름으로 내려가지 않는다.

## 1. 설정 검증

`config.md`의 `## Notion 자동 업로드` 바로 아래 YAML 블록에서 다음 필드를 읽는다.

```yaml
notion_auto_upload: true
notion_connector: notion-work
notion_parent_page_id: PAGE_ID
notion_parent_page_url: PAGE_URL
notion_duplicate_policy: exact_title_update
notion_content_mode: replace
notion_include_transcript: false
```

- `notion_auto_upload`가 `true`이고 parent ID/URL이 설정된 경우에만 이 절차를 실행한다.
- 자동 업로드가 켜졌지만 필수 필드가 없거나 값이 위 정책과 다르면 업로드를 중단한다.
- parent ID와 URL의 page ID를 정규화해 동일한지 확인한다. 다르면 중단한다.
- workspace의 목록 조회, 페이지 읽기, 생성, 수정, 검증은 모두 `notion-work` connector만 사용한다. 다른 workspace connector로 fallback하거나 결과를 섞지 않는다.
- create/update 전에 수행하는 `notion://docs/enhanced-markdown-spec` 조회는 workspace mutation과 별개인 문서 규격 조회이므로 같은 connector 제한에서 제외한다.
- 중단할 때는 `SKILL.md` Step 2에서 생성된 원본 JSON 파일을 보존하고 경로와 원인을 안내한다.

## 2. 제목과 본문 준비

### 제목

1. JSON `date`가 정확히 `YYYY-MM-DD` 형식이고 실제 그레고리력 달력에 존재하는 날짜인지 파싱해 확인한다. 파싱 후 같은 형식으로 되돌린 값이 원본과 다르면 유효하지 않은 값이다.
2. JSON `title`을 사용하고, 비어 있으면 ARGUMENTS에서 파싱한 회의 제목을 사용한다.
3. 제목에 Unicode NFKC 정규화를 적용하고 NBSP(`U+00A0`)를 일반 space로 바꾼다. 연속된 Unicode whitespace는 space 하나로 축약한 뒤 앞뒤를 trim한다.
4. 제목 맨 앞에서 다음 날짜 접두사를 반복 제거한다. 날짜 내부 구분자와 제목 앞 구분자는 hyphen(`-`), en dash(`–`), em dash(`—`) 변형을 모두 허용한다.
   - `[YYYY-MM-DD]` 뒤의 선택적 제목 구분자
   - `YYYY-MM-DD` 뒤의 선택적 제목 구분자
   - `YYYY.MM.DD` 뒤의 필수 제목 구분자
5. 접두사를 제거할 때마다 3번의 whitespace 정규화를 다시 적용한다. 결과가 비면 중단한다.
6. JSON `date`를 `YYYY.MM.DD`로 바꿔 최종 제목 `YYYY.MM.DD - {정리된 회의 제목}`을 한 번만 만든다.

### 본문

프로젝트 요약 정책을 적용해 Enhanced Markdown 본문을 만든다.

```markdown
## 회의 요약
- 한 줄 요약: ...
- 주요 논의:
  - ...

## 주요 결정사항
- ...

## 액션 아이템
- [ ] ...

## 확인 필요
- ...
```

- `회의 요약`에는 한 줄 요약과 주요 논의를 모두 포함한다.
- transcript 전체 대화록은 포함하지 않는다.
- 사용자에게 이 네 섹션의 요약 미리보기를 보여주되 업로드 대상을 묻지 않는다.

## 3. 직계 자식 전체 열거

다음 절차를 하나의 `list_direct_child_pages(parent_page_id)` 동작으로 사용한다.

1. `mcp__notion_work__API_get_block_children`을 `block_id=parent_page_id`, `page_size=100`으로 호출한다. 첫 호출에는 cursor를 넣지 않는다.
2. 각 성공 응답의 `results`를 누적하고 호출 횟수, 누적 블록 수, 사용한 cursor를 기록한다.
3. `has_more=true`이면 `next_cursor`가 존재하고 이전에 사용한 적이 없는지 확인한 뒤 다음 호출의 `start_cursor`로 사용한다.
4. `has_more=false`가 반환된 경우에만 전체 목록 조회 성공으로 인정한다.
5. 최대 20페이지 또는 누적 2,000블록까지만 허용한다. `has_more=true`인 채 한도에 도달하거나 cursor가 없거나 반복되거나 일부 호출이 실패하면 목록을 불완전한 것으로 보고 중단한다.
6. 완료된 전체 결과 중 `type=child_page`인 블록만 후보로 사용한다. 다른 블록이나 의미 검색 결과는 후보 수 계산에 사용하지 않는다.

`child_page.title`과 목표 제목을 문자열 완전 일치로 비교한다. 완전 일치한 각 후보는 `mcp__notion_work__API_retrieve_a_page`로 읽어 실제 title과 parent page ID를 다시 확인한다. 조회 실패, title 불일치, parent 불일치가 하나라도 있으면 안전하게 중단한다.

## 4. 중복 판정과 mutation

mutation 전에 문서 규격 조회 도구로 `notion://docs/enhanced-markdown-spec`을 fetch한다. 실패하면 변경하지 않는다.

### 최초 후보가 2개 이상

변경하지 않고 검증된 모든 중복 페이지 URL을 안내한다.

### 최초 후보가 1개

1. mutation 직전에 사용자에게 `기존 본문 전체를 교체하며 수동 편집 내용도 덮어씁니다.`라고 비차단 안내한다.
2. mutation 직전에 `mcp__notion_work__API_retrieve_a_page`를 다시 호출해 실제 title과 parent page ID가 목표값과 완전히 일치하는지 재검증한다. 조회 실패 또는 불일치면 mutation하지 않는다.
3. `mcp__notion_work__API_update_page_markdown`을 다음 payload로 호출한다.

```json
{
  "page_id": "기존 페이지 ID",
  "type": "replace_content",
  "replace_content": {
    "new_str": "준비한 전체 본문",
    "allow_deleting_content": false
  }
}
```

자식 page/database 삭제 위험 경고가 발생하면 승인하지 말고 중단한다.

### 최초 후보가 0개

1. 생성 직전에 `list_direct_child_pages`를 처음부터 다시 실행하고 정확 일치 후보를 재검증한다.
2. 재조회 결과가 1개면 생성하지 않고 위의 1개 update 분기로 전환한다. 2개 이상이면 중복 URL을 안내하고 중단한다.
3. 여전히 0개일 때만 `mcp__notion_work__API_post_page`를 다음 payload로 호출해 설정된 parent 아래에 일반 child page를 생성한다. database parent로 바꾸지 않는다.

```json
{
  "parent": {
    "type": "page_id",
    "page_id": "config의 notion_parent_page_id"
  },
  "properties": {
    "title": {
      "type": "title",
      "title": [
        {
          "type": "text",
          "text": {
            "content": "YYYY.MM.DD - 회의제목"
          }
        }
      ]
    }
  }
}
```

4. 생성 응답의 page ID를 사용해 `mcp__notion_work__API_update_page_markdown`을 다음 payload로 호출한다. 기존 페이지 update와 동일한 `replace_content` 구조이며 append하지 않는다.

```json
{
  "page_id": "생성된 페이지 ID",
  "type": "replace_content",
  "replace_content": {
    "new_str": "준비한 전체 본문",
    "allow_deleting_content": false
  }
}
```

`notion-work`의 mutation API는 동기 호출이다. `async_task` polling 절차를 사용하지 않는다. mutation 응답이 성공인지 명확하지 않으면 자동 재시도하지 말고 `원격 상태 불명확`으로 분류해 반환된 page ID/URL이 있으면 함께 안내하고 원본 JSON 경로를 유지한다.

## 5. 변경 후 경쟁 상태와 최종 검증

1. 생성 또는 수정 후 `list_direct_child_pages`를 다시 전체 실행한다.
2. 목표 제목의 검증된 직계 자식이 정확히 1개인지 확인한다.
3. 동시 실행으로 2개 이상이 됐으면 자동 삭제하거나 추가 수정하지 않는다. 일치한 모든 URL과 이번 실행에서 생성한 URL을 구분해 안내하고 중단한다.
4. 0개이거나 목록이 불완전해도 추가 mutation 없이 `원격 상태 불명확`으로 종료한다.
5. 유일한 페이지를 `mcp__notion_work__API_retrieve_a_page`로 읽어 title과 parent page ID의 완전 일치를 다시 확인한다.
6. `mcp__notion_work__API_retrieve_page_markdown`으로 최종 본문을 읽는다.

예상 본문과 조회 본문 양쪽에 다음 정규화를 같은 순서로 적용한다.

1. CRLF를 LF로 변환한다.
2. 각 줄의 trailing whitespace를 제거한다.
3. Unicode NFKC를 적용한다.
4. 문서 끝의 개행을 정확히 하나로 맞춘다.

정규화된 본문 전체가 byte-for-byte 동일해야 성공이다. 핵심 섹션 존재 여부만으로 성공 처리하지 않는다. title, parent, 본문 전체가 모두 일치하면 최종 페이지 URL을 안내한다.

## 6. 실패 처리

- mutation 전의 도구 없음, 권한 부족, 설정 오류, 조회 실패, 불완전한 페이지네이션 또는 Markdown 규격 조회 실패는 `업로드 실패`로 안내한다.
- mutation 응답이 불명확하거나, 페이지 생성 뒤 본문 저장이 실패하거나, mutation 후 유일성·title·parent·본문 전체 검증이 실패하면 `원격 상태 불명확`으로 안내한다.
- 어느 경우에도 공용 Notion DB나 Dooray로 우회하지 않고, generic 업로드 질문으로 돌아가지 않는다.
- 자동 재시도, 중복 자동 삭제, 임의 후보 선택을 하지 않는다.
- 원본 JSON 파일을 보존하고 그 경로, 실패 단계, 확인 가능한 page ID/URL을 안내한다.
