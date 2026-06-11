# 에이전트 팀 실행 규칙

`$agent-team` 실행 규칙은 재개/재구성, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리와 반복 한도, 산출물 검증 기준, 에이전트 구조 세부사항을 포함한다. 산출물 목록과 가정/출력 규칙은 `references/artifacts.md`를 따른다.

## Root orchestrator와 역할 실행 구조

`$agent-team`은 Root orchestrator가 통제하는 구조다.

- Root orchestrator: 실행 디렉터리 준비, 초기 파일 생성, `run-state.json` 갱신, 산출물 경로/존재 확인, `stage gate`, Domain Expert Gateway 결과를 `last_decision`에 기록하고 분기하는 일, `gateway_retry_count`/`review_retry_count` 관리, `Blocked` 상태의 사용자 입력 요청, `user_final_confirmation`, `09-final-report.md` 작성을 담당한다. 프로젝트 의미 정리와 PM 인터뷰 내용은 직접 작성하지 않는다.
- 고정 역할: PM, Domain Expert, Architect, Developer, Reviewer. PM 인터뷰는 항상 현재 대화에서 실행한다. `auto_split`에서는 PM 인터뷰 이후 역할을 `sub-agent`로 실행하고, `single_session`에서는 역할 라벨로 실행된다. 흐름 순서 밖에서 서로 직접 지시하지 않는다.

실행은 `execution_mode`로 구분한다:

- `auto_split`: PM 인터뷰는 현재 대화에서 수행하고, 이후 역할을 분리 `sub-agent`로 호출해 순차 진행.
- `single_session`: 역할 라벨링으로 동일 대화 안에서 순차 진행. 역할 전환 시 아래 형식을 사용한다:

```markdown
### **[역할명 역할]** 수행 내용 한 줄 요약
```

예: `### **[PM 역할]** 인터뷰 및 명세 작성`, `### **[Domain Expert 역할]** Gateway 1: 명세 검토`. 역할명은 PM, Domain Expert, Architect, Developer, Reviewer, Root orchestrator 중 하나다.

Root orchestrator와 Domain Expert의 `gate` 책임은 분리한다:

- Root orchestrator `stage gate`: 모든 단계 전환 전에 산출물 파일이 존재하는지, 해당 산출물이 아래 최소 검증 기준을 만족하는지, `run-state.json`을 다음 단계로 갱신할 수 있는지, 다음 역할의 `briefs/<role>.md`가 준비됐는지 확인한다. 도메인 유효성은 판단하지 않는다.
- hook 기반 quality gate는 Root orchestrator `stage gate`의 보조 검증 장치다. hook/check script는 agent가 아니며, 산출물 누락, 권한/역할 경계 위반, 구현 전 사용자 승인 누락, 가짜 성공 결과, 필수 검증 누락을 자동으로 탐지해 다음 단계 전환을 막을 수 있다.
- Domain Expert Gateway: PM 명세, Architect design, 최종 결과의 도메인 유효성을 판단하고 `Approved`, `Revise`, `Blocked`를 결정한다.

Codex 런타임 규칙:

- `auto_split`은 `$agent-team` 호출이 역할 분리 실행을 명시적으로 요청한 것으로 간주할 때만 사용한다.
- `auto_split` 시작 전에 현재 Codex 세션에 서브에이전트를 분리 실행할 수 있는 도구가 노출되어 있는지 확인한다. Codex 빌드와 설정에 따라 도구 이름과 활성화 플래그가 다를 수 있으므로, 실제로 호출 가능한 도구만 사용한다.
- 서브에이전트 실행 도구를 사용할 수 없으면 `execution_mode`를 `single_session`으로 기록하고 시작 출력에 `execution_mode` 전환 이유를 한 줄로 표시한다. 전환 이유에는 시도한 도구 이름이나 "서브에이전트 분리 실행 도구 없음" 중 하나를 적는다.
- `sub-agent`는 PM 인터뷰 이후부터 순차 호출한다. 다음 역할을 시작하려면 이전 역할의 출력 파일과 Root orchestrator 수신 검증이 끝나야 한다.

## 초기 파일 생성과 PM 인터뷰

Root orchestrator는 PM 역할을 시작하기 전에 실행 기본 정보만 `00-run-setup.md`에 작성한다. 실행 기본 정보는 `run-id`, 실행 위치, `mode`, `execution_mode`, 실행 디렉터리, 생성한 초기 파일 목록이다. 프로젝트 의미, 초기 목표, 주요 사용자, 해결하려는 일/결정, 입력 데이터, 기대 출력, 성공 기준, 기술 방향/플랫폼 제약/선호는 PM 인터뷰 책임이다.

PM은 `pm_spec` 단계에서 사용자 인터뷰와 기능 명세 작성을 수행한다. PM 인터뷰는 `sub-agent`로 실행하지 않고 현재 대화에서 직접 진행한다. PM은 한 번에 한 가지씩 질문하고, 사용자의 답변을 `00-pm-interview.md`에 누적한다.

현재 대화에 이미 PM 인터뷰에 해당하는 내용이 있어도, PM은 이를 확정 답변이 아니라 질문 맥락과 후보 답변으로만 사용한다. 사용자에게 현재 실행의 PM 인터뷰에서 한 가지씩 확인하고, 사용자가 명시적으로 “PM 인터뷰 완료”, “그걸로 명세 작성”, “넘어가자”처럼 다음 단계 진행을 승인한 뒤에만 `01-pm-spec.md`를 작성한다.

## 사용자 확인 질문 프로토콜

모든 역할은 모호하거나 모르는 내용을 임의로 확정하지 않는다. 현재 역할 산출물의 정확도, 범위, 도메인 판단, 구현 방향, 검증 결과, 다음 단계 전환에 영향을 주는 불확실성이 있으면 `question_request`를 Root orchestrator에 보고한다. 사용자에게 보여야 하는 질문은 역할이 직접 묻지 않고 PM clarification으로 라우팅한다.

`question_request` 형식:

```markdown
question_request:
- 질문 유형: requirement | model_choice | runtime_config | scope | approval | other
- 질문:
- 이유:
- 답변 없이는 위험한 결정:
- 답변 후보 또는 기본 가정:
- 영향받는 산출물:
```

질문 규칙:

