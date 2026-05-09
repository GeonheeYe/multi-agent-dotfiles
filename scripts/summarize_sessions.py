#!/usr/bin/env python3
"""raw 세션 파일을 OpenClaw gateway(Gemini)로 요약해 summaries.md에 누적한다."""
from __future__ import annotations

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from urllib import request as url_request

TERMUX_HOME = Path('/data/data/com.termux/files/home')
DEFAULT_HOME = TERMUX_HOME if TERMUX_HOME.exists() else Path.home()
LONGMEMORY = Path(os.environ.get('LONGMEMORY_DIR', str(DEFAULT_HOME / 'LONGMEMORY'))).expanduser()
PROJECTS_DIR = LONGMEMORY / 'wiki' / 'projects'
OPENCLAW_CONFIG = Path(os.environ.get('OPENCLAW_CONFIG', str(DEFAULT_HOME / '.openclaw/openclaw.json'))).expanduser()
SUMMARIZED_FILENAME = '.summarized_raw.txt'
RAW_RE = re.compile(r'^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_[a-z0-9]{1,32}\.md$')
MIN_CONTENT_LEN = 100
GATEWAY_URL = 'http://127.0.0.1:18789/v1/responses'

_LLM_SECTION_RE = re.compile(
    r'(?m)^## (?:Assistant|Claude|GPT|LLM|AI|Model|Response).*?(?=\n## |\Z)',
    re.DOTALL | re.IGNORECASE,
)
_CODE_BLOCK_RE = re.compile(r'(?s)```.*?```')
_SKIP_PREFIXES = ('project:', 'moved-from:', 'source:', '#', '<!--')

SUMMARIZE_PROMPT = (
    '아래는 AI 어시스턴트와의 세션에서 사용자 발화만 추출한 내용입니다.\n'
    '이 내용을 한국어 불릿 리스트 5-7개로 요약해주세요.\n'
    '- 사용자가 무엇을 하려 했는지 중심으로\n'
    '- 중요한 결론이나 결정이 있으면 포함\n'
    '- 각 항목은 한 줄, 간결하게\n\n'
    '세션 내용:\n{content}'
)


def _get_gateway_token() -> str | None:
    try:
        obj = json.loads(OPENCLAW_CONFIG.read_text(encoding='utf-8'))
        token = obj.get('gateway', {}).get('auth', {}).get('token', '').strip()
        return token or None
    except Exception:
        return None


def extract_user_content(text: str) -> str:
    """LLM 응답 섹션과 코드블록을 제거하고 사용자 발화만 반환."""
    text = _LLM_SECTION_RE.sub('', text)
    text = _CODE_BLOCK_RE.sub('', text)
    lines = []
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        if any(s.startswith(p) for p in _SKIP_PREFIXES):
            continue
        lines.append(s)
    return '\n'.join(lines)


def call_openclaw(token: str, user_content: str) -> str | None:
    """OpenClaw gateway /v1/responses로 요약 생성. 실패 시 None 반환."""
    prompt = SUMMARIZE_PROMPT.format(content=user_content[:4000])
    payload = json.dumps({
        'model': 'openclaw',
        'input': prompt,
    }).encode('utf-8')
    req = url_request.Request(
        GATEWAY_URL,
        data=payload,
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'x-openclaw-agent-id': 'main',
        },
        method='POST',
    )
    try:
        with url_request.urlopen(req, timeout=60) as resp:
            body = json.loads(resp.read())
            for out in body.get('output', []):
                for part in out.get('content', []):
                    if part.get('type') == 'output_text':
                        return part.get('text', '').strip()
            return None
    except Exception as e:
        print(f'[summarize] gateway error: {e}')
        return None


def _load_summarized(proj_dir: Path) -> set[str]:
    p = proj_dir / SUMMARIZED_FILENAME
    if not p.exists():
        return set()
    return {ln.strip() for ln in p.read_text(encoding='utf-8').splitlines() if ln.strip()}


def _mark_summarized(proj_dir: Path, raw_name: str) -> None:
    p = proj_dir / SUMMARIZED_FILENAME
    existing = _load_summarized(proj_dir)
    if raw_name in existing:
        return
    with open(p, 'a', encoding='utf-8') as f:
        f.write(raw_name + '\n')


def _append_summary(proj_dir: Path, raw_name: str, bullets: str) -> None:
    path = proj_dir / 'summaries.md'
    if not path.exists():
        path.write_text(f'# {proj_dir.name} Summaries\n', encoding='utf-8')
    date = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    short = raw_name.split('_')[-1].replace('.md', '')  # hash 부분
    block = f'\n## {date} · `{short}`\n{bullets}\n'
    with open(path, 'a', encoding='utf-8') as f:
        f.write(block)


def summarize_project(proj_dir: Path, token: str) -> int:
    """프로젝트 내 미처리 raw 파일 요약. 처리 건수 반환."""
    summarized = _load_summarized(proj_dir)
    raw_files = sorted(
        p for p in proj_dir.iterdir()
        if p.is_file() and RAW_RE.match(p.name) and p.name not in summarized
    )
    count = 0
    for raw in raw_files:
        text = raw.read_text(encoding='utf-8', errors='replace')
        user_content = extract_user_content(text)
        if len(user_content) < MIN_CONTENT_LEN:
            _mark_summarized(proj_dir, raw.name)
            continue
        bullets = call_openclaw(token, user_content)
        if bullets is None:
            continue  # 실패 시 재시도를 위해 기록 안 함
        _append_summary(proj_dir, raw.name, bullets)
        _mark_summarized(proj_dir, raw.name)
        count += 1
    return count


def main() -> int:
    token = _get_gateway_token()
    if not token:
        print('[summarize] gateway 토큰 없음. openclaw.json gateway.auth.token을 확인하세요.')
        return 1
    if not PROJECTS_DIR.exists():
        print('[summarize] projects 디렉토리 없음')
        return 0
    total = 0
    for proj in sorted(p for p in PROJECTS_DIR.iterdir() if p.is_dir()):
        n = summarize_project(proj, token)
        if n:
            print(f'[summarize] {proj.name}: {n}건 요약')
        total += n
    print(f'[summarize] 완료: 총 {total}건')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
