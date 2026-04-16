# ai-daily-news

HN/GN + 글로벌/중국 공식 AI 소스를 수집해 Dooray DM으로 한국어 5줄 요약을 발송하는 스킬.
퀴즈는 `ai-daily-news quiz` 요청 시에만 진행한다.

## 핵심 정책

- 요약 포맷: `제목 + 5줄 요약 + 원문 링크 1개`
- AI 필터: 정밀도 우선 (애매하면 제외)
- 날짜 정책:
  - HN/GN: 전날 필터 미적용, AI 항목 랜덤 2개씩
  - 나머지 공식 소스: Asia/Seoul 기준 전날(00:00~23:59)
- 소스별 뉴스가 없으면 `없음` 표기
- Reddit 소스는 제외

## 소스

- Legacy: HN, GeekNews
- 글로벌 공식 5개: TechCrunch AI, The Verge AI, Hugging Face Blog, OpenAI News, Anthropic News
- 중국 공식 5개: Qwen, DeepSeek, Zhipu GLM, Baidu ERNIE, Tencent Hunyuan

## 사용법

- Digest 실행:

```text
/ai-daily-news
```

- Quiz 실행:

```text
/ai-daily-news quiz
```

## 로그

- 경로: `~/ai-quiz-log/YYYY-MM-DD.md`
- 저장 내용: 소스별 상태, 뉴스 목록, Quiz 실행 시 퀴즈 결과

## 자동 실행 (cron)

매일 오전 8시 Digest를 실행하려면:

```cron
0 8 * * * /home/ghye/claude-skills/scripts/ai_daily_news_digest.sh
```

스크립트 파일: `/home/ghye/claude-skills/scripts/ai_daily_news_digest.sh`