- 한 번에 한 가지씩 묻는다.
- PM 인터뷰 단계의 질문은 예외적으로 현재 대화에서 PM 역할이 직접 묻는다.
- 역할은 질문을 만든다. Root orchestrator는 질문 의미를 바꾸지 않고 PM clarification으로 전달한다. PM은 현재 대화에서 사용자에게 한 가지씩 묻고, 답변을 `00-pm-interview.md`의 PM 질문과 답변에 누적한다.
- PM clarification에서 요구사항, 모델 선택 기준, 범위, 성공 기준, 구현 승인 여부가 바뀌면 PM은 `01-pm-spec.md`와 `assumptions.md`의 영향 범위를 갱신한다. 단순 runtime/config 값 확인이면 `00-pm-interview.md`와 해당 역할 산출물에 답변 근거만 남길 수 있다.
- 사용자 답변이 오기 전까지 `current_stage`와 `next_stage`는 현재 역할 단계에 유지한다.
- 사용자 답변을 받은 뒤 Root orchestrator는 같은 역할에 PM clarification 결과를 전달하고, 역할은 해당 산출물에 질문/답변 또는 결정 반영 내용을 기록한다.
- 낮은 위험의 세부사항은 열린 질문이나 가정으로 기록하고 진행할 수 있다. 단, 산출물의 핵심 결정이 바뀌거나 잘못된 구현을 만들 수 있으면 질문해야 한다.

Root orchestrator는 각 역할 단계 시작 전에 다음 역할의 `briefs/<role>.md`를 준비한다. `briefs/<role>.md`에는 사람이 읽는 작업 지시와 실행 추적용 `System Handoff`를 함께 포함한다.

- Root orchestrator가 `briefs/<role>.md`를 생성 또는 갱신해 입력만 전달하고, 역할별 산출물은 해당 출력 파일에만 작성한다.
- 상단 작업 지시 핵심 필드는 `작업 목표`, `해야 할 일`, `입력`, `출력`, `범위`, `완료 기준`이다.
- 각 brief에는 역할 정의 필드(`name`, `description`, 권한/도구 경계, 사용자 질문 방식)를 포함한다. 권한/도구 경계는 PM `interview/docs`, Domain Expert `read-only/domain-validation-only`, Architect `docs-only/design-and-plan`, Developer `code-editing-with-approved-work-plan`, Reviewer `read-only/verification-only` 중 하나를 기본으로 한다.
- 하단 `System Handoff` 핵심 필드는 `run-id`, `execution_mode`, `current_stage`, `next_stage`, `sender`, `receiver`, `run-state.json`, `gateway_stage`, `brief_snapshot`이다. `gateway_stage`는 Domain Expert Gateway가 아니면 `해당 없음`으로 기록한다. `brief_snapshot`은 Domain Expert와 Architect처럼 한 역할이 여러 번 실행되는 경우 해당 단계 스냅샷 경로를 기록하고, 그 외 역할은 `해당 없음`으로 기록한다.
- `briefs/pm.md`는 초기 파일 생성과 컨텍스트 로드가 끝나면 생성한다. PM 인터뷰 단계에서는 PM `sub-agent`를 만들지 않고 현재 대화에서 이 brief를 참조한다. PM은 `00-run-setup.md`, `00-context.md`, 기존 `00-pm-interview.md`를 바탕으로 필요한 인터뷰를 수행하고, 사용자 승인 후 `01-pm-spec.md`를 작성한다.
- Domain Expert Gateway를 시작할 때 Root orchestrator는 `briefs/domain-expert.md`를 최신 실행용으로 갱신한 뒤, 같은 내용을 Gateway별 스냅샷에도 저장한다. `expert_gateway_spec`은 `briefs/domain-expert-01-spec.md`, `expert_gateway_design`은 `briefs/domain-expert-02-design.md`, `expert_gateway_final`은 `briefs/domain-expert-03-final.md`다. 같은 Gateway를 재시도할 때는 기존 스냅샷을 덮어쓰지 말고 `briefs/domain-expert-01-spec-retry-1.md`처럼 `-retry-<n>` suffix를 붙인 새 파일로 저장한다.
- Architect 단계를 시작할 때 Root orchestrator는 `briefs/architect.md`를 최신 실행용으로 갱신한 뒤, 같은 내용을 단계별 스냅샷에도 저장한다. `architect_design`은 `briefs/architect-01-design.md`, `work_plan`은 `briefs/architect-02-work-plan.md`다. 같은 Architect 단계를 재시도할 때는 기존 스냅샷을 덮어쓰지 말고 `briefs/architect-01-design-retry-1.md`처럼 `-retry-<n>` suffix를 붙인 새 파일로 저장한다.
- 역할이 완료되면 Root orchestrator가 `stage gate`를 수행한다. 해당 출력 파일 존재와 최소 검증 항목을 먼저 확인한 뒤 `run-state.json`의 `current_stage`/`last_completed_stage`/`next_stage`를 갱신한다.
- `run-state.json`은 산출물보다 앞서가면 안 된다. Root orchestrator는 출력 파일이 실제로 존재하고 최소 검증 기준을 통과하기 전에는 `last_completed_stage`, `next_stage`, `artifacts`에 그 단계를 기록하지 않는다.
- `run-state.json`의 `last_completed_stage`나 `artifacts`가 가리키는 파일이 없으면 현재 상태를 완료로 보지 않는다. 이 경우 `stage_gate_failure`로 처리하고, `current_stage`와 `next_stage`는 누락 산출물을 작성해야 하는 단계로 되돌리거나 유지한다.
- 새 실행 또는 replay 실행의 `run-state.json`은 실제 실행 디렉터리와 같은 실행만 가리켜야 한다. `run_id`는 실행 디렉터리 basename과 일치해야 하며, `artifacts`의 모든 경로는 해당 실행 디렉터리 내부에 있어야 한다. 기준 실행(reference run) 경로는 `00-context.md`나 비교 기록에만 남기고, 현재 실행의 `artifacts` 값으로 복사하지 않는다.
- `stage gate`는 경로가 존재하는지만 보지 않는다. `artifacts`가 기준 실행, 이전 round, 원본 저장소의 다른 `docs/agent-team/<run-id>`를 가리키면 현재 실행 완료로 처리하지 않고 `stage_gate_failure`로 기록한다.
- Domain Expert Gateway의 `stage gate`에서는 출력 파일 `02/04/08-expert-gateway-*.md`뿐 아니라 해당 Gateway의 brief 스냅샷이 존재하고, 스냅샷의 `System Handoff current_stage`가 실행한 Gateway 단계와 맞는지도 확인한다.
- Architect의 `stage gate`에서는 출력 파일 `03-architect-design.md` 또는 `05-work-plan.md`뿐 아니라 해당 Architect 단계의 brief 스냅샷이 존재하고, 스냅샷의 `System Handoff current_stage`가 실행한 Architect 단계와 맞는지도 확인한다.
- `stage gate` 실패면 `stage_gate_failure` 항목을 수정/재실행 대상 역할의 `briefs/<role>.md`와 해당 단계 스냅샷에 기록한다. `stage_gate_failure`에는 누락된 산출물, 누락된 필수 섹션, 잘못된 `run-state.json` 값, 다음 시도에서 고쳐야 할 내용을 적는다.

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
- `briefs_created`: 초기 파일 생성과 컨텍스트 로드 후 초기 역할별 `briefs/<role>.md` scaffold 생성 완료. 이후 단계별 `handoff` 내용은 각 역할 시작 전에 계속 갱신한다.
- `pm_spec`
- `expert_gateway_spec`
- `architect_design`
- `expert_gateway_design`
- `work_plan`
- `implementation_approval`
- `developer_implementation`
- `reviewer_verification`
- `expert_gateway_final`
- `user_final_confirmation`
- `final_report`

