# 에이전트 팀 실행 규칙

이 문서는 `$agent-team`의 실행 규칙을 정의한다. `SKILL.md`는 핵심 흐름만 유지하고, 재개/재구성, 상태 전환, 게이트웨이 반복, 산출물 검증 기준, 에이전트 구조 세부사항은 여기서 관리한다. 산출물 목록과 가정/출력 규칙은 `references/artifacts.md`를 따른다.

## 에이전트 구조

`$agent-team`은 중앙 orchestrator가 통제하는 구조다.

- Root orchestrator: run directory, `run-state.json`, artifacts, gateway, retry count, `Blocked` input request, final user confirmation을 관리한다.
- 고정 서브에이전트: PM, Domain Expert, Architect, Developer, Reviewer. 고정 역할이며 흐름 순서 밖에서 서로 직접 지시하지 않는다.
- 보조 도구: 웹 검증기, 데이터 프로파일러, 보안 검사기, 벤치마크 실행기처럼 필요할 때만 호출하는 도구다.

실행은 `execution_mode`로 구분한다:

- `auto_split`: 각 역할을 분리 서브에이전트로 호출해 순차 진행.
- `single_session`: 역할 라벨링으로 동일 대화 안에서 순차 진행.

보조 도구 사용 규칙:

- 보조 도구는 고정 역할을 대체하지 않는다.
- 보조 도구를 사용하면 `run-state.json.used_helpers`에 도구 이름, 사용 단계, 이유, 결과 요약을 기록한다.
- 보조 도구 결과가 도메인 주장, 데이터 주장, 보안 주장, 벤치마크 주장을 바꾸면 관련 산출물과 `assumptions.md`도 갱신한다.
- 보조 도구 결과만으로 Domain Expert 게이트웨이를 통과시킨다고 간주하지 않는다.

## 분리 실행(handoff)

`auto_split` 모드에서는 Root orchestrator가 각 단계 시작 전에 handoff를 준비한다.

- `briefs/<role>.md`를 생성 또는 갱신해 입력만 전달하고, 역할별 산출물은 해당 출력 파일에만 작성한다.
- handoff 핵심 필드는 `run-id`, `current_stage`, `next_stage`, `required_inputs`, `required_outputs`, `constraints`, `assumptions_to_consider`다.
- 역할이 완료되면 해당 출력 파일 존재와 최소 검증 항목을 먼저 확인한 뒤 `run-state.json`의 `current_stage`/`last_completed_stage`/`next_stage`를 갱신한다.
- 검증 실패면 실패 항목을 handoff에 기록하고 재시도 또는 재구성 규칙으로 되돌린다.

## run-state.json

새 실행 디렉터리를 만들 때 아래 파일을 초기화한다:

`docs/agent-team/<run-id>/run-state.json`

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
  "used_helpers": [],
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ"
}
```

`execution_mode`는 런타임에서 실제 동작 모드를 기록한다.

단계 값:

- `initialized`
- `context_load`
- `briefs_created`
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

상태 갱신 규칙:

- 단계 시작 시 `current_stage`를 갱신한다.
- 단계 완료 시 `last_completed_stage`, `next_stage`, `artifacts`, `updated_at`을 갱신한다.
- 게이트웨이가 `Revise`면 해당 게이트웨이 재시도 횟수를 1 증가시키고 `next_stage`를 수정 대상 단계로 되돌린다.
- 게이트웨이가 `Blocked`면 `status`를 `blocked`로 두고 `blocked_reason`을 한 문장으로 기록한다.
- 최종 게이트웨이가 `Approved`면 `next_stage`를 `user_final_confirmation`으로 설정한다.
- Reviewer 발견 이슈 후 Developer 수정 반복이 시작되면 `review_retry_count`를 1 증가시킨다.
- 사용자가 최종 확인하면 `next_stage`를 `final_report`로 설정한다.
- 사용자가 최종 수정 요청을 하면 `status`를 `blocked`로 두고 수정 요청 요약을 `blocked_reason`에 기록한다.
- 최종 보고가 끝나면 `status`를 `completed`로 바꾼다.

## 재개와 재구성

사용자가 기존 실행을 이어가거나 실행 디렉터리를 지정하면 `run-state.json`을 먼저 읽는다.

재개 규칙:

- `status`가 `active`면 `next_stage`부터 이어간다.
- `status`가 `blocked`면 `blocked_reason`을 보여주고, 사용자의 새 입력이 진행 차단 사유를 해소하는지 확인한 뒤 이어간다.
- `status`가 `completed`면 새 실행을 만들지, 기존 결과를 검토/재구성할지 묻는다.
- 기존 산출물은 임의로 덮어쓰지 않는다. 사용자가 재작성 요청을 했거나 게이트웨이 `Revise`가 해당 산출물 수정을 요구한 경우에만 갱신한다.

재구성 규칙:

- 재구성은 산출물을 다시 실행하는 것이 아니라, 현재 산출물과 상태를 읽고 결정 이력을 재구성하는 것이다.
- 재구성 결과가 상태와 맞지 않으면 `run-state.json`을 바로 고치지 말고 불일치 내용을 사용자에게 보고한다.
- 재구성 중 누락 산출물이 발견되면 `status`를 `blocked`로 바꾸기 전에 해당 산출물이 현재 단계에 실제로 필요한지 확인한다.

## 산출물 검증 기준

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

게이트웨이 산출물 `02/04/08-expert-gateway-*.md`:

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

검증 기준 실패 처리:

- 다음 단계로 넘기기 전에 누락 항목을 확인한다.
- 누락이 단순 산출물 형식 문제면 작성 역할이 자동 보완한다.
- 누락이 범위, 도메인 주장, 데이터 가용성 문제면 Domain Expert 또는 사용자 입력으로 되돌린다.
- 검증 기준 통과는 도메인 승인이나 코드 품질 승인이 아니다.
