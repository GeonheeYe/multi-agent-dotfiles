---
name: my-context-sync
description: 나의 컨텍스트 싱크. 여러 소스에서 정보를 수집하고 하나의 문서로 정리한다. "싱크", "sync", "정보 수집" 요청에 사용.
triggers:
  - "싱크"
  - "sync"
  - "정보 수집"
  - "컨텍스트 싱크"
---

# My Context Sync

흩어진 정보를 한곳에 모아 정리하는 스킬.

Slack, Gmail, Google Calendar에서 최근 정보를 수집하고,
하나의 마크다운 문서로 통합한다.

## 소스 정의

### 소스 1: Slack

| 항목 | 값 |
|------|-----|
| MCP 도구 | `mcp__claude_ai_Slack__slack_read_channel` |
| 수집 범위 | 최근 7일 |

수집할 채널 목록:

<!-- 자신이 주로 사용하는 채널명으로 바꾸세요 -->
```yaml
channels:
  - name: "general"          # 전체 공지
  - name: "project-updates"  # 프로젝트 소식
  - name: "random"           # 자유 채널
```

수집 방법:
```
각 채널에 대해 mcp__claude_ai_Slack__slack_read_channel 호출.
채널명과 메시지 개수(limit)를 전달한다.

Connectors로 연결한 경우:
  mcp__claude_ai_Slack__slack_read_channel(channel="general", limit=50)

claude mcp add로 연결한 경우:
  mcp__slack__slack_read_channel(channel="general", limit=50)
  (도구명은 연결 방식에 따라 다를 수 있음. /mcp로 확인)
```

추출할 정보:
- 중요 공지사항
- 의사결정 사항 ("확정", "결정", "합의" 키워드)
- 나에게 멘션된 메시지
- 답장이 필요한 질문

### 소스 2: Gmail

| 항목 | 값 |
|------|-----|
| 실행 방법 | Python 스크립트 (Gmail API) |
| 수집 범위 | 최근 7일, 받은편지함 |

<!-- Gmail은 MCP가 아닌 스크립트로 수집합니다 -->
<!-- 이 스크립트는 Block 2에서 Claude가 자동으로 작성해줍니다 -->

수집 방법:
```bash
uv run python .claude/skills/my-context-sync/scripts/gmail_fetch.py --days 7
```

추출할 정보:
- 안 읽은 이메일 수
- 중요 발신자 이메일 요약
- 회신이 필요한 이메일
- 일정 초대 (캘린더 연동)

### 소스 3: Google Calendar

| 항목 | 값 |
|------|-----|
| 실행 방법 | Python 스크립트 (Google Calendar API) |
| 수집 범위 | 오늘 ~ 7일 후 |

<!-- 이 스크립트는 Block 2에서 Claude가 자동으로 작성해줍니다 -->

수집 방법:
```bash
uv run python .claude/skills/my-context-sync/scripts/calendar_fetch.py --days 7
```

추출할 정보:
- 오늘의 일정
- 이번 주 주요 미팅
- 준비가 필요한 미팅 (발표, 외부 미팅 등)
- 일정 충돌 여부

## 실행 흐름

이 스킬이 트리거되면 아래 순서로 실행한다.

### 1단계: 병렬 수집

3개 소스를 **동시에** 수집한다. 서로 의존성이 없으므로 병렬 실행이 가능하다.

```
수집 시작
  ├── [소스 1] Slack 채널 메시지 수집      ─┐
  ├── [소스 2] Gmail 이메일 수집            ├── 병렬 실행
  └── [소스 3] Google Calendar 일정 수집   ─┘
수집 완료
```

각 소스 수집은 subagent(Task 도구)로 실행한다:

```
Task(description="Slack 수집", prompt="general, project-updates, random 채널에서 최근 7일 메시지를 수집하라")
Task(description="Gmail 수집", prompt="gmail_fetch.py를 실행하여 최근 7일 이메일을 수집하라")
Task(description="Calendar 수집", prompt="calendar_fetch.py를 실행하여 7일간 일정을 수집하라")
```

