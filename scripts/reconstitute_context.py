#!/usr/bin/env python3
"""
LONGMEMORY context.md 자동 재합성 스크립트.
각 프로젝트의 summaries.md에서 마지막 재합성 이후 새 항목을 파싱해
OpenClaw gateway로 context.md를 재합성한다.
"""
import json
import re
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path

WIKI_ROOT = Path.home() / "LONGMEMORY/wiki/projects"
OPENCLAW_CONFIG = Path.home() / ".openclaw/openclaw.json"
GATEWAY_URL = "http://127.0.0.1:18789/v1/responses"
RECONSTITUTED_MARKER = ".reconstituted_at.txt"

CONTEXT_PROMPT = """\
아래는 이 프로젝트의 현재 context.md와 최근 세션 요약입니다.
이를 바탕으로 context.md를 재작성하세요.

규칙:
- 반드시 아래 4개 섹션을 포함하세요
- 오래된 내용은 최신 정보로 교체하세요
- 한국어 표준어를 사용하세요
- 마크다운 형식 유지, 섹션 제목은 아래 형식 그대로

# {project} Context

## 현재 상태
(지금 어디까지 왔는지 — 가장 최신 상황)

## 핵심 결정
(이미 확정된 것들 — 다시 논의할 필요 없는 사항)

## 다음 할 일
(바로 이어서 할 수 있는 것)

## 기술 스택 / 구조
(변하지 않는 배경 정보)

---
[현재 context.md]
{current_context}

[최근 세션 요약]
{new_summaries}
"""


def _get_gateway_token() -> str:
    data = json.loads(OPENCLAW_CONFIG.read_text())
    return data["gateway"]["auth"]["token"]


def _load_reconstituted_at(proj_dir: Path) -> datetime | None:
    marker = proj_dir / RECONSTITUTED_MARKER
    if not marker.exists():
        return None
    text = marker.read_text().strip()
    if not text:
        return None
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def _save_reconstituted_at(proj_dir: Path) -> None:
    marker = proj_dir / RECONSTITUTED_MARKER
    marker.write_text(datetime.now(timezone.utc).isoformat())


def _parse_new_summaries(proj_dir: Path, since: datetime | None) -> str:
    """summaries.md에서 since 이후 섹션만 추출."""
    summaries_path = proj_dir / "summaries.md"
    if not summaries_path.exists():
        return ""

    text = summaries_path.read_text()
    sections = re.split(r"(?=^## \d{4}-\d{2}-\d{2})", text, flags=re.MULTILINE)
    new_sections = []

    for section in sections:
        m = re.match(r"^## (\d{4}-\d{2}-\d{2})", section)
        if not m:
            continue
        try:
            section_date = datetime.fromisoformat(m.group(1)).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
        if since is None or section_date > since:
            new_sections.append(section.strip())

    return "\n\n".join(new_sections)


def _call_openclaw(token: str, prompt: str) -> str | None:
    payload = json.dumps({
        "model": "openclaw",
        "input": prompt,
    }).encode()
    req = urllib.request.Request(
        GATEWAY_URL,
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "x-openclaw-agent-id": "main",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read())
        return data["output"][0]["content"][0]["text"]
    except (urllib.error.URLError, KeyError, IndexError, json.JSONDecodeError) as e:
        print(f"  [오류] OpenClaw 호출 실패: {e}")
        return None


def reconstitute_project(proj_dir: Path, token: str) -> bool:
    """단일 프로젝트 context.md 재합성. 갱신되면 True 반환."""
    since = _load_reconstituted_at(proj_dir)
    new_summaries = _parse_new_summaries(proj_dir, since)
    if not new_summaries:
        return False

    context_path = proj_dir / "context.md"
    current_context = context_path.read_text() if context_path.exists() else "(없음)"

    prompt = CONTEXT_PROMPT.format(
        project=proj_dir.name,
        current_context=current_context,
        new_summaries=new_summaries,
    )

    result = _call_openclaw(token, prompt)
    if not result:
        return False

    context_path.write_text(result)
    _save_reconstituted_at(proj_dir)
    return True


def main() -> None:
    if not WIKI_ROOT.exists():
        print("WIKI_ROOT 없음:", WIKI_ROOT)
        return

    token = _get_gateway_token()
    updated = []

    for proj_dir in sorted(WIKI_ROOT.iterdir()):
        if not proj_dir.is_dir():
            continue
        if reconstitute_project(proj_dir, token):
            updated.append(proj_dir.name)

    if updated:
        print(f"갱신된 프로젝트 ({len(updated)}건): {', '.join(updated)}")


if __name__ == "__main__":
    main()
