---
name: meeting
description: 회의 녹음 파일을 chunked Whisper STT로 처리하고, 선택적 화자분리를 적용한 뒤 Claude가 교정+요약한다. "/meeting <오디오파일> [회의제목] [화자수 N명] [컨텍스트] [참고문서.pdf ...]" 형식으로 호출. "/meeting record"로 녹음 시작. "/meeting setup"으로 초기 설정.
---

# Meeting 스킬

오디오 파일을 받아 전체 파이프라인을 실행한다:
오디오 보정 → chunked STT → (선택적) 화자분리 → Claude 교정+요약 → 프로젝트 Notion 자동 업로드 또는 선택적 Notion/Dooray 업로드

## 소스 추적

- 실행 코드 저장소: `https://github.com/GeonheeYe/meeting-tools`
- 로컬 실행 경로: `~/meeting_tools`
- 환경 변수: `~/meeting_tools/.env` (setup.sh가 `~/dotfiles/meeting_tools/.env` 존재 시 symlink로 연결)

## 사용법

~~~
/meeting setup                                                         # 초기 설정 (처음 사용 시)
/meeting record                                                        # 녹음 시작 (새 터미널 창)
/meeting ~/meetings/audio.wav                                          # 기본 처리
/meeting ~/meetings/audio.wav 스프린트 회의 4명 RAG, 파이프라인        # 화자분리 포함
/meeting ~/meetings/audio.wav XQBot 리뷰 2명 project:내프로젝트        # 프로젝트 용어 활용
/meeting ~/meetings/audio.wav XQBot 리뷰 2명 BIRD,GRPO agenda.txt     # 참고 문서 포함
~~~

- 기본 실행은 오디오 보정 + chunked STT다.
- 화자 수(`N명`)를 주면 pyannote 화자 분리 실행. 없으면 생략(빠름).
- 참고 문서(`.pdf`, `.txt`, `.md`, `.docx`)를 주면 STT 정확도 향상 + Claude 교정에 활용.

---

## `/meeting setup` — 초기 설정

처음 사용하거나 새 환경에서 설치할 때 실행한다.

### Step 1: meeting-tools 클론

```bash
if [ -d ~/meeting_tools ]; then
  cd ~/meeting_tools && git pull
else
  git clone https://github.com/GeonheeYe/meeting-tools.git ~/meeting_tools
fi
```

### Step 2: setup.sh 실행 + 하드웨어 감지 메시지 출력

```bash
cd ~/meeting_tools && bash setup.sh
```

setup.sh 완료 후 터미널 출력에서 하드웨어 감지 결과를 확인하고 사용자에게 다음 형식으로 안내한다:

```
✅ 환경 감지 완료
   하드웨어: {감지된 환경}
   사용 모델: {백엔드 + 모델}
```

하드웨어별 메시지:
- Apple Silicon: `Apple Silicon M시리즈 (N GB RAM) → mlx-whisper large-v3`
- NVIDIA ≥8GB VRAM: `NVIDIA {GPU명} ({N}GB VRAM) → faster-whisper large-v3 float16`
- NVIDIA 4-8GB: `NVIDIA {GPU명} ({N}GB VRAM) → faster-whisper large-v3 int8`
- CPU: `CPU ({N}GB RAM) → faster-whisper large-v3 int8`

### Step 3: .env 파일 생성

`~/meeting_tools/.env` 파일이 없으면 생성한다 (setup.sh가 이미 생성했으면 확인만):

```
# Hugging Face 토큰 (화자 분리 사용 시 필요)
# 발급: https://huggingface.co/settings/tokens
HF_TOKEN=

# Dooray (아래 Step 4에서 연결하면 자동 입력됨)
# DOORAY_API_TOKEN=
# DOORAY_TENANT_URL=
```

파일 위치(`~/meeting_tools/.env`)와 편집 방법을 안내한다.

### Step 3.5: 주요 프로젝트 설정 (선택)

AskUserQuestion 도구로 묻는다:
- 질문: "주로 다루는 프로젝트가 있나요? 프로젝트 이름을 알려주시면 회의마다 고유명사·교정 패턴을 누적 저장해 STT 정확도가 높아집니다. 없으면 공통 환경으로 저장됩니다."
- 옵션 1: "네, 프로젝트 이름을 입력합니다"
- 옵션 2: "아니오, 공통 환경으로 사용합니다"

**"네"인 경우:**

프로젝트 이름을 입력받는다 (여러 개면 쉼표로 구분).

각 프로젝트마다 `~/dotfiles/skills/meeting/projects/{name}/terms.md` 파일을 생성한다:

