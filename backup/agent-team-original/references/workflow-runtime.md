# 에이전트 팀 실행 규칙

이 문서는 `$agent-team`의 실행 규칙을 정의한다. `SKILL.md`는 핵심 흐름만 유지하고, 재개/재구성, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리와 반복 한도, 산출물 검증 기준, 에이전트 구조 세부사항은 여기서 관리한다. 산출물 목록과 가정/출력 규칙은 `references/artifacts.md`를 따른다.

## Root orchestrator와 역할 실행 구조

`$agent-team`은 Root orchestrator가 통제하는 구조다.

- Root orchestrator: 실행 디렉터리 준비, `run-state.json` 갱신, 산출물 경로/존재 확인, `stage gate`, Domain Expert 결정 결과 기록과 분기, 재시도 횟수 관리, `Blocked` 상태의 사용자 입력 요청, 최종 사용자 확인과 `09-final-report.md` 작성을 담당한다.
- 고정 역할: PM, Domain Expert, Architect, Developer, Reviewer. `auto_split`에서는 각 역할이 `sub-agent`로 실행되고, `single_session`에서는 역할 라벨로 실행된다. 흐름 순서 밖에서 서로 직접 지시하지 않는다.

실행은 `execution_mode`로 구분한다:

- `auto_split`: 각 역할을 분리 `sub-agent`로 호출해 순차 진행.
- `single_session`: 역할 라벨링으로 동일 대화 안에서 순차 진행.

Root orchestrator와 Domain Expert의 `gate` 책임은 분리한다:

- Root orchestrator `stage gate`: 모든 단계 전환 전에 산출물 파일이 존재하는지, 해당 산출물이 이 문서의 최소 검증 기준을 만족하는지, `run-state.json`을 다음 단계로 갱신할 수 있는지, 다음 역할의 `briefs/<role>.md`가 준비됐는지 확인한다. 도메인 유효성은 판단하지 않는다.
- Domain Expert Gateway: PM 명세, Architect design, 최종 결과의 도메인 유효성을 판단하고 `Approved`, `Revise`, `Blocked`를 결정한다.

Codex 런타임 규칙:

- `auto_split`은 `$agent-team` 호출이 역할 분리 실행을 명시적으로 요청한 것으로 간주할 때만 사용한다.
- `auto_split` 시작 전에 `spawn_agent`, `wait_agent`, `close_agent`가 노출되어 있는지 확인한다. 이 도구들은 Codex config의 `[features].collab = true`에서 활성화된다.
- 세 도구 중 하나라도 사용할 수 없으면 `execution_mode`를 `single_session`으로 기록하고 시작 출력에 전환 사유를 한 줄로 표시한다. 전환 사유에는 사용할 수 없었던 도구 이름을 적는다.
- `sub-agent`는 순차 호출한다. 다음 역할을 시작하려면 이전 역할의 출력 파일과 Root orchestrator 수신 검증이 끝나야 한다.

## 역할 간 `handoff`와 `briefs/<role>.md` 갱신

Root orchestrator는 각 단계 시작 전에 다음 역할의 `briefs/<role>.md`를 준비한다. 이 파일 안에 `handoff` 섹션을 포함한다.

- Root orchestrator가 `briefs/<role>.md`를 생성 또는 갱신해 입력만 전달하고, 역할별 산출물은 해당 출력 파일에만 작성한다.
- `handoff` 핵심 필드는 `run-id`, `current_stage`, `next_stage`, `required_inputs`, `required_outputs`, `constraints`, `assumptions_to_consider`다.
- 역할이 완료되면 Root orchestrator가 `stage gate`를 수행한다. 해당 출력 파일 존재와 최소 검증 항목을 먼저 확인한 뒤 `run-state.json`의 `current_stage`/`last_completed_stage`/`next_stage`를 갱신한다.
- `stage gate` 실패면 실패 항목을 수정/재실행 대상 역할의 `briefs/<role>.md`에 기록한다. 실패 항목에는 누락된 산출물, 누락된 필수 섹션, 잘못된 `run-state.json` 값, 다음 시도에서 고쳐야 할 내용을 적는다.

## run-state.json 상태 파일

새 실행 디렉터리를 만들 때 아래 파일을 초기화한다:

`<선택한 저장 위치>/docs/agent-team/<run-id>/run-state.json`

스키마:

```json
{
  "run_id": "YYYY-MM-DD-topic-slug",
  "mode": "planning|implementation",
  "execution_mode": "auto_split|single_session",
  "status": "active|blocked|completed",
  "current_stage": "initialized",
  "last_completed_stage": null,
  "next_stage": "context_load",
  "gateway_retry_count": {
    "spec": 0,
    "design": 0,
    "final": 0
  },
  "review_retry_count": 0,
  "last_decision": null,
  "blocked_reason": null,
  "open_assumptions": [],
  "artifacts": {},
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ"
}
```

