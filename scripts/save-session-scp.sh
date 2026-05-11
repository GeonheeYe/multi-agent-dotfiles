#!/bin/bash
# Session transcript(user/assistant text) -> local raw save + remote SCP

TERMUX_HOME="/data/data/com.termux/files/home"
if [ -n "${LONGMEMORY_DIR:-}" ]; then
    LOCAL_LONGMEMORY_DIR="$LONGMEMORY_DIR"
elif [ -d "$TERMUX_HOME" ]; then
    LOCAL_LONGMEMORY_DIR="$TERMUX_HOME/LONGMEMORY"
else
    LOCAL_LONGMEMORY_DIR="$HOME/LONGMEMORY"
fi

SESSIONS_DIR="${SAVE_SESSION_DIR:-$LOCAL_LONGMEMORY_DIR/logs/session-hooks}"
mkdir -p "$SESSIONS_DIR"
LOG_FILE="$SESSIONS_DIR/save-session.log"
SAVE_SESSION_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LONGMEMORY_BUILTIN_SKILL_DIR="${LONGMEMORY_BUILTIN_SKILL_DIR:-/home/geonhee/dev/hermes-agent/skills/research/llm-wiki}"
LONGMEMORY_BUILTIN_SCRIPT_DIR="${LONGMEMORY_BUILTIN_SCRIPT_DIR:-$LONGMEMORY_BUILTIN_SKILL_DIR/scripts}"
exec 2>>"$LOG_FILE"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null || echo "unknown")
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null || echo "")
SOURCE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('source','unknown'))" 2>/dev/null || echo "unknown")

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === start session=${SESSION_ID:0:8} ===" >&2
echo "[save-session] source: $SOURCE" >&2
echo "[save-session] transcript_path: $TRANSCRIPT_PATH" >&2

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SESSION_SHORT="${SESSION_ID:0:8}"

if [ "${LONGMEMORY_LOCAL_PROCESS:-0}" = "1" ] || [ -d "/data/data/com.termux/files/home" ]; then
    OUTPUT_BASE_DIR="$LOCAL_LONGMEMORY_DIR/raw/unprocessed"
    KEEP_LOCAL_RAW=1
    mkdir -p "$OUTPUT_BASE_DIR"
    # Cursor watcher fires multiple times while a jsonl grows.
    # For Cursor source, overwrite a stable file name to avoid flooding raw/ with per-event files.
    if [ "$SOURCE" = "cursor" ]; then
        OUTPUT_FILE="$OUTPUT_BASE_DIR/cursor_${SESSION_SHORT}.md"
    else
        OUTPUT_FILE="$OUTPUT_BASE_DIR/${TIMESTAMP}_${SESSION_SHORT}.md"
    fi
else
    KEEP_LOCAL_RAW=1
    OUTPUT_BASE_DIR="$SESSIONS_DIR"
    OUTPUT_FILE="$OUTPUT_BASE_DIR/${TIMESTAMP}_${SESSION_SHORT}.md"
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "[save-session] transcript 없음, 스킵" >&2
    exit 0
fi

