---
name: meeting
description: 회의 녹음 파일을 Whisper STT + 화자분리 후 Claude가 직접 요약하고 Notion MCP로 업로드한다. "/meeting <오디오파일> [회의제목]" 형식으로 호출. "/meeting record"로 녹음 시작.
---

# Meeting 스킬

오디오 파일을 받아 전체 파이프라인을 실행한다:
STT → 화자분리 → Claude 요약 → Notion MCP로 페이지 생성

## 사용법

~~~
/meeting record                                      # 녹음 시작
/meeting ~/meetings/audio_20260313_1400.wav [회의 제목]  # 파일로 처리
~~~

## 실행 방법

### Step 1: ARGUMENTS 파싱

ARGUMENTS에서 첫 번째 인자를 확인한다.

**`record`인 경우** — 녹음 모드:

다음 명령을 실행한다:
~~~bash
python3 ~/meeting_tools/record.py
~~~

녹음이 완료되면 저장된 파일 경로를 출력한다. 이후 해당 파일로 Step 2부터 계속 진행할지 사용자에게 확인한다.

**오디오 파일 경로인 경우** — 처리 모드: 아래 Step 2로 진행한다.

### Step 2: 파이프라인 실행 (STT + 화자분리)

다음 명령을 실행한다:

~~~bash
cd ~/meeting_tools && python3 pipeline.py <오디오파일경로> [회의제목]
~~~

명령이 완료되면 `/tmp/meeting_YYYYMMDD_HHMMSS.json` 파일 경로가 출력된다.

### Step 3: JSON 결과 읽기

출력된 JSON 파일을 읽는다. 구조:
~~~json
{
  "title": "[2026-03-13] 회의",
  "date": "2026-03-13",
  "speaker_count": 2,
  "transcript": "[Speaker A]\n안녕하세요..."
}
~~~

### Step 4: Claude가 직접 요약

transcript 내용을 바탕으로 다음 3가지를 작성한다:

- **회의 요약**: 핵심 내용 3-5줄
- **액션 아이템**: `- [ ] 담당자: 내용 (기한)` 형식, 명확히 언급된 것만
- **주요 결정사항**: 결정된 사항 목록, 명확히 언급된 것만

추측하지 말고 대화록에 명시된 내용만 포함한다.

### Step 5: Notion MCP로 페이지 생성

**대상 DB**: Notion > Company > 회의록 (data_source_id: `3dd8b942-3757-4201-9345-a753e2a693bf`)

notion-create-pages 도구로 위 data_source_id에 직접 페이지를 생성한다 (검색 불필요).

페이지 properties:
- `제목`: JSON의 title 값
- `date:날짜:start`: JSON의 date 값 (YYYY-MM-DD)
- `date:날짜:is_datetime`: 0
- `참석자수`: JSON의 speaker_count 값

페이지 content 구성 (본문):
- 섹션 순서: 회의 요약 → 액션 아이템 → 주요 결정사항 → 전체 대화록(토글)
- 액션 아이템은 체크박스(to_do) 블록으로 생성
- 전체 대화록은 `<details>` toggle 블록 안에 넣어 접힌 상태로 표시

### Step 6: 완료 안내

생성된 Notion 페이지 URL을 사용자에게 알려준다.
JSON 임시 파일을 삭제한다:
~~~bash
rm <json파일경로>
~~~

## 오디오 파일이 없는 경우

녹음 방법을 안내한다:

~~~bash
python3 ~/meeting_tools/record.py
~~~