`run-state.json` 상태 갱신 규칙:

- 상태 갱신은 단계 산출물 작성과 `stage gate` 검증이 끝난 뒤에만 수행한다. 역할이 산출물을 쓰는 중이거나 실패한 상태에서 다음 단계 값을 미리 기록하지 않는다.
- 단계 시작 시 `current_stage`를 지금 실행하는 단계 값으로 갱신한다. 예: PM 명세를 작성하기 시작하면 `current_stage`는 `pm_spec`이다.
- 단계가 `stage gate`를 통과하면 `last_completed_stage`를 방금 끝난 단계로 갱신하고, `next_stage`를 다음 실행 단계로 갱신한다. 생성 또는 갱신된 파일은 실제 경로가 존재할 때만 `artifacts`에 기록하고 `updated_at`을 현재 시각으로 갱신한다.
- `artifacts`에 기록하는 경로는 현재 실행 디렉터리 내부의 절대 경로다. 기준 실행을 참고한 경우에도 기준 실행 산출물 경로를 현재 실행의 산출물로 기록하지 않는다.
- `stage gate` 실패면 `last_completed_stage`와 `artifacts`를 실패 단계로 갱신하지 않는다. 이미 잘못 기록된 값이 발견되면 해당 불일치를 사용자에게 숨기지 말고, 실패 항목에 `run-state.json` 불일치와 누락 파일 경로를 남긴 뒤 누락 산출물 작성 단계로 되돌린다.
- `context_load`가 끝나면 `next_stage`를 `briefs_created`로 설정한다.
- 실행 위치나 `mode`처럼 초기 파일 생성에 필요한 값이 없으면 `current_stage=initialized`, `next_stage=initialized`를 유지하고 사용자에게 한 번에 한 가지씩 묻는다.
- 초기 파일 생성과 `context_load`가 끝나면 `briefs/pm.md`를 생성하고 `next_stage=pm_spec`으로 설정한다.
- `briefs_created`가 끝나면 `next_stage`를 `pm_spec`으로 설정한다.
- `pm_spec`에서 PM 인터뷰 질문이 필요하면 `current_stage=pm_spec`, `next_stage=pm_spec`를 유지하고 현재 대화에서 PM 역할로 사용자에게 직접 질문한다.
- 모든 역할 단계에서 `question_request`가 발생하면 `current_stage`와 `next_stage`를 현재 단계로 유지하고 PM clarification으로 사용자 답변을 받은 뒤 같은 역할에 전달한다.
- PM이 `00-pm-interview.md`와 `01-pm-spec.md`를 작성하고 `stage gate`가 통과하면 `last_completed_stage=pm_spec`, `next_stage=expert_gateway_spec`으로 설정한다.
- 명세 Domain Expert Gateway가 `Approved`면 `last_decision`에 결정을 기록하고 `next_stage`를 `architect_design`으로 설정한다.
- 명세 Domain Expert Gateway가 `Revise`면 `gateway_retry_count.spec`을 1 증가시키고 `next_stage`를 `pm_spec`으로 되돌린다.
- 설계 Domain Expert Gateway가 `Approved`면 `last_decision`에 결정을 기록하고 `next_stage`를 `work_plan`으로 설정한다.
- 설계 Domain Expert Gateway가 `Revise`면 `gateway_retry_count.design`을 1 증가시키고 `next_stage`를 `architect_design`으로 되돌린다.
- `work_plan`이 `stage gate`를 통과하면 `last_completed_stage=work_plan`, `next_stage=implementation_approval`으로 설정한다.
- `implementation_approval`에서는 PM이 현재 대화에서 사용자에게 `05-work-plan.md` 기준으로 코드 구현을 시작해도 되는지 한 가지 질문으로 확인한다. 승인 답변은 `00-pm-interview.md`에 기록하고, 승인되면 `last_completed_stage=implementation_approval`, `next_stage=developer_implementation`으로 설정한다. 승인되지 않으면 `status=blocked`로 두고 `blocked_reason`에 수정 요청 요약과 되돌아갈 후보 단계(`pm_spec`, `architect_design`, `work_plan`)를 기록한다.
- 최종 Domain Expert Gateway가 `Revise`면 `gateway_retry_count.final`을 1 증가시킨다. 구현 결과나 Reviewer 검증 결과가 승인된 명세/설계와 다르다는 문제면 `next_stage`를 `developer_implementation`으로 되돌리고, 이후 `reviewer_verification`과 `expert_gateway_final`을 다시 거친다. 도메인 입력 누락, 명세 전제 오류, 설계 전제 오류처럼 현재 역할이 산출물만 고쳐서는 판단할 수 없는 문제면 `status`를 `blocked`로 두고 `blocked_reason`에 필요한 사용자 입력을 기록한다.
- Domain Expert Gateway가 `Blocked`면 `status`를 `blocked`로 두고 `blocked_reason`에 필요한 사용자 입력이나 판단을 한 문장으로 기록한다.
- 최종 Domain Expert Gateway가 `Approved`면 `last_decision`에 결정을 기록하고 `next_stage`를 `user_final_confirmation`으로 설정한다.
- Reviewer가 Developer 수정이 필요한 이슈를 발견하면 `review_retry_count`를 1 증가시키고 `next_stage`를 `developer_implementation`으로 되돌린다. Developer 수정 후에는 `reviewer_verification`을 다시 실행한다.
- 사용자가 `user_final_confirmation`에서 최종 승인하면 `next_stage`를 `final_report`로 설정한다.
- 사용자가 최종 수정 요청을 하면 `status`를 `blocked`로 두고 수정 요청 요약과 되돌아갈 후보 단계를 `blocked_reason`에 기록한다.
- Root orchestrator가 `09-final-report.md`를 작성하면 `current_stage=final_report`, `last_completed_stage=final_report`, `next_stage=null`, `status=completed`로 갱신한다. 이 상태에서는 추가 단계로 진행하지 않고, 사용자가 새 실행을 요청하면 새 `run-id`로 다시 시작한다.
- Root orchestrator는 `09-final-report.md`의 최종 보고 stage gate와 `run-state.json` 경로 일관성 검사를 통과하기 전에는 `status=completed`로 갱신하지 않는다.

