---
name: yt-quiz
description: YouTube URL을 입력받아 자막을 파싱하고 핵심 내용 요약 + 개념 이해 4지선다 퀴즈를 생성한다. "/yt-quiz", "유튜브 퀴즈", "YouTube 요약" 요청에 사용.
---

# /yt-quiz

YouTube URL을 입력받아 자막을 파싱하고, 핵심 내용 요약 + 개념 이해 4지선다 퀴즈를 생성한다.

## 실행 순서

### 1. Video ID 추출

사용자가 입력한 URL에서 정규식으로 video ID를 추출한다.

지원 형식:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`

추출 실패 시 "올바른 YouTube URL을 입력해주세요. (지원 형식: youtube.com/watch?v=, youtu.be/, youtube.com/embed/)"를 출력하고 종료한다.

### 2. 자막 가져오기

Bash로 아래 python3 인라인 스크립트를 실행한다. `VIDEO_ID` 자리에 추출한 video ID를 넣는다:

```bash
python3 -W ignore - VIDEO_ID <<'EOF'
from youtube_transcript_api import YouTubeTranscriptApi
import json, sys, warnings
warnings.filterwarnings('ignore')
api = YouTubeTranscriptApi()
video_id = sys.argv[1]
lang = 'en'
try:
    transcript = api.fetch(video_id, languages=['ko'])
    lang = 'ko'
except:
    try:
        transcript = api.fetch(video_id, languages=['en'])
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(0)
snippets = list(transcript)
text = ' '.join([s.text for s in snippets])
print(json.dumps({'text': text, 'lang': lang, 'count': len(snippets)}))
EOF
```

스크립트 출력 결과를 JSON으로 파싱한다:
- `error` 키가 있으면 → "이 영상에는 자막이 없어 학습 퀴즈를 생성할 수 없습니다."를 출력하고 종료한다.
- `text` 길이가 100자 미만이면 → "자막 내용이 너무 짧아 퀴즈를 생성하기 어렵습니다."를 출력하고 종료한다.

### 3. 요약 및 퀴즈 생성

자막 텍스트를 바탕으로 다음 기준에 따라 요약과 퀴즈를 생성한다:

**전처리:**
- `lang`이 `en`이면 한국어로 번역한 뒤 처리한다.

**요약 기준:**
- 영상의 핵심 내용을 3~5줄로 요약한다.
- 각 줄은 독립적인 핵심 포인트를 담는다.

**퀴즈 기준:**
- 자막 내용에서 핵심 개념을 골라 퀴즈를 5문제 만든다. 내용이 빈약하면 3문제로 줄인다.
- 개념 이해를 테스트하는 질문을 만든다.
  - 좋은 질문 예시: "왜 효과적인가?", "어떤 방식으로 동작하는가?", "다른 방식과의 차이는?"
  - 나쁜 질문 예시: "영상 제목이 뭔가요?" (단순 사실 암기 금지)
- 정답 1개 + 그럴듯한 오답 3개
- 한 줄 해설 (정답 이유 포함)

### 4. 출력 및 인터랙티브 퀴즈 진행

**4-1. 요약 출력**

아래 형식으로 요약을 먼저 출력한다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 영상 제목 (URL에서 알 수 없으면 자막 내용 기반으로 추정)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 핵심 내용 요약
- 요약 1
- 요약 2
- 요약 3
```

**4-2. 퀴즈 인터랙티브 진행**

요약 출력 후, 퀴즈를 한 문제씩 순서대로 진행한다.

각 문제마다:
1. 문제 번호와 질문, 보기(A~D)를 출력한다.
2. AskUserQuestion 도구로 사용자의 답을 받는다.
   - 선택지: A, B, C, D (각 보기 내용을 label로 표시)
3. 사용자가 답을 선택하면 정오 여부와 해설을 출력한다:
   - 정답: `✓ 정답입니다! — 해설`
   - 오답: `✗ 오답입니다. 정답은 X) — 해설`
4. 다음 문제로 넘어간다.

모든 문제가 끝나면 결과를 출력한다:

```
─── 결과 ───
N문제 중 M개 정답 (정답률 XX%)
```
