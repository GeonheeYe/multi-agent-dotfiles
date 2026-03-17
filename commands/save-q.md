---
description: 현재 대화의 핵심 Q&A를 questions bank에 저장
argument-hint: [키워드]
allowed-tools: [Glob, Write]
---

현재 대화에서 가장 최근에 나눈 핵심 질문과 답변을 questions bank에 저장합니다.

## 작업 순서

1. Glob으로 `~/dotfiles/memory/questions/*.json` 파일 목록을 가져온다.

2. 현재 대화에서 마지막으로 나눈 핵심 내용을 분석하여:
   - **keyword**: 인자로 받은 값, 없으면 주제를 2-4단어로 자동 추출
   - **question**: 사용자가 물어본 핵심 질문 (1문장으로 요약)
   - **answer**: Claude의 답변 핵심 (3-5문장으로 요약)

3. 오늘 날짜(YYYY-MM-DD)로 시작하는 파일 수를 세어 NNN 결정 (001, 002, ...)

4. `~/dotfiles/memory/questions/YYYY-MM-DD-NNN.json`에 Write로 저장:
   ```json
   {
     "id": "YYYY-MM-DD-NNN",
     "keyword": "...",
     "question": "...",
     "answer": "...",
     "created_at": "YYYY-MM-DDTHH:MM:SS",
     "last_reviewed": null
   }
   ```

5. 저장 완료 메시지를 출력한다:
   ```
   ✓ 저장 완료
   키워드: [keyword]
   질문: [question]
   파일: ~/dotfiles/memory/questions/YYYY-MM-DD-NNN.json
   ```
