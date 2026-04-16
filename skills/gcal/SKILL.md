---
name: gcal
description: Google Calendar 일정 관리. "/gcal", "일정 확인", "일정 추가", "캘린더" 요청에 사용.
---

# Google Calendar Skill

사용자의 Google Calendar 일정을 조회, 추가, 수정, 삭제한다.

## 스크립트 경로

모든 명령은 아래 스크립트를 통해 실행한다:

```
python3 .claude/skills/gcal/scripts/gcal.py [명령] [인자...]
```

## 사용 가능한 명령

### 일정 조회
```bash
python3 .claude/skills/gcal/scripts/gcal.py list [일수] [최대개수]
```
- 기본값: 7일 이내, 최대 10개
- 예: `list 30 20` → 30일 이내 최대 20개

### 일정 추가
```bash
python3 .claude/skills/gcal/scripts/gcal.py add "제목" "시작" "종료" "설명(선택)"
```
- 종일 일정: `"2026-02-20" "2026-02-21"`
- 시간 지정: `"2026-02-20T14:00:00" "2026-02-20T15:00:00"` (KST 자동 적용)

### 일정 수정
```bash
python3 .claude/skills/gcal/scripts/gcal.py update EVENT_ID key=value ...
```
- 수정 가능 필드: summary, start, end, description

### 일정 삭제
```bash
python3 .claude/skills/gcal/scripts/gcal.py delete EVENT_ID
```

## 실행 규칙

1. 사용자가 일정을 물어보면 **먼저 list로 조회**하여 결과를 보여준다.
2. 일정 추가/수정/삭제 전에 **사용자에게 내용을 확인**받고 실행한다.
3. 조회 결과는 **표 형태**로 보기 좋게 정리해서 보여준다.
4. 일정 수정/삭제 시 **event ID가 필요**하므로, 먼저 list로 조회하여 ID를 확인한다.
5. 사용자가 자연어로 말하면 적절한 날짜/시간 형식으로 변환하여 실행한다.
