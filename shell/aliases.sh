# dotfiles/shell/aliases.zsh — 자동으로 ~/.zshrc에서 source됨 (setup.sh 참고)

# Claude/Codex 실행 전 dotfiles 최신화
_dotfiles_pull() { git -C ~/dotfiles pull --ff-only --quiet 2>/dev/null || true }

# Claude Code
cc()  { _dotfiles_pull; claude "$@" }
ccd() { _dotfiles_pull; claude --dangerously-skip-permissions "$@" }
ccr() { _dotfiles_pull; claude --resume --dangerously-skip-permissions "$@" }

# Codex
cdd() { _dotfiles_pull; codex --dangerously-bypass-approvals-and-sandbox "$@" }
