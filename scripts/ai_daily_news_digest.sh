#!/bin/bash
# AI 뉴스 다이제스트 자동 실행 스크립트
# 매일 08:00 cron으로 실행됨

set -e

LOG_DIR="$HOME/ai-quiz-log"
TODAY=$(date +%Y-%m-%d)
SCRIPT_LOG="$LOG_DIR/cron_${TODAY}.log"

mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] AI 뉴스 다이제스트 시작" >> "$SCRIPT_LOG"

# Claude Code CLI로 ai-daily-news 스킬 실행
"$HOME/.local/bin/claude" \
  --dangerously-skip-permissions \
  -p "ai-daily-news" \
  >> "$SCRIPT_LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 완료" >> "$SCRIPT_LOG"
