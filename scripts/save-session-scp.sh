#!/bin/bash
# Session transcript(user/assistant text) -> local raw save + remote SCP

SESSIONS_DIR="${SAVE_SESSION_DIR:-$HOME/claude-sessions}"
mkdir -p "$SESSIONS_DIR"
LOG_FILE="$SESSIONS_DIR/save-session.log"
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

if [ -d "/data/data/com.termux/files/home" ]; then
    OUTPUT_BASE_DIR="/data/data/com.termux/files/home/LONGMEMORY/raw/unprocessed"
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

REMOTE_HOST="YOUR_S20_HOST"
REMOTE_DIR="~/LONGMEMORY"
SESSION_SHORT="${SESSION_ID:0:8}"

# SCP 전송은 훅 타임아웃(~60s)을 피하려고 백그라운드로 분리
# nohup + disown 으로 부모 종료 후에도 살아남도록 한다
nohup bash -c '
    LOG_FILE="'"$LOG_FILE"'"
    OUTPUT_FILE="'"$OUTPUT_FILE"'"
    OUTPUT_BASE_DIR="'"$OUTPUT_BASE_DIR"'"
    KEEP_LOCAL_RAW="'"$KEEP_LOCAL_RAW"'"
    REMOTE_HOST="'"$REMOTE_HOST"'"
    REMOTE_DIR="'"$REMOTE_DIR"'"
    SESSION_SHORT="'"$SESSION_SHORT"'"

    exec >>"$LOG_FILE" 2>&1

    echo "[save-session:bg] SCP 시작 session=$SESSION_SHORT pid=$$"

    ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no \
        "$REMOTE_HOST" "mkdir -p $REMOTE_DIR/raw"
    mkdir_rc=$?
    if [ $mkdir_rc -ne 0 ]; then
        echo "[save-session:bg] ssh mkdir 실패 rc=$mkdir_rc"
    fi

    scp_success=0
    for attempt in 1 2 3; do
        scp -P 8022 -o ConnectTimeout=15 -o BatchMode=yes -o StrictHostKeyChecking=no \
            "$OUTPUT_FILE" "${REMOTE_HOST}:${REMOTE_DIR}/raw/"
        rc=$?
        if [ $rc -eq 0 ]; then
            echo "[save-session:bg] SCP 전송 완료 (시도 ${attempt}, rc=0) → ${REMOTE_HOST}:${REMOTE_DIR}/raw/"
            scp_success=1
            # raw 수신 직후 분류 스크립트 실행
            ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no \
                "$REMOTE_HOST" "python3 ~/.openclaw/workspace/scripts/process_longmemory_raw.py >> ~/LONGMEMORY/process.log 2>&1" &
            echo "[save-session:bg] process_longmemory_raw.py 트리거됨"
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
    echo "[$(date '"'"'+%Y-%m-%d %H:%M:%S'"'"')] === end session=$SESSION_SHORT ==="
' </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

echo "[save-session] SCP 백그라운드 분리 (session=$SESSION_SHORT), 훅 즉시 종료" >&2
