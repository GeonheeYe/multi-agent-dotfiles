#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from urllib import parse, request

TERMUX_HOME = Path('/data/data/com.termux/files/home')
DEFAULT_HOME = TERMUX_HOME if TERMUX_HOME.exists() else Path.home()
LONGMEMORY = Path(os.environ.get('LONGMEMORY_DIR', str(DEFAULT_HOME / 'LONGMEMORY'))).expanduser()
PROJECTS_DIR = LONGMEMORY / 'wiki' / 'projects'
TOPICS_DIR = LONGMEMORY / 'wiki' / 'topics'
OPENCLAW_CONFIG = Path(os.environ.get('OPENCLAW_CONFIG', str(DEFAULT_HOME / '.openclaw/openclaw.json'))).expanduser()
DEFAULT_TELEGRAM_CHAT_ID = 'YOUR_TELEGRAM_CHAT_ID'
INDEX_FILE = LONGMEMORY / 'wiki' / 'index.md'
INBOX_DIR = LONGMEMORY / 'inbox'
CLASSIFY_DONE_FILE = TOPICS_DIR / 'classification-commands.done.txt'
CLASSIFY_REPORT_FILE = TOPICS_DIR / 'classification-report.md'
PROCESSED_RAW_FILENAME = '.processed_raw.txt'


def append_text(path: Path, text: str) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''
    if text.strip() in existing:
        return False
    with open(path, 'a', encoding='utf-8') as f:
        if path.exists() and path.stat().st_size > 0:
            f.write('\n')
        f.write(text.rstrip() + '\n')
    return True


def _normalize_spaces(s: str) -> str:
    return re.sub(r'\s+', ' ', s).strip()


def _get_telegram_bot_token() -> str | None:
    try:
        obj = json.loads(OPENCLAW_CONFIG.read_text(encoding='utf-8'))
        token = obj.get('channels', {}).get('telegram', {}).get('botToken')
        if isinstance(token, str) and token.strip():
            return token.strip()
    except Exception:
        return None
    return None


def send_telegram_message(text: str) -> bool:
    token = _get_telegram_bot_token()
    if not token:
        return False
    try:
        url = f'https://api.telegram.org/bot{token}/sendMessage'
        data = parse.urlencode(
            {
                'chat_id': DEFAULT_TELEGRAM_CHAT_ID,
                'text': text,
                'disable_web_page_preview': 'true',
            }
        ).encode('utf-8')
        req = request.Request(url, data=data, method='POST')
        with request.urlopen(req, timeout=10) as resp:
            return 200 <= resp.status < 300
    except Exception:
        return False


def ensure_project_files(project_slug: str, display_name: str | None = None) -> None:
    p = PROJECTS_DIR / project_slug
    p.mkdir(parents=True, exist_ok=True)
    dn = display_name.strip() if isinstance(display_name, str) and display_name.strip() else project_slug
    defaults = {
        'overview.md': (
            f'# {project_slug}\n\n'
            f'- Display name: {dn}\n'
            '- Status: active\n'
            f'- Created: {datetime.now().date()}\n'
            '- Summary: 프로젝트 개요를 여기에 적습니다.\n'
        ),
        'timeline.md': f'# {project_slug} Timeline\n',
        'tasks.md': f'# {project_slug} Tasks\n\n## Next Actions\n- [ ] 다음 할 일을 적습니다.\n',
        'decisions.md': f'# {project_slug} Decisions\n',
        'context.md': f'# {project_slug} Context\n',
    }
    for name, content in defaults.items():
        path = p / name
        if not path.exists():
            path.write_text(content, encoding='utf-8')


def update_index(project_slug: str) -> None:
    INDEX_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not INDEX_FILE.exists():
        INDEX_FILE.write_text('# LONGMEMORY Wiki Index\n\n## Projects\n', encoding='utf-8')
    line = f'- [{project_slug}](./projects/{project_slug}/overview.md)'
    txt = INDEX_FILE.read_text(encoding='utf-8', errors='replace')
    if line not in txt:
        if '## Projects\n' in txt:
            txt = txt.replace('## Projects\n', f'## Projects\n{line}\n')
        else:
            txt += f'\n## Projects\n{line}\n'
        INDEX_FILE.write_text(txt, encoding='utf-8')