필드 의미:

- `execution_mode`: 런타임에서 실제 동작 모드를 기록한다.
- `status`: 전체 실행 상태를 기록한다. 진행 중이면 `active`, 사용자 입력이나 한도 초과로 멈추면 `blocked`, 최종 보고까지 끝나면 `completed`다.
- `current_stage`: 지금 수행 중인 단계다.
- `last_completed_stage`: 마지막으로 `stage gate`를 통과한 단계다.
- `next_stage`: 다음에 실행할 단계다.
- `gateway_retry_count`: Domain Expert Gateway가 `Revise`를 낸 횟수를 명세, 설계, 최종 단계별로 기록한다.
- `review_retry_count`: Reviewer 발견 이슈로 Developer 수정과 Reviewer 재검증을 반복한 횟수를 기록한다.
- `last_decision`: 마지막 Domain Expert Gateway 결정을 기록한다. Root orchestrator의 `stage gate` 결과는 이 필드에 기록하지 않는다.
- `blocked_reason`: `status`가 `blocked`일 때 사용자에게 필요한 판단, 누락 입력, 한도 초과 사유를 한 문장으로 기록한다.
- `open_assumptions`: `assumptions.md`에 있는 열린 가정의 ID 목록만 기록한다. 가정 본문과 근거는 `assumptions.md`를 원본으로 유지한다.
- `artifacts`: 생성 또는 갱신된 산출물 경로를 단계별로 기록한다.

단계 값:

- `initialized`
- `context_load`
- `briefs_created`: 초기 `briefs/<role>.md` scaffold 생성 완료. 이후 단계별 `handoff` 내용은 각 역할 시작 전에 계속 갱신한다.
- `pm_spec`
- `expert_gateway_spec`
- `architect_design`
- `expert_gateway_design`
- `work_plan`
- `developer_implementation`
- `reviewer_verification`
- `expert_gateway_final`
- `user_final_confirmation`
- `final_report`

`run-state.json` 상태 갱신 규칙:

- 단계 시작 시 `current_stage`를 지금 실행하는 단계 값으로 갱신한다. 예: PM 명세를 작성하기 시작하면 `current_stage`는 `pm_spec`이다.
- 단계가 `stage gate`를 통과하면 `last_completed_stage`를 방금 끝난 단계로 갱신하고, `next_stage`를 다음 실행 단계로 갱신한다. 생성 또는 갱신된 파일은 `artifacts`에 기록하고 `updated_at`을 현재 시각으로 갱신한다.
- 명세 Domain Expert Gateway가 `Approved`면 `last_decision`에 결정을 기록하고 `next_stage`를 `architect_design`으로 설정한다.
- 명세 Domain Expert Gateway가 `Revise`면 `gateway_retry_count.spec`을 1 증가시키고 `next_stage`를 `pm_spec`으로 되돌린다.
- 설계 Domain Expert Gateway가 `Approved`면 `last_decision`에 결정을 기록하고 `next_stage`를 `work_plan`으로 설정한다.
- 설계 Domain Expert Gateway가 `Revise`면 `gateway_retry_count.design`을 1 증가시키고 `next_stage`를 `architect_design`으로 되돌린다.
- 최종 Domain Expert Gateway가 `Revise`면 `gateway_retry_count.final`을 1 증가시킨다. 구현 결과나 Reviewer 검증 결과가 승인된 명세/설계와 다르다는 문제면 `next_stage`를 `developer_implementation`으로 되돌리고, 이후 `reviewer_verification`과 `expert_gateway_final`을 다시 거친다. 도메인 입력 누락, 명세 전제 오류, 설계 전제 오류처럼 현재 역할이 산출물만 고쳐서는 판단할 수 없는 문제면 `status`를 `blocked`로 두고 `blocked_reason`에 필요한 사용자 입력을 기록한다.
- Domain Expert Gateway가 `Blocked`면 `status`를 `blocked`로 두고 `blocked_reason`에 필요한 사용자 입력이나 판단을 한 문장으로 기록한다.
- 최종 Domain Expert Gateway가 `Approved`면 `last_decision`에 결정을 기록하고 `next_stage`를 `user_final_confirmation`으로 설정한다.
- Reviewer가 Developer 수정이 필요한 이슈를 발견하면 `review_retry_count`를 1 증가시키고 `next_stage`를 `developer_implementation`으로 되돌린다. Developer 수정 후에는 `reviewer_verification`을 다시 실행한다.
- 사용자가 최종 확인하면 `next_stage`를 `final_report`로 설정한다.
- 사용자가 최종 수정 요청을 하면 `status`를 `blocked`로 두고 수정 요청 요약과 되돌아갈 후보 단계를 `blocked_reason`에 기록한다.
- Root orchestrator가 `09-final-report.md`를 작성하면 `status`를 `completed`로 바꾼다.

