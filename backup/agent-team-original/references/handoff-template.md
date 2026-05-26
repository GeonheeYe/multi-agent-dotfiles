# brief `handoff` 섹션 템플릿

각 단계에서 다음 역할로 넘기는 `handoff` 섹션 공통 템플릿이다. Root orchestrator가 `briefs/<role>.md` 안에 포함한다.

## `briefs/<role>.md`에 포함할 `handoff` 섹션

```markdown
## `handoff`

- run-id: <run-id>
- execution_mode: auto_split
- current_stage: <지금 실행할 단계 값>
- next_stage: <이 역할이 완료되면 이동할 후보 단계 값>
- sender: Root orchestrator
- receiver: <PM|Domain Expert|Architect|Developer|Reviewer>

### 필수 입력
- 사용자 요청 요약: ...
- `run-state.json` 경로: ...
- 필수 산출물/참조 파일:
  - ...
- `assumptions.md` 참조: ...

### 필수 출력
- 산출물 경로:
  - ...

### 제약
- 포함 범위: 이번 역할이 다뤄야 하는 요구사항, 파일, 의사결정 범위
- 제외 범위: 이번 역할이 새로 결정하거나 수정하면 안 되는 범위
- `stage gate` 기준: 역할 완료 뒤 Root orchestrator가 확인할 필수 섹션, 출력 파일, 상태 갱신 조건

### 필수 형식
- 지정된 출력 파일에만 결과를 작성한다.
- 필수 입력이 없으면 임의로 채우지 말고 누락된 입력 이름과 필요한 이유를 보고한다.
- 기존 산출물을 수정해야 하면 수정한 섹션과 이유를 보고한다.
- `run-state.json`은 직접 수정하지 말고, Root orchestrator가 갱신할 수 있도록 완료한 산출물 경로, 제안하는 `next_stage`, `blocked_reason` 후보, 추가/변경한 가정 ID만 보고한다.
```

## `handoff` 기록과 실패 사유 갱신 규칙

- Root orchestrator는 다음 역할을 시작하기 전에 해당 `briefs/<role>.md`의 `handoff` 섹션을 갱신한다.
- 분리 실행 실패나 `stage gate` 실패 시 실패 사유를 수정/재실행 대상 역할의 `briefs/<role>.md`에 남긴다. 실패 사유에는 누락된 파일/섹션, 기대한 값, 실제 확인한 값, 재실행 대상 역할을 적는다.
- `single_session` 모드에서도 같은 `briefs/<role>.md`를 생성해 입력 경계와 전환 사유를 기록한다.