PROJECT_CREATE_RE = re.compile(r'(?m)^(?:새\s*프로젝트\s*만들어|프로젝트\s*추가)\s+(.+?)\s*$')
CLASSIFY_RE = re.compile(r'(?m)^분류\s+([a-z0-9][a-z0-9-]{1,63})\s+(.+?)\s*$')
UNDO_RE = re.compile(r'(?m)^되돌리기\s+([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}_[a-z0-9]{1,32}\.md)\s*$')
FILENAME_RE = re.compile(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}_[a-z0-9]{1,32}\.md$')


def extract_project_create_commands(content: str, limit: int = 5) -> list[str]:
    names: list[str] = []
    for m in PROJECT_CREATE_RE.finditer(content):
        name = _normalize_spaces(m.group(1))
        if name and name not in names:
            names.append(name)
        if len(names) >= limit:
            break
    return names


def extract_classify_commands(content: str, limit: int = 20) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    for m in CLASSIFY_RE.finditer(content):
        slug = m.group(1).strip().lower()
        payload = m.group(2).strip()
        files = [x.strip() for x in payload.split(',') if x.strip()]
        for filename in files:
            if FILENAME_RE.match(filename):
                out.append((slug, filename))
            if len(out) >= limit:
                return out
    return out


def extract_undo_commands(content: str, limit: int = 10) -> list[str]:
    out: list[str] = []
    for m in UNDO_RE.finditer(content):
        out.append(m.group(1).strip())
        if len(out) >= limit:
            break
    return out


def _load_done_commands() -> set[str]:
    try:
        txt = CLASSIFY_DONE_FILE.read_text(encoding='utf-8', errors='ignore')
        return {line.strip() for line in txt.splitlines() if line.strip()}
    except Exception:
        return set()


def _mark_done(signature: str) -> None:
    CLASSIFY_DONE_FILE.parent.mkdir(parents=True, exist_ok=True)
    existing = ''
    if CLASSIFY_DONE_FILE.exists():
        existing = CLASSIFY_DONE_FILE.read_text(encoding='utf-8', errors='ignore')
        if signature in existing:
            return
    with open(CLASSIFY_DONE_FILE, 'a', encoding='utf-8') as f:
        f.write(signature + '\n')


def _load_processed(project_dir: Path) -> set[str]:
    path = project_dir / PROCESSED_RAW_FILENAME
    if not path.exists():
        return set()
    txt = path.read_text(encoding='utf-8', errors='ignore')
    return {line.strip() for line in txt.splitlines() if line.strip()}


def _mark_processed(project_dir: Path, raw_name: str) -> None:
    path = project_dir / PROCESSED_RAW_FILENAME
    existing = _load_processed(project_dir)
    if raw_name in existing:
        return
    with open(path, 'a', encoding='utf-8') as f:
        f.write(raw_name + '\n')


def _ensure_project_tag(text: str, slug: str) -> str:
    lines = text.splitlines()
    tag = f'project: {slug}'
    for i, line in enumerate(lines[:30]):
        if line.strip().lower().startswith('project'):
            lines[i] = tag
            return '\n'.join(lines)
    return tag + '\n\n' + text.lstrip('\n')


def apply_classify_command(slug: str, filename: str) -> str | None:
    ensure_project_files(slug, display_name=slug)
    update_index(slug)
    src = INBOX_DIR / filename
    if not src.exists():
        return None
    dst = PROJECTS_DIR / slug / filename
    if dst.exists():
        return None
    content = src.read_text(encoding='utf-8', errors='replace')
    content = _ensure_project_tag(content, slug)
    src.write_text(content, encoding='utf-8')
    dst.parent.mkdir(parents=True, exist_ok=True)
    src.replace(dst)
    return f'classified:{slug}:{filename}'


def apply_undo_command(filename: str) -> str | None:
    src = None
    src_slug = None
    for proj in PROJECTS_DIR.iterdir():
        if not proj.is_dir():
            continue
        cand = proj / filename
        if cand.exists():
            src = cand
            src_slug = proj.name
            break
    if src is None:
        return None
    dst = INBOX_DIR / filename
    dst.parent.mkdir(parents=True, exist_ok=True)
    text = src.read_text(encoding='utf-8', errors='replace')
    if 'moved-from:' not in text[:200]:
        text = f'moved-from: {src_slug}\n' + text
    src.write_text(text, encoding='utf-8')
    src.replace(dst)
    return f'undone:{filename}:{src_slug}->inbox'


_LLM_HEADINGS = frozenset({'assistant', 'claude', 'gpt', 'llm', 'ai', 'model', 'response'})