### 2단계: 결과 통합

수집된 정보를 하나의 문서로 합친다.

통합 규칙:
- 소스별 섹션으로 구분
- 각 섹션에서 "하이라이트" (중요 항목 3개 이내)를 선별
- 액션 아이템을 문서 하단에 모아서 정리
- 수집 실패한 소스는 "수집 실패" 표시와 함께 사유 기록

### 3단계: 문서 저장

결과 파일을 저장한다.

```
저장 위치: sync/YYYY-MM-DD-context-sync.md
```

### 4단계: 리포트

실행 결과를 사용자에게 보고한다.

```
싱크 완료!

수집 결과:
  Slack: 3개 채널, 47개 메시지
  Gmail: 12개 이메일 (안 읽음 5개)
  Calendar: 8개 일정

하이라이트 3건:
  1. [Slack] #project-updates: 배포 일정 확정 (2/20)
  2. [Gmail] 파트너사 계약서 회신 필요 (기한: 2/18)
  3. [Calendar] 내일 10시 팀 미팅 (발표 자료 준비 필요)

액션 아이템 3건:
  - [ ] 파트너사 계약서 회신
  - [ ] 팀 미팅 발표 자료 준비
  - [ ] Slack #general 공지 확인

파일 저장: sync/2026-02-16-context-sync.md
```

## 출력 포맷

<!-- 출력 형식을 선택하세요. 여러 개를 동시에 사용할 수 있습니다 -->
출력 옵션:
1. **Markdown 파일** (기본) -- `sync/YYYY-MM-DD-context-sync.md`에 저장
2. **Slack 메시지** -- 지정 채널에 요약 발송 (Slack MCP 필요)
3. **Notion 페이지** -- 지정 DB에 기록 (Notion MCP 필요)

저장되는 마크다운 파일의 구조:

```markdown
# Context Sync - 2026-02-16

> 자동 수집 시각: 09:00

## 하이라이트

- **[Slack]** 주요 공지/결정 사항
- **[Gmail]** 회신 필요한 이메일
- **[Calendar]** 오늘 주요 일정

## Slack

### #general
- (수집된 메시지 요약)

### #project-updates
- (수집된 메시지 요약)

## Gmail

| 발신자 | 제목 | 상태 |
|--------|------|------|
| (발신자) | (제목) | 회신 필요 |

## Google Calendar

### 오늘 (2/16)
- (오늘 일정)

### 이번 주
- (이번 주 일정)

## 액션 아이템

- [ ] (액션 아이템 1)
- [ ] (액션 아이템 2)
```

## 커스터마이징 가이드

### 소스 추가하기

새로운 소스를 추가하려면 "소스 정의" 섹션에 같은 형식으로 추가한다:

```markdown
### 소스 4: Linear

| 항목 | 값 |
|------|-----|
| MCP 도구 | `mcp__claude_ai_Linear__list_issues` |
| 수집 범위 | 나에게 할당된 이슈 |

수집 방법:
  mcp__claude_ai_Linear__list_issues 호출.

추출할 정보:
- 진행 중인 이슈
- 이번 주 마감 이슈
```

### 소스 제거하기

사용하지 않는 소스는 해당 "소스 N" 섹션 전체를 삭제한다.
실행 흐름의 병렬 수집 부분에서도 해당 줄을 제거한다.

### 수집 주기 변경하기

기본은 수동 실행이다. 자동 실행을 원하면 CLAUDE.md에 스케줄을 추가한다:

```markdown
## 스케줄
- context-sync: 매일 09:00 실행
```

### 출력 위치 변경하기

"3단계: 문서 저장"의 경로를 원하는 위치로 수정한다.
예: `reports/`, `docs/daily/` 등.
