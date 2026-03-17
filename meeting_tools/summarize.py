# ~/meeting_tools/summarize.py
"""
Claude API로 회의 대화록을 요약한다.
- 회의 요약 (3-5줄)
- 액션 아이템
- 주요 결정사항
"""
import os
from pathlib import Path

import anthropic
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

SYSTEM_PROMPT = """당신은 회의록 작성 전문가입니다.
주어진 회의 대화록을 분석하여 다음 형식으로 정리하세요:

## 회의 요약
(3-5줄로 회의의 핵심 내용 요약)

## 액션 아이템
- [ ] [담당자 또는 Unknown]: 내용 (기한이 언급된 경우 포함)

## 주요 결정사항
- 결정된 사항들을 간결하게 나열

회의에서 명확히 언급된 내용만 포함하고, 추측하지 마세요."""


def summarize(transcript: str) -> dict:
    """대화록을 요약하고 구조화된 결과 반환."""
    client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2000,
        messages=[
            {
                "role": "user",
                "content": f"다음 회의 대화록을 정리해주세요:\n\n{transcript}",
            }
        ],
        system=SYSTEM_PROMPT,
    )

    raw = response.content[0].text

    # 섹션 파싱
    sections = {"summary": "", "actions": "", "decisions": ""}
    current = None
    lines = raw.split("\n")
    buf = []

    for line in lines:
        if line.startswith("## 회의 요약"):
            current = "summary"
            buf = []
        elif line.startswith("## 액션 아이템"):
            if current:
                sections[current] = "\n".join(buf).strip()
            current = "actions"
            buf = []
        elif line.startswith("## 주요 결정사항"):
            if current:
                sections[current] = "\n".join(buf).strip()
            current = "decisions"
            buf = []
        elif current:
            buf.append(line)

    if current and buf:
        sections[current] = "\n".join(buf).strip()

    return sections


if __name__ == "__main__":
    # 테스트용 더미 대화록
    test_transcript = """
[Speaker A]
오늘 회의 시작하겠습니다. 이번 주 목표는 API 개발 완료입니다.

[Speaker B]
네, 저는 인증 모듈을 금요일까지 완료하겠습니다.

[Speaker A]
좋습니다. 그리고 데이터베이스 스키마는 오늘 확정하기로 합시다.

[Speaker B]
동의합니다. 스키마는 현재 안으로 진행하겠습니다.
"""
    result = summarize(test_transcript)
    print("=== 요약 ===")
    print(result["summary"])
    print("\n=== 액션 아이템 ===")
    print(result["actions"])
    print("\n=== 결정사항 ===")
    print(result["decisions"])
