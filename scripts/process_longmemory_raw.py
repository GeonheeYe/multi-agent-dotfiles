#!/usr/bin/env python3
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# 참고: 이 dotfiles 버전은 간이 스크립트라 현재 메인 분류 로직은
# workspace/scripts/process_longmemory_raw.py 쪽을 우선 사용한다.

LONGMEMORY = Path('/data/data/com.termux/files/home/LONGMEMORY')
RAW_DIR = LONGMEMORY / 'raw'
INBOX_DIR = LONGMEMORY / 'inbox'
WIKI_DIR = LONGMEMORY / 'wiki' / 'projects'
INDEX_FILE = LONGMEMORY / 'wiki' / 'index.md'

KNOWN_PROJECTS = {
    'aegis-ap': ['aegis-ap', 'aegis ap', 'wing기능', 'wing 기능'],
    'xqbot-paper': ['xqbot-paper', 'xqbot paper', 'xqbot', 'ablation study', '논문'],
    'career-change': ['이직', '채용', '지원', '면접', '자소서', 'career'],
}


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r'[^a-z0-9가-힣\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    text = re.sub(r'-+', '-', text).strip('-')
    return text or 'unclassified'


def detect_project(content: str, filename: str) -> str | None:
    hay = f"{filename}\n{content}".lower()
    scores = {}
    for slug, keywords in KNOWN_PROJECTS.items():
        score = sum(1 for kw in keywords if kw.lower() in hay)
        if score > 0:
            scores[slug] = score
    if not scores:
        return None
    return sorted(scores.items(), key=lambda x: (-x[1], x[0]))[0][0]


def append_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'a', encoding='utf-8') as f:
        if path.stat().st_size > 0:
            f.write('\n')
        f.write(text.rstrip() + '\n')


def ensure_project_files(slug: str):
    p = WIKI_DIR / slug
    p.mkdir(parents=True, exist_ok=True)
    files = {
        'overview.md': f"# {slug}\n\n- Display name: {slug}\n- Status: active\n- Created: {datetime.now().date()}\n- Summary: 프로젝트 개요를 여기에 적습니더.\n",
        'timeline.md': f"# {slug} Timeline\n",
        'tasks.md': f"# {slug} Tasks\n\n## Next Actions\n- [ ] 다음 할 일을 적습니더.\n",
        'decisions.md': f"# {slug} Decisions\n",
        'context.md': f"# {slug} Context\n",
    }
    for name, content in files.items():
        path = p / name
        if not path.exists():
            path.write_text(content, encoding='utf-8')


def update_index(slug: str):
    INDEX_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not INDEX_FILE.exists():
        INDEX_FILE.write_text('# LONGMEMORY Wiki Index\n\n## Projects\n', encoding='utf-8')
    txt = INDEX_FILE.read_text(encoding='utf-8')
    line = f'- [{slug}](./projects/{slug}/overview.md)'
    if line not in txt:
        if '## Projects\n' in txt:
            txt = txt.replace('## Projects\n', f'## Projects\n{line}\n')
        else:
            txt += f'\n## Projects\n{line}\n'
        INDEX_FILE.write_text(txt, encoding='utf-8')


def extract_next_actions(content: str) -> list[str]:
    actions = []
    for line in content.splitlines():
        s = line.strip()
        if not s:
            continue
        if any(tok in s.lower() for tok in ['todo', 'next', '해야', '할 일', '해야 할', '다음']):
            actions.append(s)
    return actions[:5]


def main(path_str: str):
    src = Path(path_str)
    if not src.exists():
        print(f'missing: {src}', file=sys.stderr)
        return 1

    content = src.read_text(encoding='utf-8', errors='replace')
    slug = detect_project(content, src.name)

    if slug is None:
        target = INBOX_DIR / src.name
        target.parent.mkdir(parents=True, exist_ok=True)
        if src.resolve() != target.resolve():
            src.replace(target)
        print(f'inbox:{target}')
        return 0

    ensure_project_files(slug)
    update_index(slug)

    now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
    timeline = WIKI_DIR / slug / 'timeline.md'
    append_text(timeline, f'## {now}\n- Raw session imported: `{src.name}`')

    actions = extract_next_actions(content)
    if actions:
        tasks = WIKI_DIR / slug / 'tasks.md'
        append_text(tasks, '## Imported from raw\n' + '\n'.join(f'- [ ] {a}' for a in actions))

    target_raw = RAW_DIR / slug / src.name
    target_raw.parent.mkdir(parents=True, exist_ok=True)
    if src.resolve() != target_raw.resolve():
        src.replace(target_raw)
    print(f'project:{slug}:{target_raw}')
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('usage: process_longmemory_raw.py <raw-file>', file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
