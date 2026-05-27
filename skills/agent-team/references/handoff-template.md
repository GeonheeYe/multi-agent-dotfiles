# brief 작업 지시서 템플릿

각 단계에서 다음 역할로 넘기는 `briefs/<role>.md` 공통 템플릿이다. 사람에게 중요한 작업 지시는 상단에 두고, 실행 추적용 값은 하단 `System Handoff`에 둔다. Root orchestrator는 둘 다 관리하지만, 역할은 주로 `작업 목표`, `해야 할 일`, `입력`, `출력`, `범위`를 읽고 수행한다.

## `briefs/<role>.md` 기본 형식

```markdown
# <Role> Brief

## 작업 목표

<이번 역할이 달성해야 할 목표를 한두 문장으로 적는다.>

## 해야 할 일

- <역할이 확인하거나 작성해야 할 핵심 항목>
- <질문/검토/설계/구현/검증 범위>

## 입력

- 사용자 요청 요약: ...
- 저장소/프로젝트 위치: ...
- 컨텍스트: ...
- 실행 메타정보: ...
- PM 인터뷰 노트: ...
- 참조 파일:
  - ...
- 입력 산출물:
  - ...
- `assumptions.md`: ...
- 직전 Domain Expert Gateway 결과: ...
- `stage gate` 실패 항목: ...

## 출력

- 작성할 산출물:
  - ...

## 범위

- 포함: 이번 역할이 다뤄야 하는 요구사항, 파일, 의사결정 범위
- 제외: 이번 역할이 새로 결정하거나 수정하면 안 되는 범위

## 완료 기준

- 지정된 출력 파일에만 결과를 작성한다.
- 필수 입력이 없으면 임의로 채우지 말고 누락된 입력 이름과 `blocked_reason` 후보를 보고한다.
- 기존 산출물을 수정해야 하면 수정한 섹션과 수정 이유를 보고한다.
- `stage gate` 기준: 역할 완료 뒤 Root orchestrator가 확인할 필수 섹션, 출력 파일, 상태 갱신 조건
- 완료 보고: 완료한 산출물 경로, 제안하는 `next_stage`, `blocked_reason` 후보, 추가/변경한 가정 ID

## System Handoff

- run-id: <run-id>
- execution_mode: <auto_split|single_session>
- current_stage: <지금 실행할 단계 값>
- next_stage: <이 역할이 완료되면 이동할 후보 단계 값>
- sender: Root orchestrator
- receiver: <PM|Domain Expert|Architect|Developer|Reviewer>
- `run-state.json`: <경로>
```

## `System Handoff`와 `stage_gate_failure` 갱신 규칙

- Root orchestrator는 다음 역할을 시작하기 전에 해당 `briefs/<role>.md`의 작업 지시와 `System Handoff`를 갱신한다.
- `System Handoff`는 실행 재개, 상태 검증, 산출물 추적을 위한 메타데이터다. 사람이 읽는 핵심 지시는 상단 작업 지시 섹션에 둔다.
- 분리 실행 실패나 `stage gate` 실패 시 `stage_gate_failure` 항목을 수정/재실행 대상 역할의 `briefs/<role>.md`에 남긴다. `stage_gate_failure`에는 누락된 파일/섹션, 기대한 값, 실제 확인한 값, 재실행 대상 역할을 적는다.
- `single_session` 모드에서도 같은 `briefs/<role>.md`를 생성해 입력 경계와 `execution_mode` 전환 이유를 기록한다.