재시도 한도:

- 각 Domain Expert Gateway의 `Revise` 반복은 최대 2회다.
- Developer fix -> Reviewer re-verification 반복은 최대 2회다.
- 한도를 초과하면 `status`를 `blocked`로 두고 `blocked_reason`에 초과한 한도, 마지막 실패 이유, 사용자가 선택해야 할 다음 행동을 기록한 뒤 사용자에게 묻는다.

## 기존 실행 재개와 `run-state.json` 상태 재구성

사용자가 기존 실행을 이어가거나 실행 디렉터리를 지정하면 `run-state.json`을 먼저 읽는다.

재개 규칙:

- `status`가 `active`면 `next_stage`부터 이어간다.
- `status`가 `blocked`면 `blocked_reason`을 보여주고, 사용자의 새 입력이 `blocked_reason`을 해소하는지 확인한 뒤 이어간다.
- `status`가 `completed`면 새 실행을 만들지, 기존 결과를 검토/재구성할지 묻는다.
- 기존 산출물은 임의로 덮어쓰지 않는다. 사용자가 재작성 요청을 했거나 Domain Expert Gateway `Revise`가 해당 산출물 수정을 요구한 경우에만 갱신한다.

재구성 규칙:

- 재구성은 산출물을 다시 작성하거나 역할을 다시 실행하는 작업이 아니다. 현재 실행 디렉터리의 파일과 `run-state.json`을 읽어 어떤 단계까지 끝났는지 판단하는 작업이다.
- 재구성할 때는 산출물 존재 여부, 각 산출물의 결정값, `last_completed_stage`, `next_stage`, `artifacts` 목록이 서로 맞는지 비교한다.
- `last_completed_stage`가 어떤 단계를 완료했다고 주장하지만 해당 단계의 필수 출력 파일이 없으면 `run-state.json`을 신뢰하지 않는다. 파일 부재가 더 강한 증거이며, 재구성 결과는 누락 산출물과 되돌아갈 단계 값을 제안해야 한다.
- 재구성 결과가 `run-state.json`과 맞지 않으면 `run-state.json`을 바로 고치지 않는다. 불일치한 필드, 파일 근거, 제안하는 수정값을 사용자에게 보고한다.
- 재구성 중 누락 산출물이 발견되면 `status`를 `blocked`로 바꾸기 전에 해당 산출물이 현재 `next_stage`를 실행하는 데 실제로 필요한지 확인한다.

## `stage gate` 산출물 최소 검증 기준

각 산출물은 다음 최소 요건을 만족해야 다음 단계의 입력으로 사용할 수 있다.

실행 기본 정보 `00-run-setup.md`:

- `run-id`
- 실행 위치와 `mode`
- 실행 디렉터리
- `execution_mode`
- 생성한 초기 파일 목록
- 프로젝트 의미/목표/요구사항은 PM 인터뷰에서 다룬다는 명시

PM 명세 `01-pm-spec.md`:

- PM 인터뷰 요약 또는 `00-pm-interview.md` 참조
- `00-pm-interview.md`에 PM 인터뷰 진행 체크리스트가 있고, 사용자와 업무 목적, 입력 데이터와 데이터 소스 역할, AI 기능과 평가 기준, 모델 선택 기준, 포함/제외 범위, 운영 데이터 기반 지속 개선, 기술 방향과 runtime/config, 명세 작성 전 승인 영역이 `확인` 또는 `해당 없음`으로 정리되어 있음
- PM 질문과 답변이 한 번에 한 가지씩 기록되어 있고, 이전 문서와 다른 요구를 나중에 바꾼 것처럼 쓰지 않고 현재 실행의 확정 요구로 기록함
- 사용자가 기준 실행 경로를 제공했다면 기준 실행 대비 PM 자체점검 기록. 기준 실행에서 보존할 구조·의미·표현 기준은 품질 기준으로만 쓰고, 현재 사용자 확인 없이 기준 실행의 요구사항을 확정 요구사항으로 복사하지 않았는지 명시한다.
- 상세 사용자 시나리오
  - 주요 사용자 또는 사용자 유형
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
  - 데이터 소스별 역할
  - schema/profile 기준 확인 역할 데이터의 모델 흐름 직접 연결 여부
  - 각 데이터 소스의 파일 경로, 파일 형식, 데이터 성격, 허용 사용, 금지 사용
  - 원천 데이터와 파생 feature/지표를 사용자가 구분한 경우 원천 행 단위, 파생 행 단위, 모델 입력/라벨/평가 연결 방식
