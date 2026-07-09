# 에이전트 팀 실행 규칙

이 문서는 `$agent-team`의 재개, 상태 전환, stage gate, content integrity, 반복 한도, 산출물 최소 검증 기준을 정의한다.

## 역할 실행 구조

- Root orchestrator는 실행 디렉터리, 초기 파일, `run-state.json`, stage gate, 역할 brief, 상태 전환을 관리한다.
- PM은 현재 대화에서만 실행한다. PM 인터뷰를 sub-agent로 보내지 않는다.
- Domain Expert, Architect, Developer, Reviewer는 `auto_split`이면 sub-agent로 순차 실행하고, 도구가 없으면 `single_session` 역할 라벨로 실행한다.
- Domain Expert와 Reviewer는 read-only다. 직접 코드, 설정, 제품 산출물을 수정하지 않는다.
- Root stage gate는 파일, 상태, 형식, 승인, content hash, consistency hook을 검증한다. 도메인 판단은 Domain Expert 책임이다.

## Runtime Preconditions Gate

PM 인터뷰 전에 Root orchestrator가 runtime 방식을 한 가지로 확정한다.

허용 값:

- `no-runtime`
- `local-process`
- `local-docker-compose`
- `existing-deployed-url`
- `kubernetes-or-cluster`
- `cloud-managed`
- `ci-runtime`
- `mock-or-simulator`
- `hybrid`

규칙:

- secret 값, token 값, env-file 경로는 문서에 저장하지 않는다.
- runtime 방식만 `00-run-setup.md`와 `run-state.json.runtime_mode`에 남긴다.
- `local-docker-compose`가 선택되면 compose 탐색, 없을 때 설치/복사, 부팅, service URL 유도는 구현 책임에 포함한다.
- 실제 env 값이 없으면 preflight를 성공 처리하지 않는다. 필요한 값은 구현 직전 `question_request`로 한 번에 한 가지씩 묻는다.

## 질문 프로토콜

역할은 사용자에게 직접 묻지 않고 `question_request`를 Root에 보고한다. Root는 PM clarification으로 현재 대화에서 한 가지씩 묻고, 답변을 `00-pm-interview.md` 또는 해당 runtime 기록에 남긴다.

```markdown
question_request:
- 질문 유형: requirement | model_choice | runtime_config | scope | approval | other
- 질문:
- 이유:
- 답변 없이는 위험한 결정:
- 답변 후보 또는 기본 가정:
- 영향받는 산출물:
```

핵심 결정, 구현 결과, 검증 통과 여부가 바뀌면 질문해야 한다. 낮은 위험의 세부사항만 가정으로 진행할 수 있다.

## run-state.json

초기 schema:

```json
{
  "run_id": "YYYY-MM-DD-topic-slug",
  "mode": "planning|implementation",
  "execution_mode": "auto_split|single_session",
  "runtime_mode": "no-runtime|local-process|local-docker-compose|existing-deployed-url|kubernetes-or-cluster|cloud-managed|ci-runtime|mock-or-simulator|hybrid",
  "runtime_gate": "root-pre-pm",
  "pending_reapproval": false,
  "pending_reapproval_reason": null,
  "stale_approvals": [],
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
  "content_hashes": {},
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ"
}
```

단계 값:

- `initialized`
- `context_load`
- `briefs_created`
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

결정 enum:

- Domain Expert Gateway: `Approved`, `Revise`, `Blocked`
- Reviewer: `Approved`, `ChangesRequested`, `Blocked`

`open_assumptions`는 `assumptions.md`에서 상태가 `open` 또는 `needs-validation`인 ID와 일치해야 한다.

재승인 관련 필드:

- `pending_reapproval`: 현재 산출물 변경 때문에 구현 승인 질문을 다시 해야 하면 `true`다. 문자열 marker가 아니라 이 필드가 원본 상태다.
- `pending_reapproval_reason`: 재승인이 필요한 이유를 한 문장으로 기록한다.
- `stale_approvals`: 승인 이후 입력 산출물이 바뀌어 더 이상 그대로 신뢰할 수 없는 Gateway 또는 approval 단계 목록이다. 예: `expert_gateway_spec`, `expert_gateway_design`, `implementation_approval`.

## 상태 전환

