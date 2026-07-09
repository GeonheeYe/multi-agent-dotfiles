# 에이전트 팀 산출물

이 문서는 실행 디렉터리, 역할 brief, 가정 목록, 최종 보고 규칙을 정의한다. 실행 재개, 상태 전환, stage gate, content hash 검증은 `workflow-runtime.md`를 따른다.

## 실행 디렉터리

각 실행은 선택한 저장 위치 아래에 산출물을 쓴다.

```text
<선택한 저장 위치>/docs/agent-team/<run-id>/
├── run-state.json
├── 00-run-setup.md
├── 00-context.md
├── 00-pm-interview.md
├── assumptions.md
├── briefs/
│   ├── pm.md
│   ├── domain-expert.md
│   ├── domain-expert-01-spec.md
│   ├── domain-expert-02-design.md
│   ├── domain-expert-03-final.md
│   ├── architect.md
│   ├── architect-01-design.md
│   ├── architect-02-work-plan.md
│   ├── developer.md
│   └── reviewer.md
├── 01-pm-spec.md
├── 02-expert-gateway-spec.md
├── 03-architect-design.md
├── 04-expert-gateway-design.md
├── 05-work-plan.md
├── 06-developer-implementation.md
├── 07-reviewer-verification.md
├── 08-expert-gateway-final.md
└── 09-final-report.md
```

Top-level numbered files are reserved for the lifecycle artifacts above. Do not create `08-*`, `09-*`, `10-*`, or any other extra `NN-*.md` in the run root for Reviewer feedback, rework, correction logs, or retry notes.

Retry and rework artifacts live in dedicated retry directories:

```text
<run-id>/
├── reviewer-retry-1/
│   ├── 01-architect-<topic>-design.md
│   ├── 02-<topic>-work-plan.md
│   └── 03-developer-<topic>-implementation.md
├── reviewer-retry-2/
│   └── ...
└── root-correction-log.md
```

The numbering inside a retry directory is local to that retry and never extends the top-level stage sequence. Track these paths in `run-state.json.artifacts` with keys such as `reviewer_retry_1_architect_design`, not with top-level stage artifact keys.

## Root 산출물

`00-run-setup.md`는 Root orchestrator가 작성한다.

- run-id
- 실행 위치와 `mode`
- 실행 디렉터리
- `execution_mode`
- 생성한 초기 파일
- `Runtime Preconditions Gate` 결과
- runtime 방식과 실행 책임
- secret/env-file 경로 저장 금지 원칙

`00-context.md`는 context load 결과를 기록한다.

- 참고 문서 목록
- 컨텍스트 로드 성공/실패
- 구현 모드이면 대상 저장소 구조 요약
- 기준 실행(reference run)이 있으면 파일 목록, 단계 상태, 보존할 구조/의미/표현 기준
- 기준 실행 요구사항은 현재 사용자 확인 없이는 확정 요구사항이 아니라는 명시

## 역할 brief

`briefs/<role>.md`는 역할 실행 입력이다. 최종 산출물이 아니며, 사람에게 중요한 작업 지시는 상단에 두고 실행 추적 값은 하단 `System Handoff`에 둔다.

필수 포함 항목:

- 역할 정의와 권한/도구 경계
- 사용자 요청 요약
- 저장소/프로젝트 위치
- context load 결과
- 기준 실행 경로와 보존할 품질 기준
- 입력 산출물
- 작성할 출력 산출물
- `assumptions.md`
- `run-state.json`
- 직전 Domain Expert Gateway 결과
- `stage gate` 실패 항목
- `System Handoff`의 `current_stage`, `next_stage`, `sender`, `receiver`

스냅샷 규칙:

- Domain Expert Gateway는 Gateway별 snapshot을 남긴다.
- Architect는 design/work plan 단계별 snapshot을 남긴다.
- Developer와 Reviewer도 재시도에서는 기존 brief를 덮어쓰지 않고 `briefs/developer-retry-<n>.md`, `briefs/reviewer-retry-<n>.md`를 남긴다.
- Reviewer feedback 이후 재작업 산출물은 `reviewer-retry-<n>/` 아래에 둔다. brief snapshot은 `briefs/`에, 실제 재설계/재구현/재검증 기록은 retry 디렉터리에 둔다.

## assumptions.md

모든 가정은 `assumptions.md`를 원본으로 유지한다.

```markdown
| ID | 단계 | 담당 | 가정 | 근거 | 틀렸을 때 리스크 | 검증 방법 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- |
```

상태 값은 아래 enum만 허용한다.

- `open`: 아직 검증하지 않음
- `accepted`: 일단 받아들이고 진행 가능
- `needs-validation`: 의존하기 전에 반드시 검증 필요
- `rejected`: 틀린 것으로 확인됨
- `resolved`: 검증되었거나 닫힘

`run-state.json`의 `open_assumptions`에는 `open`, `needs-validation` 상태의 ID만 들어간다. `accepted`, `resolved`, `rejected`는 열린 가정으로 기록하지 않는다.

## 사용자 대화 출력

각 단계가 끝나면 대화에는 짧은 요약, 생성/갱신 파일, `next_stage` 또는 `blocked_reason`만 보여준다. 전체 내용은 실행 디렉터리에 저장한다.

## 최종 확인과 최종 보고

`user_final_confirmation`에는 아래를 포함한다.

- PM 명세 요약과 `01-pm-spec.md`
- Architect 설계 요약과 `03-architect-design.md`
- Work Plan 요약과 `05-work-plan.md`
- 구현 전 사용자 승인 기록
- Developer implementation 요약과 `06-developer-implementation.md`
- Reviewer verification 요약과 `07-reviewer-verification.md`
- 사용자가 실제로 실행할 runbook 요약
- required 기술/플랫폼 적합성 요약
- feature coverage와 남은 차이
- 최종 Domain Expert 결정과 `08-expert-gateway-final.md`
- 열린 가정과 `assumptions.md`
- 사용자 승인 또는 수정 요청 질문

`09-final-report.md`는 사용자가 바로 실행하고 실패를 해석할 수 있는 runbook 수준으로 작성한다.

필수 섹션:

- 실행 전제와 runtime 방식
- 설치 또는 준비 명령
- 구현된 CLI/API/UI mode 목록
- mode별 실행 예시
- 성공 artifact와 확인 명령
- 실패 artifact와 실패를 성공으로 해석하지 않는 기준
- feature coverage 결과
- required 기술/플랫폼 primary path와 fallback 경계
- 테스트와 검증 명령
- 남은 열린 가정과 후속 조치
- 기준 실행 대비 구조/의미/표현 자체점검

위 정보를 작성할 근거가 이전 산출물에 없으면 Root orchestrator가 추측하지 않고 Reviewer 또는 해당 역할 단계로 되돌린다.