- AI 기능 고려사항 또는 해당 없음 명시
  - 기술 방향/플랫폼 제약의 `required`, `preferred`, `candidate` 구분
  - AI/ML 모델이 필요한 기능이면 PM이 모델명을 직접 고르지 않고 모델 선택 기준을 확인했는지. 최소 기준은 모델 과제 유형(예: 시계열 예측, tabular classification, LLM text classification), 필수 플랫폼/모델 계열, 정확도/속도/비용 우선순위, 로컬 실행 또는 외부 API 허용 여부, 설명가능성 필요 여부다.
  - 사용자가 특정 모델 과제 유형과 `required` 플랫폼을 함께 요구한 경우, 해당 플랫폼이 그 과제 유형을 직접 지원해야 하는지 또는 별도 모델을 쓰고 `required` 플랫폼은 데이터 생성/오케스트레이션/평가/검수에만 쓸지 PM이 사용자에게 확인했는지.
  - 예측 출력이 상태값과 KPI 요약을 모두 포함하거나 사용자가 시계열 예측을 언급한 경우, PM이 모델 실행 순서를 확인했는지. 최소 선택지는 미래 KPI 예측 후 상태 분류, 상태 직접 분류, 둘 다 비교다.
  - 추론이 NIM, vLLM, OpenAI-compatible server처럼 structured JSON 응답에 의존하면 PM이 inference runtime과 response schema 책임을 확인했는지. 최소 선택지는 NVIDIA-hosted NIM, 로컬 vLLM OpenAI-compatible endpoint, PoC deterministic adapter + 후속 NIM/vLLM 검증이다.
  - AI 예측/추천/분류 기능이면 운영 데이터 기반 지속 개선 루프 실행 시점과 워크플로우 경계. PoC라면 지속개선을 실제 운영으로 돌릴지, 코드 경계/예측 결과 저장 형식과 필드 목록/PoC 데모용 결과 후보 또는 VOC 샘플 연결/데모 재평가와 개선 리포트/승인 기반 재학습 후보 실험 경계까지 구현할지 사용자에게 한 가지 질문으로 확인했는지 점검한다.
  - 현재 구현 범위이면 운영 기록, 라벨 또는 실제 결과, 사람 승인, 저장 데이터, 재평가/개선 후보 트리거
  - 별도 후속 워크플로우이면 현재 구현 범위의 제외 항목과 후속 워크플로우가 읽을 예측 결과 저장 형식/필드 목록 후보
  - required 외부 플랫폼이나 microservices 묶음이 있으면 PM 명세가 필수 기술 여부, 실제 runtime 연결 검증 필요 여부, 기존 설정/배포 문서 확인 여부, secret을 env var로만 다루는 원칙, endpoint/base URL을 배포 결과나 기존 설정에서 산출한다는 원칙을 포함함
  - `NeMo Microservices actual runtime`이 required이면 PM 명세가 local artifact 성공과 NeMo service smoke 성공을 분리하고, Data Store/Entity Store/Evaluator 또는 공식 문서로 식별한 동등 필수 서비스의 health/API smoke artifact를 PoC 수용 기준에 포함함. 단순 adapter/fallback/config template만으로 성공 처리하지 않는다고 명시함
  - `NeMo Microservices actual runtime`이 required이고 합성 데이터 생성이 범위에 있으면 PM 명세가 `NeMo Data Designer primary`를 기본 경로로 기록하고, local generator는 Data Designer job/config/status/result reference를 대체하지 못하는 보조 경로라고 명시함
  - `NeMo Microservices actual runtime`이 required이고 평가가 범위에 있으면 PM 명세가 `NeMo Evaluator primary`를 기본 평가 runtime으로 기록하고, local metric은 Evaluator custom evaluation/custom metric 불가 시의 보조 artifact이며 Evaluator job/result reference를 대체하지 못한다고 명시함
- 열린 질문
- 가정 ID 참조
- 추상 용어 구체화: “입력”, “피드백”, “루프”, “계약”, “후속”, “사용” 같은 표현은 실제 저장 데이터/필드, 산출물, 소비 단계, 금지 용도를 함께 설명해야 한다.

Domain Expert Gateway 산출물 `02/04/08-expert-gateway-*.md`:

- `결정: Approved | Revise | Blocked` (최상단에 명시)
- 승인 근거 항목 최소 3개 이상: 도메인 용어/지표/데이터 역할/업무 제약/가정 추적 중 확인된 항목을 구체적으로 서술한다. "문제 없음"처럼 한 줄 요약만으로는 stage gate를 통과시키지 않는다.
- 검토한 가정 (해당 ID 참조)
- 도메인 리스크 (없으면 "없음"으로 명시)
- 필수 수정사항 (`Revise`/`Blocked` 시 구체적으로 서술, `Approved` 시 다음 단계 주의사항)
- 해당 Gateway의 brief 스냅샷 존재:
  - `expert_gateway_spec`: `briefs/domain-expert-01-spec.md` 또는 retry snapshot
  - `expert_gateway_design`: `briefs/domain-expert-02-design.md` 또는 retry snapshot
  - `expert_gateway_final`: `briefs/domain-expert-03-final.md` 또는 retry snapshot
- brief 스냅샷의 `System Handoff current_stage`가 해당 Gateway 단계와 일치

아키텍처 설계 `03-architect-design.md`:

- 해당 Architect brief 스냅샷 존재:
  - `architect_design`: `briefs/architect-01-design.md` 또는 retry snapshot
- brief 스냅샷의 `System Handoff current_stage`가 `architect_design`과 일치
- 구조 다이어그램
  - Mermaid 데이터 흐름도
  - Mermaid 실행 모드 또는 제어 흐름도
  - Mermaid 블록은 Markdown 렌더러 호환성을 위해 세 개 백틱 code fence와 `mermaid` info string으로 작성해야 한다. `~~~mermaid` tilde fence는 stage gate를 통과시키지 않는다.
  - 운영 데이터 기반 지속 개선 루프가 실서비스 운영 단계 또는 별도 후속 워크플로우이면 Mermaid 실서비스 지속개선 워크플로우 다이어그램
- 사용자가 기준 실행 경로를 제공했다면 기준 실행의 설계 산출물과 구조·의미·표현 차이를 자체 점검한 기록. 단, 기준 실행 내용을 현재 요구사항으로 무단 복사하지 않고 현재 PM 명세와 충돌하는 부분은 현재 PM 명세를 우선한다.
- PM 명세의 데이터 소스 역할 반영
- PM 명세의 원천 데이터와 파생 feature/지표 경계 반영
- 컴포넌트와 책임
- 데이터/모델/제어 흐름
- 기술 스택 후보와 결정 또는 기존 스택 유지 사유
- AI/ML 모델이 필요한 기능이면 모델 후보 비교와 선택 근거. PM 모델 선택 기준을 반영하고, 선택 모델 또는 모델 계열, 사용 위치, 제외 후보와 제외 이유, 추가 사용자 확인이 필요한 조건을 포함해야 한다.
- 모델 과제 유형과 required 플랫폼 지원 여부
  - 과제 유형: 시계열 예측, tabular classification, LLM text classification, anomaly detection 등
  - required 플랫폼이 해당 과제 유형을 공식적으로 지원하는 단계: 학습, 추론, 평가, 오케스트레이션, 데이터 생성, 검수 중 무엇인지
  - 공식 문서 또는 프로젝트 문서 근거
  - 지원 근거가 없거나 범위가 맞지 않으면 `question_request`로 사용자 확인을 요청했는지
  - 별도 모델을 쓰는 경우 required 플랫폼이 맡는 보조 역할과 모델 학습/추론 주체를 구분했는지
- 모델 실행 순서
  - 미래 KPI 예측 후 상태 분류인지, 상태 직접 분류인지
  - 미래 KPI target schema와 forecast artifact
  - 상태 라벨 rule과 위험 점수 계산 기준
  - 미래 target이 입력 feature에 섞이지 않는 leakage guard
- structured inference runtime과 response schema
  - NVIDIA-hosted NIM, 로컬 vLLM OpenAI-compatible endpoint, PoC deterministic adapter 중 선택한 실행 방식
  - base URL, model/deployment name, `/chat/completions` path
  - 필수 JSON key와 실패 시 artifact 정책
  - schema smoke test를 Developer/Reviewer 작업에 포함했는지