- 산출물 작성과 stage gate가 끝나기 전에는 `last_completed_stage`, `next_stage`, `artifacts`를 완료 상태로 앞당기지 않는다.
- `pm_spec` 완료 뒤 `expert_gateway_spec`으로 간다.
- Spec Gateway `Approved`면 `architect_design`, `Revise`면 `pm_spec`, `Blocked`면 `status=blocked`.
- Design Gateway `Approved`면 `work_plan`, `Revise`면 `architect_design`, `Blocked`면 `status=blocked`.
- `work_plan` 통과 뒤 `pending_reapproval=true`로 두고 `implementation_approval`로 간다.
- `implementation_approval`에서는 현재 `05-work-plan.md` 기준으로 구현 시작 승인을 한 가지 질문으로 확인한다. 승인 답변은 `00-pm-interview.md`에 기록한다.
- 승인되면 `pending_reapproval=false`, `pending_reapproval_reason=null`로 갱신하고, `content_hashes.implementation_approval.inputs`에 `01-pm-spec.md`, `03-architect-design.md`, `05-work-plan.md`의 SHA256을 기록한 뒤 `developer_implementation`로 간다. 거부되면 `status=blocked`로 두고 되돌아갈 후보 단계를 `blocked_reason`에 기록한다.
- Developer 완료 뒤 `reviewer_verification`으로 간다.
- Reviewer `Approved`면 `expert_gateway_final`로 간다.
- Reviewer `ChangesRequested`면 이슈 성격에 따라 되돌아간다.
  - 코드/테스트/설정 구현 문제: `developer_implementation`
  - PM 요구사항, feature contract, scope 변경 필요: `pm_spec`, 이후 Spec Gateway 재검토
  - 아키텍처, required 플랫폼 mapping, primary metric capability 변경 필요: `architect_design` 또는 `work_plan`, 이후 필요한 Gateway 재검토
  - work plan 변경 또는 승인 이후 plan 수정: `implementation_approval`
- Reviewer `Blocked`면 `status=blocked`와 `blocked_reason`을 기록한다.
- Final Gateway `Approved`면 `user_final_confirmation`, `Revise`면 문제 성격에 따라 `developer_implementation`, `architect_design`, `pm_spec` 중 하나로 되돌린다.
- 사용자 최종 확인이 승인되면 `final_report`, 수정 요청이면 `status=blocked`.
- `09-final-report.md` stage gate를 통과하면 `status=completed`, `next_stage=null`.

## 구현 진입 gate

Developer로 들어가기 전 Root는 아래를 모두 확인한다.

- `pending_reapproval=false`
- `stale_approvals=[]`이거나 해당 stale approval이 재검토 또는 명시적 재승인 scope로 해소되어 있음
- 현재 `05-work-plan.md`에 대한 사용자 승인 기록이 `00-pm-interview.md`에 있음
- 승인 이후 `01-pm-spec.md`, `03-architect-design.md`, `05-work-plan.md`, required config/manifest가 바뀌지 않았음. 이 판단은 `content_hashes.implementation_approval.inputs`의 hash로 한다.
- `content_hashes.implementation_approval.inputs`에 `01-pm-spec.md`, `03-architect-design.md`, `05-work-plan.md` baseline이 있음
- 구현 결과를 좌우하는 `needs-validation` 가정이 해소됐거나, 사용자가 미검증 보류를 명시 승인했고 그 리스크가 `00-pm-interview.md`와 `assumptions.md`에 남아 있음
- feature coverage contract가 있으면 expected 항목이 컬럼/필드 수준으로 설계 또는 work plan에 추적됨
- required primary platform capability가 있으면 설계 근거, smoke 계획, 실패 artifact 기준이 있음
- Developer brief의 Task 범위가 `05-work-plan.md`와 일치함

위 조건 중 하나라도 실패하면 `developer_implementation`으로 진행하지 않고 `implementation_approval`, `work_plan`, `architect_design`, `pm_spec` 중 가장 이른 필요한 단계로 되돌린다.

## Content Integrity

Root는 stage gate 통과와 승인 시점에 주요 입력 파일의 SHA256을 `run-state.json.content_hashes`에 기록한다.

권장 구조:

```json
{
  "implementation_approval": {
    "approved_at": "YYYY-MM-DDTHH:MM:SSZ",
    "inputs": {
      "01-pm-spec.md": "sha256:...",
      "03-architect-design.md": "sha256:...",
      "05-work-plan.md": "sha256:..."
    }
  }
}
```

재개 시 hash가 바뀌면 downstream approval은 stale로 본다.

- PM spec 변경: Spec Gateway 이후 단계 재검토
- Architect design 변경: Design Gateway 이후 단계 재검토
- Work plan 변경: implementation approval 재실행
- Developer/Reviewer 산출물 변경: Reviewer 또는 Final Gateway 재실행

hash 불일치나 승인 이후 산출물 변경이 발견되면 Root는 해당 단계를 `stale_approvals`에 추가하고, 필요한 단계로 되돌린다. 실용적으로 Domain Expert Gateway 재실행을 생략하고 사용자 재승인으로 갈음하려면, 재승인 질문에 “변경된 spec/design/work plan과 stale Gateway 포함 승인”임을 명시하고 그 승인 scope를 `00-pm-interview.md`와 `root-correction-log.md`에 기록한 뒤 `stale_approvals=[]`로 닫는다.

Gateway 결정 문서는 append-only로 다룬다. 결정 이후 입력 산출물이 바뀌면 기존 결정을 고쳐 쓰지 않고, 보정 메모와 새 Gateway 재검토를 남긴다.

## Consistency Hook

Root는 stage 전환과 재개 전에 가능하면 아래 스크립트를 실행한다.

