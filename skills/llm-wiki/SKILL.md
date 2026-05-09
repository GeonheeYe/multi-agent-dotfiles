---
name: llm-wiki
description: Use when the user references LONGMEMORY, llm-wiki, wiki-*, project/session context, prior work, or asks to load context from a markdown wiki.
---

# LLM Wiki / LONGMEMORY Context Loader

LONGMEMORY is the first-class backend for project/session context. Use this before generic wiki behavior when the user asks for `llm-wiki`, `wiki-aegis`, `컨텍스트 불러와`, `저번에 하던 것`, or a known project.

## Loader

Prefer the bundled loader; do not depend on a shell alias.

```bash
python ~/dotfiles/scripts/longmemory_loader.py list
python ~/dotfiles/scripts/longmemory_loader.py load aegis
python ~/dotfiles/scripts/longmemory_loader.py load 사주 --recent-sessions 3
```

If `~/dotfiles` is unavailable, search for `longmemory_loader.py`; if running inside Hermes repo, use `skills/research/llm-wiki/scripts/longmemory_loader.py`.

Path resolution order:
1. `$LONGMEMORY_WIKI_PATH`
2. `$LONGMEMORY_DIR/wiki`
3. `$LONGMEMORY_PATH/wiki`
4. `~/LONGMEMORY/wiki`
5. `$WIKI_PATH`
6. `~/wiki`
7. SSH fallback only when `LONGMEMORY_REMOTE_HOST` or `LONGMEMORY_SSH_HOST` is set, using `LONGMEMORY_REMOTE_DIR` or `/home/geonhee/LONGMEMORY`.

## LONGMEMORY Layout

```text
LONGMEMORY/wiki/
├── index.md
├── projects/<slug>/
│   ├── overview.md
│   ├── context.md
│   ├── tasks.md
│   ├── decisions.md
│   ├── timeline.md
│   ├── summaries.md
│   └── YYYY-MM-DD_HH-MM-SS_<session>.md
└── topics/<slug>/
    ├── overview.md
    └── notes.md
```

## Workflow

1. Extract keyword:
   - `/llm-wiki XQbot` → `xqbot`
   - `wiki-aegis` → `aegis`
   - `llm-wiki 사주` → `사주`
   - no argument → run `longmemory_loader.py list` and show candidates.
2. Run `longmemory_loader.py load <keyword>`.
3. If `multiple_matches`, show candidates and ask which one.
4. If `no_match`, show available projects/topics; do not invent context.
5. If `ok: true`, summarize content from `overview.md`, `context.md`, `tasks.md`, `decisions.md`, `timeline.md`, `summaries.md`, and recent sessions.
6. Reply in Korean when the user is using Korean:

```text
[llm-wiki] <slug> 컨텍스트 로드 완료.

- 현재 상태: ...
- 최근 진행: ...
- 다음 할 일: ...
- 결정/주의사항: ...
- 참고 파일: projects/<slug>/overview.md, projects/<slug>/context.md, ...
```

## Session-End Ingestion Contract

Other devices should send session transcripts into the canonical LONGMEMORY host using `scripts/save-session-scp.sh`. The script uploads the raw markdown to `$LONGMEMORY_REMOTE_DIR/raw/unprocessed/`, syncs the latest processing scripts into `$LONGMEMORY_REMOTE_DIR/bin/`, then runs:

```bash
LONGMEMORY_DIR=$LONGMEMORY_REMOTE_DIR python3 $LONGMEMORY_REMOTE_DIR/bin/process_longmemory_raw.py <uploaded-file>
LONGMEMORY_DIR=$LONGMEMORY_REMOTE_DIR python3 $LONGMEMORY_REMOTE_DIR/bin/update_longmemory_wiki.py
```

After that, this loader reads the updated `LONGMEMORY/wiki` consistently from Hermes, Claude, Codex, Cursor, Telegram, or Discord.

## Error Handling

| Situation | Response |
|---|---|
| No local wiki | Try configured SSH fallback; otherwise report checked paths |
| No keyword | List projects/topics |
| Multiple matches | Ask user to choose exact slug |
| No match | Show available projects/topics |
| Missing `context.md` | Summarize from overview/tasks/timeline/summaries |
| Loader JSON error | Report command and stderr briefly; do not hallucinate context |