```bash
mkdir -p ~/dotfiles/skills/meeting/projects/{name}
```

terms.md 초기 내용:
```markdown
---
name: {name} 프로젝트 용어
description: STT 교정 및 요약에 활용되는 고유명사, 기술 용어, 오인식 패턴
type: project
---

## 프로젝트명

## 기술 용어

## STT 오인식 교정 패턴

| STT 오인식 | 올바른 표기 | 비고 |
|------------|------------|------|

---
*마지막 업데이트: {오늘 날짜}*
```

생성 완료 후 안내:
```
📁 프로젝트 용어 파일 생성됨:
  ~/dotfiles/skills/meeting/projects/{name}/terms.md

사용법:
  /meeting audio.wav 회의제목 project:{name}
  /meeting audio.wav 회의제목 @{name}
```

**"아니오"인 경우:**

```
ℹ️ 프로젝트 미지정 시 회의록은 공통 환경으로 처리됩니다.
나중에 프로젝트를 추가하려면:
  mkdir -p ~/dotfiles/skills/meeting/projects/프로젝트명
  # terms.md 파일 생성 후 /meeting에서 project:프로젝트명 으로 사용
```

### Step 4: Dooray MCP 설치 (선택)

AskUserQuestion 도구로 묻는다:
- 질문: "Dooray 위키에 회의록을 자동으로 올리겠습니까? (회의 후 위키 업로드가 자동화됩니다)"
- 옵션 1: "네, Dooray에 연결합니다"
- 옵션 2: "아니오, 나중에 설정합니다"

**"네"인 경우:**

AI 에이전트 종류 감지:

```bash
HAS_CLAUDE=$(command -v claude && echo yes || echo no)
HAS_CODEX=$(command -v codex && echo yes || echo no)
```

Claude Code가 있으면:

```bash
claude mcp add -s user dooray-mcp npx @geonheeye/dooray-mcp@latest
```

Codex가 있으면 `~/.codex/config.json`에 MCP 서버 추가:

```json
{
  "mcpServers": {
    "dooray-mcp": {
      "command": "npx",
      "args": ["@geonheeye/dooray-mcp@latest"]
    }
  }
}
```

그 다음 .env의 Dooray 항목 언커멘트 후 값 입력 방법 안내:

```
DOORAY_API_TOKEN 발급 방법:
  두레이 접속 → 우상단 프로필 → 개인설정 → API → 개인 인증 토큰 생성

DOORAY_TENANT_URL 예시:
  https://your-company.dooray.com
```

사용자에게 `.env` 파일을 직접 편집하도록 안내하고, 완료했으면 알려달라고 한다.

편집 완료 확인 후 AskUserQuestion 도구로 위키를 묻는다:
- 질문: "회의록을 올릴 Dooray 위키 이름 또는 URL을 알려주세요."

입력값을 받아 `mcp__dooray__get-wiki-list` 도구로 위키 목록을 조회하고 wiki_id를 찾는다.
찾은 wiki_id를 이 SKILL.md 파일의 `## Dooray 설정` 섹션에 저장한다.

**"아니오"인 경우:** Step 5로 넘어간다.

### Step 5: 완료 안내

```
🎉 설정 완료!

필수 입력 (~/meeting_tools/.env):
  HF_TOKEN — 화자 분리(pyannote) 사용 시 필요
  발급: https://huggingface.co/settings/tokens

사용법:
  /meeting ~/meetings/audio.wav              # 기본 처리
  /meeting ~/meetings/audio.wav 회의제목 2명  # 화자 분리 포함
  /meeting record                            # 녹음 시작
```

---

## `/meeting` — 회의 처리 모드

### Step 1: ARGUMENTS 파싱

ARGUMENTS에서 다음 정보를 추출한다:

- **오디오 파일 경로**: 첫 번째 인자 (또는 `record` 또는 `setup`)
- **회의 제목**: 숫자, 파일 경로, 키워드처럼 보이지 않는 텍스트 부분
- **회의 타입**: 제목이나 컨텍스트에서 "세미나" 키워드 감지. 있으면 `meeting_type="seminar"`, 없으면 None
- **화자 수**: "N명", "N people", "speakers N" 패턴에서 숫자 추출. 없으면 None
- **컨텍스트**: 기술 용어나 회의 주제 설명 문자열 (파일 경로 아닌 것). 없으면 None
- **참고 문서**: `.pdf`, `.txt`, `.md`, `.docx` 확장자를 가진 경로들. 없으면 None
- **프로젝트 이름**: `project:프로젝트명` 또는 `@프로젝트명` 형식. 없으면 None
  - 있으면 아래 두 파일을 각각 읽는다.
    - `~/dotfiles/skills/meeting/projects/{project}/terms.md`: 프로젝트 고유명사, 기술 용어, STT 오인식 교정 패턴에 사용
    - `~/dotfiles/skills/meeting/projects/{project}/config.md`: 조직 역할, 요약 형식, 업로드 대상과 자동 업로드 정책에 사용
  - `terms.md`가 없으면 프로젝트 전용 용어 교정 없이 진행한다.
  - `config.md`가 없으면 프로젝트 전용 요약·업로드 정책을 적용하지 않고 기존 공용 흐름으로 진행한다.
  - 한 파일이 없어도 다른 파일은 독립적으로 적용한다.