- PM 명세의 `required` 기술/플랫폼 제약 반영 방식
- `required` 외부 플랫폼의 실제 runtime 연결 검증이 범위에 있으면 구현 전 runtime/config checklist
  - 서비스/모듈별 endpoint 또는 base URL
  - 인증 방식 또는 env var
  - workspace/project/tenant
  - workflow 파일 또는 실행 방식
  - model/dataset/job/artifact reference
  - API version/path 또는 SDK 버전
  - 권한과 smoke check
  - 값 미제공 시 config schema, service adapter, 실패 artifact, 실제 runtime 연동 residual risk
  - 사용자 확인이 필요한 값은 `question_request`로 Root orchestrator에 보고했는지
  - Root orchestrator가 기존 설정 파일/배포 문서/운영 담당자 제공 값이 있는지 먼저 묻고, 없으면 로컬 Docker Compose 구성을 진행할지 한 가지 질문으로 확인하도록 질문 순서를 제시했는지
  - endpoint/base URL은 사용자가 손으로 채우는 값이 아니라 기존 배포 환경 또는 Docker Compose 배포 결과에서 산출하는 값으로 표시했는지
  - secret 값은 `.env` 또는 shell env에 넣도록 안내하고, 문서에는 env var 이름만 기록하도록 명시했는지
- `required` 기술이 여러 서비스/모듈로 구성된 플랫폼이면 서비스/모듈별 매핑 표
  - 서비스/모듈명
  - 담당 단계
  - 사용 목적
  - 입력/출력 또는 artifact
  - 필요한 설정/권한
  - 검증 방법
  - 제외/보류 사유
  - 서비스/모듈명은 공식 문서나 프로젝트 문서에서 확인한 이름이어야 한다. 일반 기능명(`training`, `evaluation`, `inference`, `generation`)에 플랫폼명을 붙인 라벨만 있으면 stage gate를 통과시키지 않는다.
- 평가 방식
- 운영 데이터 기반 지속 개선 루프 설계, 별도 후속 워크플로우 또는 실서비스 운영 단계 경계와 워크플로우 다이어그램, 또는 제외 사유
- 운영 데이터 기반 지속 개선 루프와 사람 피드백이 있으면 저장 artifact/필드, 연결 key, 재평가 사용 방식, 자동 변경/자동 조치 금지 경계
- 실패 모드
- 추가/변경한 가정 ID

Task Plan `05-work-plan.md`:

- 해당 Architect brief 스냅샷 존재:
  - `work_plan`: `briefs/architect-02-work-plan.md` 또는 retry snapshot
- brief 스냅샷의 `System Handoff current_stage`가 `work_plan`과 일치
- 사용자가 기준 실행 경로를 제공했다면 기준 실행의 Work Plan과 비교해 누락된 필수 작업 유형이 있는지 점검한 기록. 비교 기준은 작업 수가 아니라 원천/파생 데이터 경계, required 기술 연동, mode별 artifact, 실패 artifact, 검증 명령의 보존 여부다.
- 각 작업의 목적
- 입력
- 출력
- 의존성
- 검증 방법
- 예상 변경 파일/영역
- 원천 데이터와 파생 feature/지표가 분리된 계획이면 원천 생성/검증 작업과 파생 feature/지표 생성/검증 작업
- PM 명세의 `required` 기술이 있으면 환경/config 검증 작업과 해당 기술 연동 검증 방법
- `required` 외부 플랫폼이 있으면 Architect가 만든 runtime/config checklist를 입력으로 받는 작업
  - 값을 제공받을 수 있으면 실제 runtime smoke/e2e 검증 작업을 포함한다.
  - 값을 제공받을 수 없으면 실제 runtime 연동 성공을 PoC 수용 기준에서 제외하고, config schema, service adapter, 실패 artifact, 미검증 residual risk를 구현하는 작업을 포함한다.
- `required` 기술이 여러 서비스/모듈로 구성된 플랫폼이면 서비스/모듈별 구현 작업과 검증 방법
  - Task Plan은 공식 서비스/모듈별 작업을 나눠야 한다. 일반 기능명만 적힌 작업은 Developer에게 넘기기 전에 Architect 단계로 되돌린다.
  - NeMo actual runtime이 required이면 Data Designer 기반 데이터 생성과 Evaluator 기반 평가를 primary 작업으로 나눠야 한다. local generator/local metric만 있고 Data Designer/Evaluator job/result reference 작업이 없으면 Developer에게 넘기기 전에 Architect 단계로 되돌린다.
- 사용자 실행 mode가 여러 개면 mode별 목적, 입력, 출력 artifact, 필요한 config/env, 성공 기준, 실패 artifact, 검증 명령
- 모델명과 runtime 실행값을 바꿔야 하는 프로젝트이면 config override 작업. 최소 검증 항목은 model/deployment name, endpoint/base URL, port, max tokens, temperature, seed, 필요한 dataset/config/model reference가 config 또는 env override로 실제 payload/wrapper에 반영되는지다.
- 운영 데이터 기반 지속 개선 루프가 현재 구현 범위인 경우 예측·운영 기록 수집, 정답·결과 후보 저장, 오프라인 평가, 개선 후보 트리거, 사람 승인 경계 작업. PoC에서 지속개선을 구현만 하는 경우 PoC 데모용 결과 후보/VOC 샘플 연결, 데모 재평가/개선 리포트, 승인 기반 후보 실험 경계 검증 작업과 실서비스 개선 방식 설명. 별도 후속 워크플로우인 경우 현재 범위의 예측 결과 저장 형식/로그 저장 작업
- 예상 변경 영역
- Developer가 구현할 때 사용할 debugger 보조 관점이 필요하면 해당 조건을 명시. 예: 테스트 실패 재현, root cause 정리, 최소 수정, 재검증 명령. Debugger는 별도 기본 역할이 아니라 Developer fix 반복 안의 분석 방식이다.

구현 전 사용자 승인 `implementation_approval`:

- `05-work-plan.md`가 `stage gate`를 통과한 뒤에만 수행
- PM이 현재 대화에서 사용자에게 코드 구현 시작 승인 여부를 한 가지 질문으로 확인
- `00-pm-interview.md`에 승인 질문, 사용자 답변, 승인한 work plan 경로가 기록됨
- 승인 전에는 `developer_implementation`으로 넘어가지 않음
- 사용자가 수정 요청을 하면 `status=blocked` 또는 적절한 이전 단계로 되돌릴 후보가 기록됨

Developer implementation `06-developer-implementation.md`:

