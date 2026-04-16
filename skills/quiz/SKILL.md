---
name: quiz
description: questions bank에서 랜덤 퀴즈 출제. "/quiz", "퀴즈", "문제 풀기" 요청에 사용.
---

`~/dotfiles/memory/questions/` 디렉토리에서 퀴즈를 출제합니다.

## 작업 순서

1. Glob으로 `~/dotfiles/memory/questions/*.json` 파일 목록을 가져온다.

2. 각 파일을 Read로 읽어 항목 목록을 만든다.

3. 인자로 받은 숫자만큼 문제를 출제한다. 인자가 없으면 5개. 항목이 부족하면 전체 출제.

4. last_reviewed가 null인 것을 우선, 없으면 last_reviewed가 오래된 것 순으로 선택한다.

5. 각 문제를 아래 형식으로 하나씩 출제한다:
   ```
   [Q1/5] 키워드: {keyword}

   {question}

   답변을 입력하세요:
   ```

6. 사용자가 답변하면 정답(answer)과 비교하여 피드백을 준다:
   ```
   ✓ 정답 참고:
   {answer}

   ---
   다음 문제로 넘어갈까요?
   ```

7. 모든 문제가 끝나면 결과를 출력한다:
   ```
   퀴즈 완료! {N}문제 중 직접 확인하세요.
   ```

8. 출제된 각 문제의 `last_reviewed`를 현재 시각으로 업데이트하여 해당 파일에 Write로 덮어쓴다.