def extract_one_liner(content: str) -> str:
    """첫 번째 ## 헤딩(LLM 응답 제외), 없으면 첫 번째 사용자 발화 1줄을 최대 80자로 반환."""
    skip_prefixes = ('#', '```', '- ', 'project:', 'moved-from:', 'source:', '<!--', '>')
    for line in content.splitlines():
        s = line.strip()
        if s.startswith('## ') and len(s) > 3:
            heading = s[3:].strip()
            if heading.lower() not in _LLM_HEADINGS:
                return heading[:80]
    for line in content.splitlines():
        s = line.strip()
        if not s:
            continue
        if any(s.startswith(p) for p in skip_prefixes):
            continue
        if len(s) >= 8:
            return s[:80]
    return ''


def update_project(project_dir: Path) -> list[str]:
    raw_files = sorted(
        [
            p for p in project_dir.iterdir()
            if p.is_file() and p.suffix == '.md'
            and p.name not in {'overview.md', 'timeline.md', 'tasks.md', 'decisions.md', 'context.md'}
        ]
    )
    if not raw_files:
        return []
    timeline = project_dir / 'timeline.md'
    processed = _load_processed(project_dir)
    changed: list[str] = []
    for raw in raw_files:
        if raw.name in processed:
            continue
        content = raw.read_text(encoding='utf-8', errors='replace')
        create_names = extract_project_create_commands(content)
        classify_cmds = extract_classify_commands(content)
        undo_cmds = extract_undo_commands(content)

        for name in create_names:
            slug = re.sub(r'-+', '-', re.sub(r'[\s_]+', '-', re.sub(r'[^a-z0-9가-힣\s-]', '', name.strip().lower()))).strip('-') or 'unclassified'
            p = PROJECTS_DIR / slug
            if not p.exists():
                ensure_project_files(slug, display_name=name)
                update_index(slug)
                send_telegram_message(f'새 프로젝트를 생성했습니다: {slug} ({name})')
                changed.append(f'created:{slug}')

        done = _load_done_commands()
        for slug, filename in classify_cmds:
            sig = f'classify:{slug}:{filename}'
            if sig in done:
                continue
            status = apply_classify_command(slug, filename)
            if status:
                changed.append(status)
                send_telegram_message(f'[LONGMEMORY] 분류 완료: {filename} → {slug}')
            _mark_done(sig)

        done = _load_done_commands()
        for filename in undo_cmds:
            sig = f'undo:{filename}'
            if sig in done:
                continue
            status = apply_undo_command(filename)
            if status:
                changed.append(status)
                send_telegram_message(f'[LONGMEMORY] 되돌리기 완료: {filename} → inbox')
            _mark_done(sig)

        date = datetime.now(timezone.utc).strftime('%Y-%m-%d')
        one_liner = extract_one_liner(content)
        entry = f'- `{raw.name}`' + (f' {one_liner}' if one_liner else '')
        tl_block = f'## {date}\n{entry}'
        if append_text(timeline, tl_block):
            changed.append(f'timeline:{project_dir.name}:{raw.name}')

        _mark_processed(project_dir, raw.name)
        processed.add(raw.name)
    return changed


def write_classification_report(changes: list[str]) -> None:
    inbox_count = len([p for p in INBOX_DIR.iterdir() if p.is_file()]) if INBOX_DIR.exists() else 0
    project_count = len([p for p in PROJECTS_DIR.iterdir() if p.is_dir()]) if PROJECTS_DIR.exists() else 0
    classified = sum(1 for x in changes if x.startswith('classified:'))
    undone = sum(1 for x in changes if x.startswith('undone:'))
    created = sum(1 for x in changes if x.startswith('created:'))
    now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
    block = (
        f'## {now}\n'
        f'- projects: {project_count}\n'
        f'- inbox: {inbox_count}\n'
        f'- classified: {classified}\n'
        f'- undone: {undone}\n'
        f'- created: {created}'
    )
    append_text(CLASSIFY_REPORT_FILE, block)


def main() -> int:
    if not PROJECTS_DIR.exists():
        print('no-projects-dir')
        return 0
    changes: list[str] = []
    for project_dir in sorted([p for p in PROJECTS_DIR.iterdir() if p.is_dir()]):
        changes.extend(update_project(project_dir))
    write_classification_report(changes)
    if not changes:
        print('no-wiki-updates')
    else:
        print('\n'.join(changes))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