재시도 한도:

- 각 Domain Expert Gateway의 `Revise` 반복은 최대 2회다.
- Developer fix -> Reviewer re-verification 반복은 최대 2회다.
- 한도를 초과하면 `status`를 `blocked`로 두고 `blocked_reason`에 초과한 한도, 마지막 실패 이유, 사용자가 선택해야 할 다음 행동을 기록한 뒤 사용자에게 묻는다.

## 기존 실행 재개와 `run-state.json` 상태 재구성

사용자가 기존 실행을 이어가거나 실행 디렉터리를 지정하면 `run-state.json`을 먼저 읽는다.

재개 규칙:

- `status`가 `active`면 `next_stage`부터 이어간다.
- `status`가 `blocked`면 `blocked_reason`을 보여주고, 사용자의 새 입력이 진행 차단 사유를 해소하는지 확인한 뒤 이어간다.
- `status`가 `completed`면 새 실행을 만들지, 기존 결과를 검토/재구성할지 묻는다.
- 기존 산출물은 임의로 덮어쓰지 않는다. 사용자가 재작성 요청을 했거나 Domain Expert Gateway `Revise`가 해당 산출물 수정을 요구한 경우에만 갱신한다.

재구성 규칙:

- 재구성은 산출물을 다시 작성하거나 역할을 다시 실행하는 작업이 아니다. 현재 실행 디렉터리의 파일과 `run-state.json`을 읽어 어떤 단계까지 끝났는지 판단하는 작업이다.
- 재구성할 때는 산출물 존재 여부, 각 산출물의 결정값, `last_completed_stage`, `next_stage`, `artifacts` 목록이 서로 맞는지 비교한다.
- 재구성 결과가 `run-state.json`과 맞지 않으면 `run-state.json`을 바로 고치지 않는다. 불일치한 필드, 파일 근거, 제안하는 수정값을 사용자에게 보고한다.
- 재구성 중 누락 산출물이 발견되면 `status`를 `blocked`로 바꾸기 전에 해당 산출물이 현재 `next_stage`를 실행하는 데 실제로 필요한지 확인한다.

## `stage gate` 산출물 최소 검증 기준

각 산출물은 다음 최소 요건을 만족해야 다음 단계의 입력으로 사용할 수 있다.

PM 명세 `01-pm-spec.md`:

- 상세 사용자 시나리오
  - 페르소나 또는 주요 사용자
  - 시작 조건과 사용 맥락
  - 사용자가 끝내려는 일 또는 결정
  - 입력 데이터와 기대 출력
  - 정상 흐름
  - 예외 사례
  - 실패/예외 상황
  - 성공 기준과 수용 기준
  - 운영/업무 제약
- 포함 범위
- 제외 범위 또는 비목표
- 목표와 성공 지표
- 데이터 명세
- AI 기능 고려사항 또는 해당 없음 명시
- 열린 질문
- 가정 ID 참조

Domain Expert Gateway 산출물 `02/04/08-expert-gateway-*.md`:

- `결정: Approved | Revise | Blocked`
- 검토한 가정
- 도메인 리스크
- 필수 수정사항
- 메모

아키텍처 설계 `03-architect-design.md`:

- 컴포넌트와 책임
- 데이터/모델/제어 흐름
- 기술 스택 후보와 결정 또는 기존 스택 유지 사유
- 평가 방식
- 실패 모드
- 추가/변경한 가정 ID

Task Plan `05-work-plan.md`:

- 각 작업의 목적
- 입력
- 출력
- 의존성
- 검증 방법
- 예상 변경 영역

Developer implementation `06-developer-implementation.md`:

- 구현한 내용
- 변경 파일
- 실행한 명령
- 계획 대비 변경
- 해결/추가한 가정 ID

Reviewer verification `07-reviewer-verification.md`:

- 실행한 검증
- 발견 이슈를 심각도로 분류
- 명세/설계 준수 여부
- 남은 차이
- 열린 가정
- 검증하지 못한 항목이 있으면 이유

Final report `09-final-report.md`:

- 작성자: Root orchestrator
- 최종 결과 요약
- 주요 산출물 경로
- 테스트/평가 결과
- 남은 차이 또는 열린 가정
- 최종 Domain Expert 결정
- 사용자 최종 확인 결과

검증 기준 실패 처리:

- 다음 단계로 넘기기 전에 누락 항목을 확인한다.
- 누락이 제목, 필수 섹션, 경로 기록 같은 산출물 형식 문제면 작성 역할이 같은 단계에서 보완한다.
- 누락이 포함 범위, 도메인 주장, 데이터 가용성, 사용자 의사결정 문제면 Root orchestrator가 Domain Expert Gateway 또는 사용자 입력으로 되돌린다.
- `stage gate` 검증 기준 통과는 도메인 승인이나 코드 품질 승인이 아니다.