- 구현 상태
- 구현한 내용
- 변경 파일
  - 코드, 테스트, 문서, 설정을 구분해 실제 파일 경로를 나열한다. 모듈 설명이나 “src 전체” 같은 요약만으로는 stage gate를 통과시키지 않는다.
- 실행한 명령
- 계획 대비 변경
- Work Plan task 추적표
  - 각 `05-work-plan.md` task가 변경 파일, 실행 명령, 생성 artifact, 실패 artifact 또는 미검증 항목 중 최소 하나와 연결되어야 한다.
  - 연결되지 않은 task가 있으면 구현 완료가 아니라 계획 대비 미구현/미검증 항목으로 적는다.
- 구현 전 사용자 승인 기록이 `00-pm-interview.md`에 있어야 한다. 승인 없는 코드 변경은 stage gate를 통과시키지 않는다.
- PM/Architect가 `required`로 확정한 기술/플랫폼 제약 구현 결과
  - 서비스/모듈별 config validation
  - 서비스/모듈별 runtime adapter 또는 adapter 주입 경계
  - adapter 입출력 형식 테스트 또는 실제 runtime 검증 결과
  - 설정 누락/런타임 실패 시 성공 산출물 생성 금지와 실패 artifact
- 사용자 실행 mode별 구현 결과
  - 정상 실행 가능한 mode는 성공 artifact와 metadata를 만든다.
  - endpoint나 인증이 없어 실행할 수 없는 mode는 성공 artifact를 만들지 않고 실패 artifact를 만든다.
  - 항상 실패하는 stub mode는 stage gate를 통과하지 못한다.
- config override 구현 결과
  - config key와 env override 목록
  - override 값이 runtime adapter payload, CLI wrapper, 생성 artifact 중 어디에 반영되는지
  - secret 값을 config나 문서에 직접 저장하지 않았는지
- 원천 데이터와 파생 feature/지표가 분리된 경우 그 생성 순서와 artifact 경계를 보존한 구현 결과
- 운영 데이터 기반 지속 개선 루프가 포함된 경우 구현한 예측·운영 기록 수집, 정답·결과 후보 저장, 오프라인 평가, 개선 후보 트리거, 사람 승인 경계
- 생성 artifact와 실패 artifact
  - 성공 artifact는 경로와 핵심 필드를 기록한다.
  - runtime/config 부재나 외부 서비스 실패는 실패 artifact 경로와 reason을 기록하고, 성공 artifact를 만들지 않았음을 기록한다.
- 주요 테스트 커버리지
  - 새로 추가하거나 의미 있게 확인한 테스트가 어떤 요구사항/설계 결정/Work Plan task를 덮는지 기록한다.
- 사용자가 기준 실행 경로를 제공했다면 기준 실행 대비 Developer 자체점검 기록. 비교 기준은 문서 길이가 아니라 task 추적성, 변경 파일/명령/artifact 보존, 실패를 성공으로 위장하지 않는 경계, 미검증 항목의 노출 여부다.
- 해결/추가한 가정 ID

Reviewer verification `07-reviewer-verification.md`:

- Decision
- 실행한 검증
- Findings
- 발견 이슈를 심각도로 분류
- 명세/설계 준수 여부
- 필요한 경우 reviewer 세분화 관점별 findings. 기본 관점은 제품/명세 준수, 보안/비밀정보, 성능/운영 리스크, 테스트/평가 충분성, 필수 플랫폼 연동 검증이다.
- Developer implementation의 변경 파일 목록, 실행 명령, 실패 artifact, 미검증 항목이 실제 구현 상태와 맞는지 확인한 결과
- PM/Architect가 `required`로 확정한 기술/플랫폼 제약 검증 결과
  - 모델 과제 유형과 required 플랫폼 지원 근거가 구현에서 보존됐는지. 예: 시계열 예측 요구를 LLM 분류로 조용히 바꾸지 않았는지, required 플랫폼이 직접 지원하지 않는 과제를 native 지원처럼 표현하지 않았는지
  - PM/Architect가 미래 KPI 예측 후 상태 분류를 확정했다면 구현과 테스트가 먼저 예측 KPI summary를 만들고, 그 summary로 상태 라벨/위험 점수를 계산하는지. 상태 라벨만 직접 반환하는 adapter로 단순화했거나 미래 KPI target이 feature에 섞였으면 통과시키지 않는다
  - NIM/vLLM/OpenAI-compatible 추론을 선택했다면 Reviewer가 실제 endpoint schema smoke를 실행했는지. 미래 KPI 예측 후 분류 흐름이면 `predicted_quality_summary`가 응답에 있어야 하며, schema 불일치 시 성공으로 처리하지 않는다
  - 서비스/모듈별 config validation 검증
  - 사용자 실행 mode별 검증 결과. `run-e2e`만 보지 말고 PM/Architect가 설계한 `predict`, `ingest-outcomes`, `improve`, `run-retraining-experiment` 같은 mode의 성공 또는 의도된 실패 artifact를 확인한다
  - config override 검증 결과. 모델명, endpoint/base URL, vLLM model/image/port/max model length, max tokens, temperature, seed, Customizer dataset/config/output model reference가 설정 또는 env에서 실제 실행값에 반영되는지 확인한다
  - runtime adapter 또는 adapter 주입 end-to-end 검증
  - 설정 누락/런타임 실패 artifact 검증
  - 실제 runtime 미검증 항목과 남은 리스크
- 실제 실행 검증
  - Reviewer가 로컬에서 실행 가능한 명령을 직접 실행했는지
  - 명령별 `cwd`, `command`, `result 또는 exit code`, `확인한 artifact`, `핵심 값`, `판단 영향`을 기록했는지
  - CLI help 또는 사용 가능한 command 목록
  - `run-e2e` 성공 환경이면 `metrics.json`, `prediction_records.jsonl`, `run_metadata.json` 존재와 핵심 지표 확인 명령
  - `run-e2e` 실패 환경이면 `run_failure.json` 존재, 실패 reason, 성공 artifact 미생성 확인
  - `predict` 성공 환경이면 `prediction_result.json`과 `run_metadata.json`을 확인하고, 정답 라벨이 없는 단건 추론에 truth label을 꾸며 넣지 않았는지 확인
  - 운영 개선 mode가 구현 범위이면 `operational_records.jsonl`, `operational_metrics.json`, `improvement_report.json`, `candidate_model_reference.json`을 확인
- 운영 데이터 기반 지속 개선 루프 검증 결과
- Work Plan 대비 확인
  - 각 Work Plan task가 구현 기록과 실제 파일/명령/artifact로 추적되는지 확인한다.
  - 추적되지 않는 task는 Developer 재작업 또는 residual risk로 분류한다.
