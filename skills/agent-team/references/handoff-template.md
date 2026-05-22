# Handoff Template (auto_split)

각 단계에서 다음 역할로 넘기는 handoff 패킷 공통 템플릿이다. Root orchestrator가 자동 분리 실행 시 `briefs/<role>.md`와 함께 사용한다.

## Handoff packet

```markdown
## Handoff

- run-id: <run-id>
- execution_mode: auto_split
- current_stage: <현재 단계>
- next_stage: <다음 단계>
- sender: Root orchestrator
- receiver: <PM|Domain Expert|Architect|Developer|Reviewer>

### Inputs
- 사용자 요청 요약: ...
- run-state.json 경로: ...
- 필수 산출물/참조 파일:
  - ...
- assumptions.md 참조: ...

### Outputs
- 산출물 경로:
  - ...

### Constraints
- 포함 범위: ...
- 제외 범위: ...
- 검증 게이트웨이 기준: ...

### Required format
- 기존 템플릿/섹션을 유지하고, 누락 항목은 최소 메시지로 보완 요청
```

## 기록 규칙

- `auto_split`에서 생성한 handoff 기록은 `handoffs/auto-split-mode.md`에 타임스탬프 또는 단계 단위로 축적한다.
- 분리 실행 실패 시 실패 사유를 `handoffs/auto-split-mode.md`에 남기고, 동일 단계에서 재시도한다.
- `single_session` 모드에서는 해당 파일은 비워두거나 생략할 수 있다.
