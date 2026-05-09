#!/usr/bin/env python3
"""LONGMEMORY loader for Hermes llm-wiki skill.

Usage:
  python longmemory_loader.py list
  python longmemory_loader.py load <keyword-or-slug>

Outputs JSON so agents can summarize without guessing.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

CONTEXT_FILES = [
    "overview.md",
    "context.md",
    "tasks.md",
    "decisions.md",
    "timeline.md",
    "summaries.md",
]
EXCLUDED_SESSION_FILES = set(CONTEXT_FILES) | {"README.md", "index.md"}


def _read(path: Path, max_chars: int | None = None) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    if max_chars and len(text) > max_chars:
        return text[:max_chars].rstrip() + "\n...[truncated]"
    return text


def _parse_index(index: Path) -> list[str]:
    projects: list[str] = []
    if not index.exists():
        return projects
    for line in _read(index).splitlines():
        line = line.strip()
        if not line.startswith("- [") or "./projects/" not in line:
            continue
        name = line.split("]", 1)[0].removeprefix("- [").strip()
        if name and name not in projects:
            projects.append(name)
    return projects


def _candidate_wikis() -> list[Path]:
    out: list[Path] = []
    env_wiki = os.environ.get("LONGMEMORY_WIKI_PATH")
    if env_wiki:
        out.append(Path(env_wiki).expanduser())
    for key in ("LONGMEMORY_DIR", "LONGMEMORY_PATH"):
        val = os.environ.get(key)
        if val:
            out.append(Path(val).expanduser() / "wiki")
    out.append(Path.home() / "LONGMEMORY" / "wiki")
    wiki_path = os.environ.get("WIKI_PATH")
    if wiki_path:
        out.append(Path(wiki_path).expanduser())
    out.append(Path.home() / "wiki")

    seen: set[str] = set()
    uniq: list[Path] = []
    for p in out:
        key = str(p)
        if key not in seen:
            seen.add(key)
            uniq.append(p)
    return uniq


def resolve_local_wiki() -> Path | None:
    for wiki in _candidate_wikis():
        if (wiki / "index.md").exists() or (wiki / "projects").is_dir() or (wiki / "SCHEMA.md").exists():
            return wiki
    return None


def list_local(wiki: Path) -> dict[str, Any]:
    projects_dir = wiki / "projects"
    topics_dir = wiki / "topics"
    projects = _parse_index(wiki / "index.md")
    if not projects and projects_dir.is_dir():
        projects = sorted(p.name for p in projects_dir.iterdir() if p.is_dir())
    topics = sorted(p.name for p in topics_dir.iterdir() if p.is_dir()) if topics_dir.is_dir() else []
    return {"source": "local", "wiki": str(wiki), "projects": projects, "topics": topics}


def match_slug(items: list[str], keyword: str) -> tuple[str | None, list[str]]:
    key = keyword.strip().lower()
    if not key:
        return None, []
    exact = [x for x in items if x.lower() == key]
    if exact:
        return exact[0], exact
    contains = [x for x in items if key in x.lower()]
    if len(contains) == 1:
        return contains[0], contains
    return None, contains


def newest_session_files(directory: Path, limit: int = 3) -> list[Path]:
    files = [
        p for p in directory.glob("*.md")
        if p.is_file() and p.name not in EXCLUDED_SESSION_FILES
    ]
    return sorted(files, key=lambda p: p.stat().st_mtime, reverse=True)[:limit]


def load_local(wiki: Path, keyword: str, recent_sessions: int = 2, max_chars_per_file: int = 12000) -> dict[str, Any]:
    listing = list_local(wiki)
    projects = listing["projects"]
    topics = listing["topics"]

    project, project_matches = match_slug(projects, keyword)
    topic, topic_matches = match_slug(topics, keyword)

    if project and topic:
        # Prefer projects for session context, but report both.
        topic_matches = [topic]
    if not project and not topic:
        matches = project_matches + [f"topics/{x}" for x in topic_matches]
        return {
            "ok": False,
            "error": "multiple_matches" if matches else "no_match",
            "keyword": keyword,
            "matches": matches,
            "available_projects": projects,
            "available_topics": topics,
        }
    if len(project_matches) > 1 and not project:
        return {"ok": False, "error": "multiple_matches", "keyword": keyword, "matches": project_matches}
    if len(topic_matches) > 1 and not topic and not project:
        return {"ok": False, "error": "multiple_matches", "keyword": keyword, "matches": [f"topics/{x}" for x in topic_matches]}

    if project:
        base = wiki / "projects" / project
        kind = "project"
        slug = project
    else:
        base = wiki / "topics" / topic  # type: ignore[arg-type]
        kind = "topic"
        slug = topic

    files: dict[str, str] = {}
    for name in CONTEXT_FILES:
        path = base / name
        if path.exists():
            files[name] = _read(path, max_chars_per_file)
    recent: dict[str, str] = {}
    for path in newest_session_files(base, recent_sessions):
        recent[path.name] = _read(path, max_chars_per_file)
    return {
        "ok": True,
        "source": "local",
        "wiki": str(wiki),
        "kind": kind,
        "slug": slug,
        "base": str(base),
        "files": files,
        "recent_sessions": recent,
    }


def remote_host() -> str | None:
    return os.environ.get("LONGMEMORY_REMOTE_HOST") or os.environ.get("LONGMEMORY_SSH_HOST")


def remote_dir() -> str:
    return os.environ.get("LONGMEMORY_REMOTE_DIR", "/home/geonhee/LONGMEMORY")


def load_remote_via_ssh(command: str, keyword: str | None = None) -> dict[str, Any] | None:
    host = remote_host()
    if not host:
        return None
    script = Path(__file__).resolve()
    script_text = script.read_text(encoding="utf-8")
    cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", host]
    remote_wiki = str(Path(remote_dir()) / "wiki")
    if command == "list":
        remote_cmd = f"LONGMEMORY_WIKI_PATH={remote_wiki!r} python3 - list"
    else:
        assert keyword is not None
        remote_cmd = f"LONGMEMORY_WIKI_PATH={remote_wiki!r} python3 - load {keyword!r}"
    try:
        proc = subprocess.run(cmd + [remote_cmd], input=script_text, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
    except Exception as exc:
        return {"ok": False, "source": "remote", "error": "ssh_failed", "detail": str(exc)}
    if proc.returncode != 0:
        return {"ok": False, "source": "remote", "error": "remote_failed", "stderr": proc.stderr[-1000:]}
    try:
        data = json.loads(proc.stdout)
        if isinstance(data, dict):
            data.setdefault("source", "remote")
            data.setdefault("remote_host", host)
            return data
    except Exception as exc:
        return {"ok": False, "source": "remote", "error": "json_parse_failed", "detail": str(exc), "stdout": proc.stdout[-1000:]}
    return None


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Load LONGMEMORY project/wiki context")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    load_p = sub.add_parser("load")
    load_p.add_argument("keyword")
    load_p.add_argument("--recent-sessions", type=int, default=2)
    args = parser.parse_args(argv)

    local = resolve_local_wiki()
    # Prefer local when it exists; this covers running directly on geonhee-ubuntu/server.
    if args.cmd == "list":
        if local:
            print(json.dumps(list_local(local), ensure_ascii=False, indent=2))
            return 0
        remote = load_remote_via_ssh("list")
        if remote:
            print(json.dumps(remote, ensure_ascii=False, indent=2))
            return 0 if remote.get("ok", True) else 1
        print(json.dumps({"ok": False, "error": "no_wiki", "checked": [str(p) for p in _candidate_wikis()]}, ensure_ascii=False, indent=2))
        return 1

    if args.cmd == "load":
        if local:
            data = load_local(local, args.keyword, recent_sessions=args.recent_sessions)
            print(json.dumps(data, ensure_ascii=False, indent=2))
            return 0 if data.get("ok") else 2
        remote = load_remote_via_ssh("load", args.keyword)
        if remote:
            print(json.dumps(remote, ensure_ascii=False, indent=2))
            return 0 if remote.get("ok") else 2
        print(json.dumps({"ok": False, "error": "no_wiki", "keyword": args.keyword, "checked": [str(p) for p in _candidate_wikis()]}, ensure_ascii=False, indent=2))
        return 1
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
