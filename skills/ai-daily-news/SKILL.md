---
name: ai-daily-news
description: HN/GN + 글로벌/중국 공식 AI 소스를 수집해 Dooray DM으로 5줄 한국어 요약을 발송하고 로그를 저장한다. 퀴즈는 `ai-daily-news quiz` 요청 시에만 진행한다.
---

# /ai-daily-news

매일 AI 뉴스를 수집해 Dooray DM으로 보내고 로그를 남긴다.

## 트리거

- 요약 실행: `/ai-daily-news` 또는 `ai-daily-news`
- 퀴즈 실행: `/ai-daily-news quiz` 또는 `ai-daily-news quiz`

## 실행 모드

### 1) Digest 모드 (기본)

요약 + DM + 로그만 수행한다. (퀴즈 자동 시작 금지)

### 2) Quiz 모드 (`quiz` 인자)

퀴즈를 진행한다. 가능하면 당일 Digest 결과를 재사용하고, 없으면 즉시 수집 후 문제를 만든다.

## 소스

### A. Legacy
- Hacker News (Top/Best)
- GeekNews

### B. 글로벌 공식 5개

| 소스 | URL | 비고 |
|------|-----|------|
| TechCrunch AI | https://techcrunch.com/category/artificial-intelligence/ | HTML |
| VentureBeat AI | https://feeds.feedburner.com/venturebeat/SZYF | RSS (The Verge 대체: 도메인 차단) |
| Hugging Face Blog | https://huggingface.co/blog | HTML |
| OpenAI News | https://openai.com/news/rss.xml | RSS (HTML 403 차단 우회) |
| Anthropic News | https://www.anthropic.com/news | HTML |

### C. 중국 공식 5개
- Qwen (Alibaba)
- DeepSeek
- Zhipu GLM
- Baidu ERNIE
- Tencent Hunyuan

## 날짜 정책

- 기준 타임존: Asia/Seoul
- HN/GN: 전날 필터 미적용
  - AI 필터를 통과한 항목 중 랜덤 2개씩 선택
- 글로벌/중국 공식 소스: 전날(00:00~23:59, KST) 게시물만 포함
- 소스별로 해당 항목이 없으면 `없음`으로 표시

## AI 필터 (정밀도 우선)

1. 포함 키워드가 있어야 함
2. 제외 키워드(채용/광고/비AI 일반 개발성 글 등)면 제거
3. 애매한 항목은 제거

## DM 작성 규칙

항목당 아래 형태를 반드시 지킨다:

```
[출처 N번] 제목
• 요약 1
• 요약 2
• 요약 3
• 요약 4
• 요약 5
🔗 원문URL
```

- 요약은 한국어 5줄
- 링크는 원문 URL 1개만 사용
- 수집 포털/중간 링크를 추가로 붙이지 않음

## 전달

**항상** Discord와 Dooray 양쪽에 전달한다. 하나가 실패해도 나머지는 계속 진행한다.

### 1) Discord #브리핑 채널 전송 (우선)

`terminal` 도구로 아래 Python 스크립트를 실행해 Discord 채널 `1502682632230801528`에 직접 전송한다.
뉴스 본문이 2000자를 초과하면 1900자씩 분할해 순서대로 전송한다.

```python
import urllib.request, json, os

token = ''
env_path = os.path.expanduser('~/.hermes/.env')
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line.startswith('DISCORD_BOT_TOKEN='):
            token = line.split('=', 1)[1].strip().strip('"').strip("'")

channel_id = '1502682632230801528'
content = """여기에 뉴스 본문"""  # 실제 실행 시 뉴스 본문으로 대체

chunks = [content[i:i+1900] for i in range(0, len(content), 1900)]
for chunk in chunks:
    data = json.dumps({'content': chunk}).encode('utf-8')
    req = urllib.request.Request(
        f'https://discord.com/api/v10/channels/{channel_id}/messages',
        data=data,
        headers={'Authorization': f'Bot {token}', 'Content-Type': 'application/json'},
        method='POST'
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f'Discord sent: {resp.status}')
    except Exception as e:
        print(f'Discord error: {e}')
```

### 2) Dooray DM 전송 (보조)

1. `mcp__dooray__get-my-member-info`로 본인 ID 조회
2. `mcp__dooray__send-messenger-direct-message`로 전송
3. 실패 시 경고를 출력하고 로그 저장은 계속 진행

## 로그 저장

- 경로: `~/ai-quiz-log/YYYY-MM-DD.md`
- 포함 내용:
  - 소스별 상태(성공/실패/없음)
  - 발송한 뉴스 목록(출처, 제목, 원문 링크)
  - Quiz 모드일 경우 문제/응답/정답

## 자동 실행 (매일 08:00)

- cron으로 Digest 모드만 자동 실행
- 예시:

```cron
0 8 * * * /home/ghye/claude-skills/scripts/ai_daily_news_digest.sh
```

## 예외 처리

- 일부 소스 실패: 나머지 소스로 계속 진행
- 모든 소스가 비어 있음: "오늘은 조건에 맞는 AI 뉴스가 없습니다" 전송
- Reddit은 사용하지 않음 (차단/불안정 이슈로 제외)