CONVERSATION=$(python3 - "$TRANSCRIPT_PATH" 2>/dev/null <<'PYEOF'
import sys, json

path = sys.argv[1]
parts = []

def append_message(role, text):
    if not text or not text.strip():
        return
    if role == "user":
        label = "## 사용자"
    else:
        label = "## Assistant"
    parts.append(f"{label}\n{text}")

with open(path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue
        t = obj.get("type")

        # Claude transcript format
        if t in ("user", "assistant"):
            content = obj.get("message", {}).get("content", "")
            if isinstance(content, list):
                text = "\n".join(c.get("text", "") for c in content if c.get("type") == "text")
            elif isinstance(content, str):
                text = content
            else:
                text = ""
            append_message(t, text)
            continue

        # Cursor agent-transcripts format (no "type", has {"role","message":{"content":[...]}})
        role = obj.get("role")
        if role in ("user", "assistant") and isinstance(obj.get("message"), dict):
            content = obj.get("message", {}).get("content", [])
            if isinstance(content, list):
                texts = []
                for c in content:
                    if not isinstance(c, dict):
                        continue
                    if c.get("type") == "text":
                        texts.append(c.get("text", ""))
                text = "\n".join(t for t in texts if t)
            elif isinstance(content, str):
                text = content
            else:
                text = ""
            append_message(role, text)
            continue

        # Codex transcript format
        if t == "response_item":
            payload = obj.get("payload", {})
            if payload.get("type") != "message":
                continue
            role = payload.get("role")
            if role not in ("user", "assistant"):
                continue
            content = payload.get("content", [])
            if isinstance(content, list):
                texts = []
                for c in content:
                    ctype = c.get("type")
                    if ctype in ("input_text", "output_text"):
                        texts.append(c.get("text", ""))
                text = "\n".join(t for t in texts if t)
            else:
                text = ""
            append_message(role, text)

print("\n\n".join(parts))
PYEOF
)

if [ -z "$CONVERSATION" ]; then
    echo "[save-session] 대화 내용 없음, 스킵" >&2
    exit 0
fi

{
    echo "# Claude 세션 대화"
    echo ""
    echo "- 세션 ID: $SESSION_ID"
    echo "- 일시: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "$CONVERSATION"
} > "$OUTPUT_FILE"

echo "[save-session] raw 저장: $OUTPUT_FILE" >&2

if [ "${LONGMEMORY_LOCAL_PROCESS:-0}" = "1" ]; then
    LOCAL_PROCESS_SCRIPT="${LONGMEMORY_LOCAL_PROCESS_SCRIPT:-$LONGMEMORY_BUILTIN_SCRIPT_DIR/process_longmemory_raw.py}"
    LOCAL_UPDATE_SCRIPT="${LONGMEMORY_LOCAL_UPDATE_SCRIPT:-$LONGMEMORY_BUILTIN_SCRIPT_DIR/update_longmemory_wiki.py}"
    if [ ! -f "$LOCAL_PROCESS_SCRIPT" ]; then
        LOCAL_PROCESS_SCRIPT="$SAVE_SESSION_SCRIPT_DIR/process_longmemory_raw.py"
    fi
    if [ ! -f "$LOCAL_UPDATE_SCRIPT" ]; then
        LOCAL_UPDATE_SCRIPT="$SAVE_SESSION_SCRIPT_DIR/update_longmemory_wiki.py"
    fi
    LOCAL_PROCESS_LOG="${LONGMEMORY_LOCAL_PROCESS_LOG:-$LOCAL_LONGMEMORY_DIR/process.log}"
    mkdir -p "$(dirname "$LOCAL_PROCESS_LOG")"
    if [ -f "$LOCAL_PROCESS_SCRIPT" ]; then
        LONGMEMORY_DIR="$LOCAL_LONGMEMORY_DIR" python3 "$LOCAL_PROCESS_SCRIPT" "$OUTPUT_FILE" >>"$LOCAL_PROCESS_LOG" 2>&1 || true
        echo "[save-session] local LONGMEMORY process 완료" >&2
    else
        echo "[save-session] local process script 없음: $LOCAL_PROCESS_SCRIPT" >&2
    fi
    if [ -f "$LOCAL_UPDATE_SCRIPT" ]; then
        LONGMEMORY_DIR="$LOCAL_LONGMEMORY_DIR" python3 "$LOCAL_UPDATE_SCRIPT" >>"$LOCAL_PROCESS_LOG" 2>&1 || true
        echo "[save-session] local LONGMEMORY wiki update 완료" >&2
    else
        echo "[save-session] local update script 없음: $LOCAL_UPDATE_SCRIPT" >&2
    fi
fi

REMOTE_ENABLED="${LONGMEMORY_REMOTE_ENABLED:-1}"
REMOTE_HOST="${LONGMEMORY_REMOTE_HOST:-geonhee-ubuntu}"
REMOTE_PORT="${LONGMEMORY_REMOTE_PORT:-22}"
REMOTE_WIKI_DIR="${LONGMEMORY_REMOTE_WIKI_DIR:-/home/geonhee/wiki}"
REMOTE_DIR="$REMOTE_WIKI_DIR"
REMOTE_RAW_DIR="${LONGMEMORY_REMOTE_RAW_DIR:-$REMOTE_WIKI_DIR/raw/unprocessed}"
REMOTE_BIN_DIR="${LONGMEMORY_REMOTE_BIN_DIR:-/home/geonhee/.local/share/llm-wiki/bin}"
REMOTE_PROCESS_SCRIPT="${LONGMEMORY_REMOTE_PROCESS_SCRIPT:-$REMOTE_BIN_DIR/process_longmemory_raw.py}"
REMOTE_UPDATE_SCRIPT="${LONGMEMORY_REMOTE_UPDATE_SCRIPT:-$REMOTE_BIN_DIR/update_longmemory_wiki.py}"
REMOTE_PROCESS_LOG="${LONGMEMORY_REMOTE_PROCESS_LOG:-/home/geonhee/.local/state/llm-wiki/process.log}"
# 기본값은 전송만 수행한다. 분류/위키 반영은 Hermes가 raw/unprocessed를 감시하며 처리한다.
# 이전 동작이 필요하면 LONGMEMORY_REMOTE_PROCESS_ENABLED=1 로 명시한다.
REMOTE_PROCESS_ENABLED="${LONGMEMORY_REMOTE_PROCESS_ENABLED:-0}"
SESSION_SHORT="${SESSION_ID:0:8}"

if [ "$REMOTE_ENABLED" = "0" ]; then
    echo "[save-session] remote 전송 비활성화 (LONGMEMORY_REMOTE_ENABLED=0)" >&2
    exit 0
fi

_shell_quote() {
    printf "%q" "$1"
}

_run_remote_transfer() {
    exec >>"$LOG_FILE" 2>&1

    echo "[save-session:bg] SCP 시작 session=$SESSION_SHORT pid=$$"

    local remote_raw_q
    local remote_bin_q
    local remote_log_dir_q
    local remote_wiki_q
    local remote_file
    local remote_file_q
    local process_script_q
    local update_script_q
    local process_log_q
    remote_raw_q="$(_shell_quote "$REMOTE_RAW_DIR")"
    remote_bin_q="$(_shell_quote "$REMOTE_BIN_DIR")"
    remote_log_dir_q="$(_shell_quote "$(dirname "$REMOTE_PROCESS_LOG")")"
    remote_wiki_q="$(_shell_quote "$REMOTE_WIKI_DIR")"
    remote_file="$REMOTE_RAW_DIR/$(basename "$OUTPUT_FILE")"
    remote_file_q="$(_shell_quote "$remote_file")"
    process_script_q="$(_shell_quote "$REMOTE_PROCESS_SCRIPT")"
    update_script_q="$(_shell_quote "$REMOTE_UPDATE_SCRIPT")"
    process_log_q="$(_shell_quote "$REMOTE_PROCESS_LOG")"

    ssh -p "$REMOTE_PORT" -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no \
        "$REMOTE_HOST" "mkdir -p $remote_raw_q $remote_bin_q $remote_log_dir_q"
    mkdir_rc=$?
    if [ $mkdir_rc -ne 0 ]; then
        echo "[save-session:bg] ssh mkdir 실패 rc=$mkdir_rc"
    fi

    if [ "$REMOTE_PROCESS_ENABLED" = "1" ]; then
        # Keep the canonical LONGMEMORY processor on the remote host in sync with the built-in Hermes llm-wiki copy.
        # Fallback to this dotfiles checkout only if the built-in script is absent.
        local script_dir
        script_dir="$LONGMEMORY_BUILTIN_SCRIPT_DIR"
        [ -d "$script_dir" ] || script_dir="$SAVE_SESSION_SCRIPT_DIR"
        for local_script in process_longmemory_raw.py update_longmemory_wiki.py longmemory_loader.py; do
            if [ -f "$script_dir/$local_script" ]; then
                scp -P "$REMOTE_PORT" -o ConnectTimeout=15 -o BatchMode=yes -o StrictHostKeyChecking=no \
                    "$script_dir/$local_script" "${REMOTE_HOST}:${REMOTE_BIN_DIR}/" \
                    && echo "[save-session:bg] remote script synced: $local_script" \
                    || echo "[save-session:bg] remote script sync failed: $local_script"
            fi
        done
    else
        echo "[save-session:bg] remote LONGMEMORY processing disabled; upload only"
    fi

    scp_success=0
    for attempt in 1 2 3; do
        scp -P "$REMOTE_PORT" -o ConnectTimeout=15 -o BatchMode=yes -o StrictHostKeyChecking=no \
            "$OUTPUT_FILE" "${REMOTE_HOST}:${REMOTE_RAW_DIR}/"
        rc=$?
        if [ $rc -eq 0 ]; then
            echo "[save-session:bg] SCP 전송 완료 (시도 ${attempt}, rc=0) → ${REMOTE_HOST}:${REMOTE_RAW_DIR}/"
            scp_success=1
            if [ "$REMOTE_PROCESS_ENABLED" = "1" ]; then
                ssh -p "$REMOTE_PORT" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no \
                    "$REMOTE_HOST" "if [ -f $process_script_q ]; then WIKI_PATH=$remote_wiki_q python3 $process_script_q $remote_file_q >> $process_log_q 2>&1; else echo '[save-session:bg] missing process script: $REMOTE_PROCESS_SCRIPT' >> $process_log_q; fi; if [ -f $update_script_q ]; then WIKI_PATH=$remote_wiki_q python3 $update_script_q >> $process_log_q 2>&1; fi"
                echo "[save-session:bg] LONGMEMORY 처리 스크립트 트리거됨"
            else
                echo "[save-session:bg] LONGMEMORY 처리 스크립트 미실행; Hermes classifier 대기"
            fi
            break
        fi
        echo "[save-session:bg] SCP 실패 (시도 ${attempt}, rc=${rc})"
        [ "$attempt" -lt 3 ] && sleep 3
    done

    if [ "$scp_success" -eq 0 ]; then
        echo "[save-session:bg] 최종 실패, 로컬만 저장됨: $OUTPUT_FILE"
    fi
    if [ "$KEEP_LOCAL_RAW" -ne 1 ]; then
        rm -rf "$OUTPUT_BASE_DIR"
        echo "[save-session:bg] 임시 raw 정리: $OUTPUT_BASE_DIR"
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] === end session=$SESSION_SHORT ==="
}

if [ "${SAVE_SESSION_SCP_SYNC:-0}" = "1" ]; then
    _run_remote_transfer
    echo "[save-session] SCP 동기 실행 완료 (session=$SESSION_SHORT)" >&2
else
    export LOG_FILE OUTPUT_FILE OUTPUT_BASE_DIR KEEP_LOCAL_RAW SAVE_SESSION_SCRIPT_DIR
    export REMOTE_HOST REMOTE_PORT REMOTE_WIKI_DIR REMOTE_DIR REMOTE_RAW_DIR REMOTE_BIN_DIR
    export REMOTE_PROCESS_SCRIPT REMOTE_UPDATE_SCRIPT REMOTE_PROCESS_LOG REMOTE_PROCESS_ENABLED SESSION_SHORT
    nohup bash -c "$(declare -f _shell_quote _run_remote_transfer); _run_remote_transfer" </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null || true
    echo "[save-session] SCP 백그라운드 분리 (session=$SESSION_SHORT), 훅 즉시 종료" >&2
fi
