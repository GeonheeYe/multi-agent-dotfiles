# 에이전트 팀 산출물

실행 디렉터리 구조, 역할 작업 지시서, 출력 규칙, 가정 목록, AI 기능 체크리스트를 아래에 정의한다. 실행 시작/재개, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리와 반복 한도, `run-state.json` 상태 재구성, 산출물 검증 기준은 `workflow-runtime.md`를 따른다.

## 실행 디렉터리와 생성 파일

각 실행은 선택한 저장 위치 아래에 산출물을 쓴다:

```text
<선택한 저장 위치>/docs/agent-team/<run-id>/
├── run-state.json                # `status`, `current_stage`, `next_stage` 등을 기록하는 실행 상태 파일, 최종 산출물이 아님
├── 00-context.md                 # 로드한 컨텍스트 또는 컨텍스트 없음/실패 기록
├── 00-run-setup.md               # Root orchestrator가 기록한 실행 기본 정보
├── 00-pm-interview.md            # PM이 사용자와 정리한 인터뷰 노트
├── assumptions.md                # 가정 목록
├── briefs/                       # 역할 작업 지시서, 최종 산출물이 아님
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

`00-run-setup.md`는 Root orchestrator가 작성하는 실행 기본 정보다. `run-id`, 실행 위치, `mode`, 실행 디렉터리, `execution_mode`, 생성한 초기 파일 목록만 기록한다. 프로젝트 주제, 목표, 주요 사용자, 해결하려는 일/결정, 입력 데이터, 기대 출력, 성공 기준은 기록하지 않고 PM 인터뷰에서 다룬다.

`00-context.md`는 Root orchestrator가 컨텍스트 로드 단계에서 작성한다. 최소 포함 항목:

- 참고 문서 목록: 불러온 외부 문서, wiki, 기존 프로젝트 문서, 데이터 설명 파일. 없으면 `컨텍스트 없음`으로 명시한다.
- 컨텍스트 로드 결과: 성공이면 수집한 내용 요약. 실패이면 시도한 출처와 실패 이유.
- `implementation` 모드이면 대상 저장소 현재 구조 요약: 주요 디렉터리·파일·기존 코드 존재 여부.
- 사용자가 기준 실행 경로(reference run)를 지정한 경우, 기준 실행 파일 목록과 단계 상태, 주요 섹션 구조, 반복해서 보존해야 할 품질 경계(예: 원천 데이터와 파생 feature 분리, required 기술 하위 서비스 매핑, 실패 artifact, PoC/실서비스 경계)를 요약한다.
- 기준 실행 경로가 있더라도 기준 실행의 요구사항을 현재 실행의 확정 요구사항으로 복사하지 않는다. 기준 실행은 PM 인터뷰 후보 답변과 산출물 품질 비교 기준이며, 현재 실행에서 사용자가 확인한 내용만 확정 요구사항이 된다.
- 컨텍스트가 있더라도 확정 요구사항이 아님을 명시한다. PM 인터뷰에서 사용자가 확인한 내용만 확정 요구사항이 된다.

`00-pm-interview.md`는 PM이 사용자에게 한 질문, 사용자 답변, 확정 요구사항, 열린 질문, PM 인터뷰 진행 체크리스트를 누적하는 작업 노트다. 인터뷰 진행 방식, 기술 방향의 `required`/`preferred`/`candidate` 분류 기준, 이전 대화 내용 처리 규칙은 `references/roles/pm.md`를 따른다.

`briefs/<role>.md` 파일은 역할 프롬프트(`references/roles/<role>.md`)와 함께 역할 실행 입력으로 전달된다. PM 인터뷰 단계에서는 현재 대화에서 참조하고, PM 인터뷰 이후 역할은 `sub-agent` 또는 `single_session` 역할 라벨 실행에 전달한다. 사용자에게 보여주는 최종 산출물은 아니다. 사람에게 필요한 작업 지시는 상단에 두고, 실행 추적 정보는 하단 `System Handoff`에 둔다.

`briefs/domain-expert.md`는 최신 Domain Expert 실행용 작업 지시서다. Domain Expert는 한 실행에서 세 번 호출될 수 있으므로, Root orchestrator는 각 Gateway 시작 직전에 같은 내용을 별도 스냅샷으로도 저장한다:

- `briefs/domain-expert-01-spec.md`: PM 명세 검토 Gateway 입력
- `briefs/domain-expert-02-design.md`: Architect 설계 검토 Gateway 입력. `05-work-plan.md`는 이 Gateway 승인 뒤 작성되므로 Gateway 2 입력으로 요구하지 않는다.
- `briefs/domain-expert-03-final.md`: 최종 구현/검증 결과 검토 Gateway 입력

같은 Gateway가 `Revise` 또는 `stage gate` 실패 후 재시도되면 기존 스냅샷을 덮어쓰지 않고 `briefs/domain-expert-01-spec-retry-1.md`처럼 `-retry-<n>` suffix를 붙여 저장한다. 이렇게 해야 최종 산출물 `02/04/08-expert-gateway-*.md`뿐 아니라 각 검토가 어떤 지시로 실행됐는지도 순서대로 확인할 수 있다.

## briefs/<role>.md 작업 지시서 입력

`briefs/<role>.md` 형식은 `references/handoff-template.md`를 따른다.

각 역할 작업 지시서에는 아래를 포함한다. 값이 없으면 “없음”, “아직 생성 전”, “사용자 입력 필요” 중 하나로 표시한다:

- 역할 정의: `name`, `description`, 권한/도구 경계, 사용자 질문 방식
- 사용자 요청
- 저장소/프로젝트 위치
- 로드한 컨텍스트 또는 컨텍스트 실패 정보
- 기준 실행 경로와 기준 실행에서 보존해야 할 구조·의미·표현 기준. 기준 실행이 없으면 `해당 없음`으로 표시한다.
- `00-run-setup.md` 경로
- `00-pm-interview.md` 경로와 현재 인터뷰 상태
- 기술 방향/플랫폼 제약/선호 요약
- 기술 방향의 `required`, `preferred`, `candidate` 구분
- 공통 역할 프롬프트 경로
- 사용자 요청, 컨텍스트, 프로젝트 문서에서 확인한 프로젝트별 요구사항
- 현재 입력 산출물 경로. 예: Architect는 `01-pm-spec.md`와 `02-expert-gateway-spec.md`를 입력으로 받는다.
- 작성할 출력 산출물 경로. 예: Developer는 `06-developer-implementation.md`만 작성한다.
- `assumptions.md` 경로
- `run-state.json` 경로와 `current_stage`는 하단 `System Handoff`에 기록
- 역할이 올린 `question_request`가 있으면 PM clarification 질문/답변 경로와 반영해야 할 산출물을 기록
- Developer brief에는 구현 전 사용자 승인 기록이 있는 `00-pm-interview.md` 경로와 승인한 `05-work-plan.md` 경로를 포함
- 현재 역할 입력에 영향을 주는 Domain Expert Gateway 결과와 필수 수정사항. 직전 단계나 현재 반복에 관련 Domain Expert Gateway 결과가 없으면 `해당 없음`으로 표시한다.
- Domain Expert 또는 Architect처럼 한 역할이 여러 번 실행되는 brief라면 `System Handoff`에 `brief_snapshot`을 기록한다. Domain Expert Gateway brief는 `gateway_stage`도 함께 기록한다.
- `stage gate` 결과 또는 실패 항목. 실패 항목은 누락된 파일/섹션, 기대값, 실제 확인값을 포함한다.

`briefs/pm.md`는 초기 파일 생성과 컨텍스트 로드가 끝나면 생성한다. PM brief에는 “PM은 먼저 사용자 인터뷰를 수행해야 한다”는 지시와 `references/roles/pm.md`의 PM 인터뷰 질문 진행 순서를 따르라는 지시를 명시한다. PM 인터뷰는 `sub-agent`로 실행하지 않고 현재 대화에서 직접 진행한다. PM은 사용자 인터뷰와 사용자 승인 후 `01-pm-spec.md` 작성을 담당한다. 이전 대화의 내용은 질문 맥락과 후보 답변으로만 사용하고, 현재 실행에서 사용자가 확인한 답변만 확정 요구사항으로 기록한다.

현재 실행 산출물과 기준 실행 산출물은 경로 수준에서도 분리한다. 기준 실행(reference run) 경로는 비교 입력으로만 다루고, 현재 실행의 `run-state.json artifacts`, `주요 산출물 경로`, 역할 brief의 출력 경로에는 현재 실행 디렉터리 내부 경로만 기록한다. 새 실행이나 replay 실행에서 기준 실행의 절대 경로를 현재 산출물 경로로 복사하면 현재 실행 완료로 보지 않는다.

역할별 권한/도구 경계는 brief에 명시한다. Domain Expert는 `read-only/domain-validation-only`, Architect는 `docs-only/design-and-plan`, Developer는 `code-editing-with-approved-work-plan`, Reviewer는 `read-only/verification-only`로 기록한다. Reviewer가 필요하면 발견 이슈를 보안, 성능, 테스트/평가, 필수 플랫폼 연동, 제품/명세 준수 관점으로 세분화할 수 있지만, 기본 역할 파일이나 단계 수를 늘리지는 않는다. Debugger는 별도 기본 역할이 아니라 Developer fix 반복에서 원인 분석 관점으로만 사용한다.

`briefs/architect.md`는 최신 Architect 실행용 작업 지시서다. Architect는 한 실행에서 두 번 호출될 수 있으므로, Root orchestrator는 각 Architect 단계 시작 직전에 같은 내용을 별도 스냅샷으로도 저장한다:

- `briefs/architect-01-design.md`: Architect 설계 단계 입력. `03-architect-design.md` 작성용이다.
- `briefs/architect-02-work-plan.md`: Architect 구현 계획 단계 입력. `05-work-plan.md` 작성용이다.

같은 Architect 단계를 재시도할 때는 기존 스냅샷을 덮어쓰지 말고 `briefs/architect-01-design-retry-1.md`처럼 `-retry-<n>` suffix를 붙인 새 파일로 저장한다. `architect_design` 단계 brief는 `03-architect-design.md` 작성을, `work_plan` 단계 brief는 `04-expert-gateway-design.md` 승인 결과를 입력으로 `05-work-plan.md` 작성을 지시한다. Architect가 따라야 할 설계 규칙(Mermaid 다이어그램, 데이터 소스 역할과 원천·파생 경계 보존, `required` 기술/플랫폼 제약 반영, runtime/config checklist, 서비스/모듈 매핑 등)은 `references/roles/architect.md`를, 산출물 최소 검증 기준은 `references/workflow-runtime.md`를 따른다.

## assumptions.md 가정 목록 관리

실행 디렉터리를 준비할 때 Root orchestrator는 아래 테이블 헤더를 가진 `assumptions.md`를 먼저 생성한다. 모든 가정은 `assumptions.md`에 유지한다. 단계별 산출물에는 해당 단계에서 추가되거나 바뀐 가정만 적고 가정 ID를 참조한다.

가정 목록 형식:

| ID | 단계 | 담당 | 가정 | 근거 | 틀렸을 때 리스크 | 검증 방법 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- |

상태 값:

- `open`: 아직 검증하지 않음
- `accepted`: 일단 받아들이고 진행
- `needs-validation`: 의존하기 전에 반드시 검증 필요
- `rejected`: 틀린 것으로 확인됨
- `resolved`: 검증되었거나 닫힘

가정을 본문에 숨기지 않는다. 확정되지 않은 전제는 `assumptions.md`에 새 ID로 추가하고, 명세, 설계, 계획, 검토, Domain Expert Gateway 메모에서는 그 ID를 참조한다.

## 사용자 대화 출력과 최종 보고 규칙

각 단계가 끝나면 대화에는 짧은 요약과 산출물 경로만 보여준다. 짧은 요약은 완료한 역할, 생성/갱신한 파일, `next_stage` 또는 `blocked_reason`까지만 포함한다. 전체 내용은 실행 디렉터리에 저장한다.

`user_final_confirmation`에는 아래를 포함한다:

- PM 명세 요약과 `01-pm-spec.md`
- 아키텍처 설계 요약과 `03-architect-design.md`
- Task Plan 요약과 `05-work-plan.md`
- 구현 전 사용자 승인 기록과 `00-pm-interview.md`
- Developer implementation 요약과 `06-developer-implementation.md`
- Reviewer verification 요약과 `07-reviewer-verification.md`
- 사용자 실행 가이드 요약. 최소한 CLI help, `run-e2e` 실행 명령, 성공 시 `metrics.json` 확인 명령, 실패 시 `run_failure.json` 확인 명령을 포함한다.
- 모델 과제 유형과 required 플랫폼 적합성 요약. 예: 시계열 예측이 필요한데 required 플랫폼이 해당 과제를 직접 지원하지 않으면 별도 모델/플랫폼 역할 분리 또는 사용자 확인 필요성을 표시한다.
- 운영 데이터 기반 지속 개선 루프 구현/검증 요약. 포함된 경우 예측·운영 기록 수집, 정답·결과 후보 저장, 오프라인 평가, 개선 후보 트리거, 사람 승인 경계를 표시한다.
- 최종 Domain Expert 결정과 `08-expert-gateway-final.md`
- 주요 열린 가정과 `assumptions.md`
- `user_final_confirmation` 승인 또는 수정 요청 여부 질문

Root orchestrator는 `user_final_confirmation` 후 `09-final-report.md`를 작성한다. 최종 보고 필수 섹션은 `references/workflow-runtime.md`의 Final report `09-final-report.md` 검증 기준을 따른다.

`09-final-report.md`는 사용자가 바로 실행하고 실패를 해석할 수 있는 runbook 수준으로 작성한다. Root orchestrator는 `07-reviewer-verification.md`, `06-developer-implementation.md`, 실제 생성 artifact를 다시 읽고 아래 정보를 현재 실행 경로 기준으로 옮긴다:

- CLI help, `profile-schema`, `run-e2e`, `predict`, 운영 개선 관련 mode 실행 예시
- 성공 시 확인할 artifact와 지표 확인 명령
- 실패 시 확인할 `run_failure.json` 또는 동등한 실패 artifact와 실패를 성공으로 해석하지 않는 기준
- 모델 과제 유형, required 플랫폼 적합성, 모델 실행 순서, runtime/schema smoke 결과
- 기준 실행을 제공받은 경우 기준 실행 대비 구조·의미·표현 자체점검

위 항목을 작성할 근거가 이전 산출물에 없으면 Root orchestrator가 추측해서 채우지 않고 Reviewer 또는 해당 역할 단계로 되돌린다.

## AI 기능 포함 시 고려사항

요청이 AI 기능을 포함하는지 판단하고 명세/설계에 반영하는 책임은 PM과 Architect에 있다. 고려 항목(합성 데이터 생성, 모델 선택 기준, 평가 데이터셋과 수용 기준, 추론/서빙 경로, 사람 승인/피드백 반복, 운영 데이터 기반 지속 개선 루프 경계, 모니터링/실패 처리)과 PoC·실서비스 경계 확인 질문은 `references/roles/pm.md`와 `references/roles/architect.md`를 따른다.