예시: `audio.wav XQBot 리뷰 2명 BIRD,GRPO agenda.txt`
→ title=`XQBot 리뷰`, speakers=`2`, context=`BIRD,GRPO`, docs=`[agenda.txt]`

예시: `audio.wav 스프린트 회의 4명 project:팀회의`
→ title=`스프린트 회의`, speakers=`4`, project=`팀회의`

**`setup`인 경우** — 위의 `/meeting setup` 플로우로 이동한다.

**`record`인 경우** — 녹음 모드:

```bash
osascript -e 'tell application "Terminal" to do script "cd ~/meeting_tools && .venv/bin/python3 record.py"'
```

사용자에게 안내:
```
새 터미널 창에서 녹음이 시작됩니다.
Enter로 녹음 종료 후, 저장된 파일 경로로 다시 호출하세요:

  /meeting ~/meetings/audio_YYYYMMDD_HHMM.wav [회의 제목] [화자수 N명] [키워드] [문서.pdf ...]
```

**오디오 파일 경로인 경우** — Step 2로 진행한다.

### Step 2: 파이프라인 실행

다음 명령을 실행하기 전에 사용자에게 알린다:
```
⏳ STT 파이프라인을 시작합니다. 오디오 길이에 따라 수 분 소요될 수 있습니다...
```

```bash
cd ~/meeting_tools && .venv/bin/python3 pipeline.py <오디오파일경로> [회의제목] [--speakers N] [--context "컨텍스트"] [--docs 문서1 문서2]
```

예시 (화자분리 없음):
```bash
cd ~/meeting_tools && .venv/bin/python3 pipeline.py ~/meetings/audio.wav "스프린트 회의"
```

예시 (화자분리 + 참고 문서):
```bash
cd ~/meeting_tools && .venv/bin/python3 pipeline.py ~/meetings/audio.wav "XQBot 리뷰" --speakers 2 --context "BIRD,GRPO" --docs ~/docs/agenda.txt
```

명령이 완료되면 `{오디오파일디렉토리}/{오디오파일명}.json` 파일 경로가 출력된다.

완료 후 안내:
```
✅ 파이프라인 완료
```

### Step 3: JSON 결과 읽기

출력된 JSON 파일을 읽는다. 구조:
```json
{
  "title": "[2026-03-13] 회의",
  "date": "2026-03-13",
  "speaker_count": 4,
  "transcript": "[Speaker A]\n안녕하세요...",
  "doc_content": "참고 문서 본문 (없으면 빈 문자열)",
  "agenda_items": ["안건1", "안건2"],
  "vad_applied": false,
  "chunking_applied": true,
  "source_audio_path": "/path/to/audio.wav",
  "stt_audio_path": "/path/to/audio_enhanced.wav",
  "term_metadata_applied": true,
  "audio_enhanced": true
}
```

### Step 4: Claude 교정 + 요약

**프로젝트 컨텍스트 로드 (project가 있을 때):**

아래 두 파일을 각각 읽는다.

- `~/dotfiles/skills/meeting/projects/{project}/terms.md`
  - 있으면 STT 오인식 교정 패턴으로 transcript를 수정하고, 기술 용어를 교정·요약에 반영한다.
  - 없으면 프로젝트 전용 용어 교정 없이 진행한다.
- `~/dotfiles/skills/meeting/projects/{project}/config.md`
  - 있으면 조직 역할과 출처 우선순위, 요약 형식, 업로드 대상과 자동 업로드 정책을 적용한다.
  - 없으면 프로젝트 전용 요약·업로드 정책을 적용하지 않고 기존 공용 흐름으로 진행한다.

한 파일이 없어도 다른 파일은 독립적으로 적용한다. config의 정책과 transcript가 충돌하면 config에 적힌 출처 우선순위를 따르며, 근거 없이 내용을 보완하지 않는다.

**교정 (doc_content 또는 project terms가 있을 때):**

