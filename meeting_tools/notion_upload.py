# ~/meeting_tools/notion_upload.py
"""
회의 분석 결과를 Notion 회의록 DB에 새 페이지로 생성한다.
"""
import os
from datetime import datetime
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from notion_client import Client

load_dotenv(Path(__file__).parent / ".env")


def _text_block(content: str) -> dict:
    return {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
            "rich_text": [{"type": "text", "text": {"content": content}}]
        },
    }


def _heading2(content: str) -> dict:
    return {
        "object": "block",
        "type": "heading_2",
        "heading_2": {
            "rich_text": [{"type": "text", "text": {"content": content}}]
        },
    }


def _todo(content: str) -> dict:
    checked = content.startswith("- [x]")
    # "- [ ] " 또는 "- [x] " 접두사(6자) 제거
    text = content[6:].strip()
    return {
        "object": "block",
        "type": "to_do",
        "to_do": {
            "rich_text": [{"type": "text", "text": {"content": text}}],
            "checked": checked,
        },
    }


def _bullet(content: str) -> dict:
    text = content.lstrip("- ").strip()
    return {
        "object": "block",
        "type": "bulleted_list_item",
        "bulleted_list_item": {
            "rich_text": [{"type": "text", "text": {"content": text}}]
        },
    }


def _toggle(title: str, children: list[dict]) -> dict:
    return {
        "object": "block",
        "type": "toggle",
        "toggle": {
            "rich_text": [{"type": "text", "text": {"content": title}}],
            "children": children,
        },
    }


def upload(
    title: str,
    summary: str,
    actions: str,
    decisions: str,
    transcript: str,
    speaker_count: int,
    meeting_date: Optional[datetime] = None,
) -> str:
    """Notion DB에 회의록 페이지 생성. 생성된 페이지 URL 반환."""
    notion = Client(auth=os.environ.get("NOTION_API_KEY"))
    db_id = os.environ.get("NOTION_DATABASE_ID")
    date = meeting_date or datetime.now()

    # 액션 아이템 블록 생성
    action_blocks = []
    for line in actions.split("\n"):
        line = line.strip()
        if line.startswith("- ["):
            action_blocks.append(_todo(line))
        elif line:
            action_blocks.append(_text_block(line))

    # 결정사항 블록 생성
    decision_blocks = []
    for line in decisions.split("\n"):
        line = line.strip()
        if line.startswith("- "):
            decision_blocks.append(_bullet(line))
        elif line:
            decision_blocks.append(_text_block(line))

    # 전체 대화록 (토글)
    transcript_blocks = [_text_block(line) for line in transcript.split("\n") if line.strip()]

    children = [
        _heading2("회의 요약"),
        *[_text_block(line) for line in summary.split("\n") if line.strip()],
        _heading2("액션 아이템"),
        *(action_blocks or [_text_block("없음")]),
        _heading2("주요 결정사항"),
        *(decision_blocks or [_text_block("없음")]),
        _toggle("전체 대화록 (펼치기)", transcript_blocks),
    ]

    page = notion.pages.create(
        parent={"database_id": db_id},
        properties={
            "제목": {"title": [{"text": {"content": title}}]},
            "날짜": {"date": {"start": date.strftime("%Y-%m-%d")}},
            "참석자 수": {"number": speaker_count},
        },
        children=children,
    )

    url = page.get("url", "")
    print(f"Notion 페이지 생성 완료: {url}")
    return url


if __name__ == "__main__":
    # 연결 테스트
    notion = Client(auth=os.environ.get("NOTION_API_KEY"))
    db_id = os.environ.get("NOTION_DATABASE_ID")
    db = notion.databases.retrieve(database_id=db_id)
    print(f"DB 연결 OK: {db['title'][0]['text']['content']}")
