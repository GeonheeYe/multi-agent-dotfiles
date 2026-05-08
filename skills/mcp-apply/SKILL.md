---
name: mcp-apply
description: ~/dotfiles/mcp/servers.json을 읽어서 secrets.json의 값을 주입한 뒤 ./mcp/apply.sh를 실행해 Claude Code와 Codex CLI에 MCP 서버 설정을 적용한다. "/mcp-apply", "MCP 적용", "MCP 설정 반영" 요청에 사용.
---

# MCP Apply

`~/dotfiles/mcp/servers.json`에서 MCP 서버 설정을 읽고 `secrets.json`의 값을 주입한 뒤, `./mcp/apply.sh`를 실행해 Claude Code와 Codex CLI에 적용한다.

## 실행 절차

1. `~/dotfiles/mcp/servers.json` 확인
2. `~/dotfiles/mcp/secrets.json`의 값을 주입
3. `~/dotfiles/mcp/apply.sh` 실행

```bash
cd ~/dotfiles && ./mcp/apply.sh
```

## 주의

- secrets.json에 민감한 키가 포함되므로 git에 커밋하지 않도록 주의
- apply.sh 실행 후 Claude Code를 재시작해야 변경이 반영될 수 있음