```bash
python <agent-team-skill-dir>/scripts/check-run-consistency.py <run-dir>
```

`<agent-team-skill-dir>`는 로드한 `agent-team` 스킬 디렉터리 기준으로 해석한다. 사용자별 dotfiles 절대 경로를 규칙에 고정하지 않는다.

hook 실패는 stage gate 실패로 처리한다. hook이 없거나 실행할 수 없으면 그 사실을 `stage_gate_failure`에 기록하고 수동 검사를 수행한다.

검사 대상:

- `run-state.json` schema와 enum
- artifact 경로가 현재 run 디렉터리 내부인지
- `assumptions.md` 상태 enum
- `open_assumptions`와 `assumptions.md` 일치
- 승인 이후 수정된 입력 파일
- 구현 진입 gate
- read-only 역할 산출물의 직접 수정 주장
- 예상 밖 top-level numbered artifact

## Brief snapshot

- Domain Expert Gateway retry: `briefs/domain-expert-<gateway>-retry-<n>.md`
- Architect retry: `briefs/architect-<stage>-retry-<n>.md`
- Developer retry: `briefs/developer-retry-<n>.md`
- Reviewer retry: `briefs/reviewer-retry-<n>.md`

최신 실행용 `briefs/<role>.md`는 갱신할 수 있지만, retry snapshot은 덮어쓰지 않는다.

## Retry output artifacts

- Top-level numbered artifacts are fixed lifecycle stage files only: `00-*`, `01-pm-spec.md`, `02-expert-gateway-spec.md`, `03-architect-design.md`, `04-expert-gateway-design.md`, `05-work-plan.md`, `06-developer-implementation.md`, `07-reviewer-verification.md`, `08-expert-gateway-final.md`, `09-final-report.md`.
- Reviewer `ChangesRequested` 이후 재설계, 보정 계획, Developer fix 기록, 재검증 보조 문서는 top-level `08/09/10...`로 이어 쓰지 않는다.
- 이런 산출물은 `reviewer-retry-<n>/NN-*.md` 아래에 둔다. 내부 `NN`은 retry 디렉터리 안에서만 의미가 있다.
- `run-state.json.artifacts`에는 retry 산출물을 `reviewer_retry_<n>_<purpose>` 형식의 key로 추적한다.
- Root stage gate는 run root의 예상 밖 top-level `NN-*.md`를 오류로 본다.

## 반복 한도

- 각 Domain Expert Gateway `Revise` 반복은 최대 2회다.
- Developer fix와 Reviewer 재검증 반복은 최대 2회다.
- 한도 초과 시 `status=blocked`와 마지막 실패 이유, 사용자 선택지를 남긴다.

## 산출물 최소 검증 기준

### `00-run-setup.md`

- run-id, 실행 위치, mode, execution_mode, 실행 디렉터리
- Runtime Preconditions Gate 결과
- runtime 방식과 실행 책임
- secret 저장 금지
- 생성한 초기 파일

### `01-pm-spec.md`

- PM 인터뷰 근거
- 사용자 시나리오, 범위, 성공 기준
- 데이터 명세와 원천/파생 경계
- feature coverage contract 또는 해당 없음
- AI 기능 고려사항 또는 해당 없음
- required/preferred/candidate 기술 방향
- 실행 mode 원본
- 열린 질문과 가정

### Domain Expert Gateway

- decision enum
- 승인 근거 또는 필수 수정사항
- 검토한 가정
- 도메인 리스크
- Gateway brief snapshot 존재와 `current_stage` 일치

### `03-architect-design.md`

- 설계 요약과 PM 명세 연결
- Run manifest
- 컴포넌트와 책임
- 데이터/feature 흐름
- feature coverage 설계
- required 기술/플랫폼 설계
- 평가와 수용 기준
- runtime/config/secret 경계
- 열린 가정

### `05-work-plan.md`

- 구현 전 gate
- Task Plan
- feature coverage 작업
- required runtime 작업
- 검증 계획
- implementation approval 질문 대상 명시

### `06-developer-implementation.md`

- 구현 상태
- 변경 파일
- 실행한 명령
- Work Plan task 추적표
- feature coverage 구현 비교
- required runtime/platform 구현
- 계획 대비 변경
- 테스트 커버리지
- 해결/추가한 가정

### `07-reviewer-verification.md`

- Reviewer decision enum
- 실행한 검증
- 발견 이슈와 심각도
- 되돌아갈 단계 판단
- 명세/설계/계획 준수
- feature coverage 검증
- required runtime/platform 검증
- 열린 가정
- 최종 보고 입력

### `09-final-report.md`

- 실행 전제와 runtime 방식
- 설치/준비 명령
- 구현된 mode별 실행 예시
- 성공 artifact와 확인 명령
- 실패 artifact와 실패 해석 기준
- feature coverage 결과
- required 기술/플랫폼 primary/fallback 경계
- 테스트와 검증 명령
- 열린 가정과 후속 조치
