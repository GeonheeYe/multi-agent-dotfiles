#!/usr/bin/env python3
"""
1회성 LONGMEMORY 노이즈 정리 스크립트.
모든 프로젝트의 timeline/tasks/decisions에서 자동 추출 쓰레기를 제거하고
.processed_raw.txt를 시드한다.
"""
import re
from pathlib import Path

LONGMEMORY = Path('/data/data/com.termux/files/home/LONGMEMORY')
PROJECTS_DIR = LONGMEMORY / 'wiki' / 'projects'
RAW_FILENAME_RE = re.compile(r'^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_[a-z0-9]{1,32}\.md$')
IMPORTED_SECTION_RE = re.compile(r'(?m)^## Imported from `[^`]+`.*?(?=\n## |\Z)', re.DOTALL)


def clean_timeline(path: Path) -> int:
    """중복 섹션 제거 후 1줄 포맷으로 압축. 수동 섹션은 보존."""
    if not path.exists():
        return 0
    txt = path.read_text(encoding='utf-8', errors='replace')
    parts = re.split(r'(?m)^## ', txt)
    header = parts[0]
    seen_raw: set[str] = set()
    kept: list[str] = []

    for b in parts[1:]:
        block = '## ' + b.strip()
        if not block.strip():
            continue
        m = re.search(r'- raw: `([^`]+)`', block)
        if not m:
            m = re.search(r'- Raw session imported: `([^`]+)`', block)
        if m:
            raw_name = m.group(1)
            if raw_name in seen_raw:
                continue
            seen_raw.add(raw_name)
            date_m = re.match(r'## (\d{4}-\d{2}-\d{2})', block)
            if date_m:
                date = date_m.group(1)
            else:
                dm2 = re.search(r'(\d{4}-\d{2}-\d{2})', block)
                date = dm2.group(1) if dm2 else '????-??-??'
            kept.append(f'## {date}\n- `{raw_name}` imported')
        else:
            kept.append(block)

    new = header.rstrip() + '\n\n' + '\n\n'.join(kept).rstrip() + '\n'
    if new != txt:
        path.write_text(new, encoding='utf-8')
        return 1
    return 0


def clean_imported_sections(path: Path) -> int:
    """## Imported from ... 섹션 전체 삭제."""
    if not path.exists():
        return 0
    txt = path.read_text(encoding='utf-8', errors='replace')
    new = IMPORTED_SECTION_RE.sub('', txt).rstrip() + '\n'
    new = re.sub(r'\n{3,}', '\n\n', new)
    if new != txt:
        path.write_text(new, encoding='utf-8')
        return 1
    return 0


def seed_processed(proj_dir: Path) -> int:
    """프로젝트 폴더 내 raw 파일명을 .processed_raw.txt에 시드."""
    raw_files = [
        p.name for p in proj_dir.iterdir()
        if p.is_file() and RAW_FILENAME_RE.match(p.name)
    ]
    proc_path = proj_dir / '.processed_raw.txt'
    existing: set[str] = set()
    if proc_path.exists():
        existing = {ln.strip() for ln in proc_path.read_text(encoding='utf-8').splitlines() if ln.strip()}
    new_entries = [n for n in raw_files if n not in existing]
    if new_entries:
        with open(proc_path, 'a', encoding='utf-8') as f:
            for n in new_entries:
                f.write(n + '\n')
        return len(new_entries)
    return 0


def main() -> None:
    if not PROJECTS_DIR.exists():
        print('projects dir not found')
        return
    for proj in sorted(p for p in PROJECTS_DIR.iterdir() if p.is_dir()):
        tl_changed = clean_timeline(proj / 'timeline.md')
        tk_changed = clean_imported_sections(proj / 'tasks.md')
        dc_changed = clean_imported_sections(proj / 'decisions.md')
        seeded = seed_processed(proj)
        print(f'{proj.name}: tl={tl_changed} tasks={tk_changed} decisions={dc_changed} seeded={seeded}')


if __name__ == '__main__':
    main()