transcript에서 STT 오류를 교정한다.
- doc_content 또는 terms.md에 등장하는 고유명사/기술 용어가 다르게 표기된 경우만 교정
- 근거 없는 추측 교정 금지 — 문서에 명시된 것만

**요약:**

교정된 transcript를 바탕으로 다음 3가지를 작성한다:

- **회의 요약**: 핵심 내용 3-5줄
- **액션 아이템**: agenda_items가 있으면 항목별 그룹화, 없으면 단순 목록

  agenda_items가 있을 때:
  ```
  **1. {agenda_items[0]}**
  - [ ] 내용 (기한)

  **기타**
  - [ ] 안건 외 명확히 도출된 액션
  ```

  agenda_items가 없을 때:
  ```
  - [ ] 내용 (기한)
  ```

- **주요 결정사항**: 대화록에 명확히 언급된 것만

추측하지 말고 대화록에 명시된 내용만 포함한다.

**Insight 생성 (meeting_type == "seminar"인 경우):**

세미나인 경우, 추가로 다음 항목들을 생성한다:

- **주요 학습 포인트**: 세미나에서 배운 핵심 개념 또는 지식 (3-5개)
- **실행 가능한 개선사항**: 직장이나 프로젝트에 바로 적용할 수 있는 실무 팁
- **업계 트렌드/인사이트**: 세미나 주제와 관련된 현재 업계 동향
- **개인적 성장 포인트**: 경력 발전에 도움이 될 수 있는 관찰사항

각 항목은 대화록에 명확히 언급된 내용과 그 의미를 바탕으로만 작성한다. 추측은 금지.

### Step 4.5: 요약 확인 + 업로드 분기

프로젝트 `config.md`에 요약 형식이 있으면 해당 형식의 모든 섹션을 미리보기로 먼저 출력한다. 예를 들어 `ai-platform`은 `회의 요약`, `주요 결정사항`, `액션 아이템`, `확인 필요`를 모두 보여준다.

프로젝트 전용 요약 형식이 없을 때 터미널에 출력 (meeting_type != "seminar"인 경우):
```
---
📋 회의 요약
(요약 내용)

✅ 액션 아이템
(액션 아이템 목록)

🔑 주요 결정사항
(결정사항 목록)
---
```

프로젝트 전용 요약 형식이 없을 때 터미널에 출력 (meeting_type == "seminar"인 경우):
```
---
📋 회의 요약
(요약 내용)

✅ 액션 아이템
(액션 아이템 목록)

🔑 주요 결정사항
(결정사항 목록)

💡 주요 Insight
(Insight 항목들)
---
```

#### 프로젝트 전용 Notion 자동 업로드

AskUserQuestion을 호출하기 전에 다음 분기를 먼저 판정한다.

- project의 `config.md`에서 구조화 필드 `notion_auto_upload: true`와 parent 설정이 확인되면 config의 네 섹션 요약 미리보기를 보여주되 업로드 대상은 묻지 않는다.
- **REQUIRED:** 자동 업로드를 실행하기 전에 `references/project-notion-auto-upload.md`를 처음부터 끝까지 읽고 제목 정규화, 페이지네이션, 중복 판정, mutation, 최종 검증, 오류 처리 절차를 모두 따른다.
- 자동 업로드가 활성화되어 있지만 설정이 유효하지 않으면 reference의 실패 절차로 종료한다.
- 프로젝트 자동 업로드 조건이 없으면 이 분기를 실행하지 않고 아래의 기존 AskUserQuestion 흐름으로 진행한다.
- 이 자동 업로드 분기에 들어간 뒤에는 성공·실패와 관계없이 아래의 기존 AskUserQuestion 흐름으로 떨어지지 않는다.

AskUserQuestion 도구로 묻는다:
- 질문: "위 내용을 어디에 업로드할까요?"
- 옵션 1: "Notion에 업로드"
- 옵션 2: "Dooray 위키에 업로드"
- 옵션 3: "업로드 없이 완료"

**"Notion"인 경우:**

**대상 DB**: Notion > Company > 회의록 (database_id: `f04252be-cb89-4cf0-88b1-0351a7a8f98c`)

**MCP 우선순위**: `notion-work` 먼저 시도 → 실패 시 `claude_ai_Notion` fallback

#### notion-work MCP 사용 시 (우선)

**1단계: 페이지 생성** — `API-post-page` 도구 사용

```json
parent: {"type": "database_id", "database_id": "f04252be-cb89-4cf0-88b1-0351a7a8f98c"}
properties:
  제목: {"title": [{"type": "text", "text": {"content": "[YYYY-MM-DD] 회의제목"}}]}
  날짜: {"date": {"start": "YYYY-MM-DD"}}
  참석자수: {"number": N}
```