- 사용자 실행 방법과 지표 확인 검증
  - 설치/실행 전제
  - CLI help 또는 API help 확인 명령
  - mode별 실행 명령
  - 성공 artifact와 지표 확인 명령
  - 실패 artifact와 reason 확인 명령
  - 미검증 runtime/config를 성공으로 해석하지 않는 기준
- 사용자가 기준 실행 경로를 제공했다면 기준 실행 대비 Reviewer 자체점검 기록. 비교 기준은 명령별 증거, 사용자 실행 방법, 성공/실패 artifact, required 플랫폼/모델 적합성, 모델 실행 순서, 미검증 리스크 보존 여부다.
- 남은 차이
- 열린 가정
- 검증하지 못한 항목이 있으면 이유

Final report `09-final-report.md`:

- 작성자: Root orchestrator
- 최종 결과 요약: 만들었거나 명세화한 내용
- 주요 산출물 경로
- 테스트/평가 결과
- 사용자 실행 가이드
  - 설치 또는 실행 전제
  - CLI help 확인 명령
  - `profile-schema` 실행 예시
  - `run-e2e` 실행 예시
  - `run-e2e` 성공 시 생성되는 artifact와 경로: `metrics.json`, `prediction_records.jsonl`, `run_metadata.json`
  - `predict`, `ingest-outcomes`, `improve`, `run-retraining-experiment`가 구현 범위이면 실행 예시와 각 mode의 성공/실패 artifact 경로
  - 모델명, endpoint/base URL, vLLM model/image/port/max model length, max tokens, temperature, seed, dataset/config/model reference를 config 또는 env로 바꾸는 방법
  - 성능지표를 바로 출력하는 명령. 예: `python -m json.tool <output-dir>/metrics.json`, 또는 `python - <<'PY' ...`
  - 실패 시 확인할 artifact와 reason 확인 명령: `run_failure.json`
  - 실제 runtime/config가 없을 때 성공으로 해석하지 말아야 할 항목
- 모델 과제 유형과 required 플랫폼 적합성 결과 및 남은 리스크
- 모델 실행 순서와 runtime/schema 결과
  - 미래 KPI 예측 후 상태 분류라면 예측 KPI summary artifact, 상태 라벨 rule, leakage guard, 성능지표 확인법을 포함한다.
  - NIM/vLLM/OpenAI-compatible runtime을 썼다면 base URL 출처, served model/deployment name, `/chat/completions` path, 필수 JSON key, schema smoke 결과, 실패 시 성공으로 해석하지 않는 기준을 포함한다.
- 실제 runtime/config 성공과 실패 해석
  - 성공한 runtime 경로와 생성 artifact
  - 실패한 runtime 경로와 실패 artifact
  - 미검증 runtime/config와 residual risk
- 운영 데이터 기반 지속 개선 루프 구현/검증 결과
- 남은 차이 또는 열린 가정
- 최종 Domain Expert 결정
- `user_final_confirmation` 결과 또는 수정 요청 내용
- 사용자가 기준 실행 경로를 제공했다면 기준 실행 대비 자체점검
  - 파일 목록/필수 산출물 구조가 같은지
  - 최종 보고의 사용자 실행 가이드, 모델 적합성, 모델 실행 순서, 실패 artifact 해석이 기준 실행 수준으로 남았는지
  - 차이가 있으면 현재 PM 명세 차이 때문인지, 산출물 품질 누락인지 구분한다
- `run-state.json` 일관성
  - `run_id`와 실행 디렉터리 basename 일치
  - `status=completed`, `current_stage=final_report`, `last_completed_stage=final_report`, `next_stage=null`
  - `artifacts`의 모든 경로가 현재 실행 디렉터리 내부에 있고 실제 존재

검증 기준 실패 처리:

- `stage gate`에서 다음 `next_stage`로 넘기기 전에 누락 항목을 확인한다.
- 누락이 제목, 필수 섹션, 경로 기록 같은 산출물 형식 문제면 작성 역할이 같은 단계에서 보완한다.
- 누락이 포함 범위, 도메인 주장, 데이터 가용성, 사용자 의사결정 문제면 Root orchestrator가 Domain Expert Gateway 또는 사용자 입력으로 되돌린다.
- `stage gate` 검증 기준 통과는 도메인 승인이나 코드 품질 승인이 아니다.
- `09-final-report.md`는 짧은 요약만으로 통과하지 않는다. 위 필수 섹션 중 하나라도 없거나, Reviewer가 확인한 실행 명령/성공 artifact/실패 artifact/미검증 항목을 사용자 실행 가이드와 residual risk에 반영하지 않았으면 `final_report` stage gate 실패로 처리한다.
- 최종 보고에 필요한 실행 명령이나 artifact 근거가 `07-reviewer-verification.md`에 없으면 Root orchestrator가 추측해 쓰지 않는다. `reviewer_verification` 단계로 되돌려 사용자 실행 방법과 지표 확인 검증을 보완하게 한다.

반복성 검토:

- 산출물 표현, 다이어그램, 범위 경계, 데이터 역할, 기술 제약에서 재현성 문제가 발견되면 현재 문서와 관련 역할 프롬프트, 검증 기준을 함께 보완한다.
- 보완 후 같은 형태의 문제가 다시 나오는지 3가지 관점으로 검토한다.
  - 구조 검토: 필수 파일, 제목, 섹션, 표, Mermaid 다이어그램, Task Plan 작업 단위가 템플릿과 맞는가.
  - 의미 검토: PM 답변, 데이터 소스 역할, `required/preferred/candidate`, PoC와 실서비스 경계, 사람 승인/자동화 금지, 가정 ID가 서로 모순되지 않는가.
  - 표현 검토: 도메인 사용자가 읽기 어려운 영어 라벨, 모호한 축약어, “입력/피드백/루프/계약” 같은 추상어, “가짜 성공 결과”를 숨기는 표현이 남아 있지 않은가. 평가/검증/사용자 대상 설명에 쓰는 영어 용어는 한국어 의미를 먼저 쓰는가. “현재 저장소 상태”처럼 시간이 지나면 틀려질 문장은 작성 시점을 붙였는가.
- 세 검토 중 하나라도 흔들리면 산출물을 통과시키지 말고 역할 프롬프트 또는 검증 기준을 더 구체화한 뒤 다시 검토한다.
- 이 검토는 특정 도메인 예시에 고정하지 않는다. 통신, 금융, 제조, SaaS 등에서도 데이터 역할, 기술 제약, 운영/PoC 경계, 사람이 남기는 판단 기록을 같은 형식으로 분리해 적용한다.