**2단계: 본문 추가** — `API-patch-block-children` 도구 사용 (생성된 page_id에 append)

블록 구성 (meeting_type != "seminar"인 경우):
- `paragraph` (bold, blue): "📋 회의 요약"
- `bulleted_list_item` × N: 요약 항목
- `paragraph` (bold, green): "✅ 액션 아이템"
- `bulleted_list_item` × N: 액션 아이템 (`- [ ] 내용` 형식)
- `paragraph` (bold, orange): "🔑 주요 결정사항"
- `bulleted_list_item` × N: 결정 항목
- `paragraph` (bold, gray): "💬 전체 대화록"
- `paragraph` × N: Speaker별 대화 내용

블록 구성 (meeting_type == "seminar"인 경우):
- `paragraph` (bold, blue): "📋 회의 요약"
- `bulleted_list_item` × N: 요약 항목
- `paragraph` (bold, green): "✅ 액션 아이템"
- `bulleted_list_item` × N: 액션 아이템 (`- [ ] 내용` 형식)
- `paragraph` (bold, orange): "🔑 주요 결정사항"
- `bulleted_list_item` × N: 결정 항목
- `paragraph` (bold, purple): "💡 주요 Insight"
- `bulleted_list_item` × N: Insight 항목들
- `paragraph` (bold, gray): "💬 전체 대화록"
- `paragraph` × N: Speaker별 대화 내용

#### claude_ai_Notion MCP 사용 시 (fallback)

`notion-create-pages` 도구로 `data_source_id`에 직접 생성.

페이지 properties:
- `제목`: JSON의 title 값
- `date:날짜:start`: JSON의 date 값 (YYYY-MM-DD)
- `date:날짜:is_datetime`: 0
- `참석자수`: JSON의 speaker_count 값

페이지 content 구성 (본문):
- 섹션 순서: 회의 요약 → 액션 아이템 → 주요 결정사항 → 전체 대화록(토글)
- 전체 대화록은 `<details><summary>전체 대화록</summary>...</details>` 토글로 표시

생성된 Notion 페이지 URL을 안내한다.

**"Dooray 위키"인 경우:**

이 SKILL.md의 `## Dooray 설정` 섹션에서 wiki_id를 읽어 `mcp__dooray__create-wiki-page` 도구로 생성:

```
subject: "[YYYY-MM-DD] 회의제목"
content: (마크다운 — 회의 요약 + 액션 아이템 + 주요 결정사항)
```

content 구성:
```markdown
## 회의 요약
- 요약 항목 1

## 액션 아이템
- [ ] 액션 1

## 주요 결정사항
- 결정 1
```

생성된 위키 페이지 URL을 안내한다.

**"업로드 없이 완료"인 경우:**

JSON 결과 파일 경로를 안내하고 종료한다.

### Step 5: 완료 안내 + 프로젝트 용어 저장

JSON 결과 파일은 원본 오디오와 같은 디렉토리에 보존한다 (재처리·디버깅용).

**프로젝트 용어 저장 (project가 있을 때):**

회의 중 새로 등장한 고유명사나 사용자가 교정한 내용이 있으면
`~/dotfiles/skills/meeting/projects/{project}/terms.md`에 추가한다:
- 새 용어 → 기술 용어 섹션에 추가
- 교정 패턴 → STT 오인식 교정 패턴 테이블에 추가
- 마지막 업데이트 날짜 갱신

새로 저장한 용어가 있으면 안내한다:
```
📝 [{project}] 용어 업데이트: [새로 추가된 용어 목록]
```

---

## Dooray 설정

> `/meeting setup`에서 Dooray 연결 시 자동으로 채워집니다.

```
DOORAY_WIKI_ID=3682781558863996885
DOORAY_WIKI_NAME=AI개발팀-주간업무보고
DOORAY_WIKI_HOME_PAGE_ID=3682781559607351814
DOORAY_WIKI_PARENT_PAGE_ID=4295872682126525499
DOORAY_WIKI_PARENT_PAGE_NAME=meeting
```

회의록은 `DOORAY_WIKI_PARENT_PAGE_ID`(`meeting` 페이지) 하위에 생성합니다. `create-wiki-page` 호출 시 `parentPageId`로 이 값을 사용하세요.

## 오디오 파일이 없는 경우

녹음 방법을 안내한다:

```bash
osascript -e 'tell application "Terminal" to do script "cd ~/meeting_tools && .venv/bin/python3 record.py"'
```
