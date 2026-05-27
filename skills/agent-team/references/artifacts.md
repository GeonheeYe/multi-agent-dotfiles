# 에이전트 팀 산출물

이 파일은 실행 디렉터리 구조, 역할 작업 지시서, 출력 규칙, 가정 목록, AI 기능 체크리스트를 다룬다. 실행 시작/재개, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리와 반복 한도, `run-state.json` 상태 재구성, 산출물 검증 기준은 `workflow-runtime.md`를 따른다.

## 실행 디렉터리와 생성 파일

각 실행은 선택한 저장 위치 아래에 산출물을 쓴다:

```text
<선택한 저장 위치>/docs/agent-team/<run-id>/
├── run-state.json                # `status`, `current_stage`, `next_stage` 등을 기록하는 실행 상태 파일, 최종 산출물이 아님
├── 00-context.md                 # 로드한 컨텍스트 또는 컨텍스트 없음/실패 기록
├── 00-run-setup.md               # Root orchestrator가 기록한 실행 메타정보
├── 00-pm-interview.md            # PM이 사용자와 정리한 인터뷰 노트
├── assumptions.md                # 가정 목록
├── briefs/                       # 역할 작업 지시서, 최종 산출물이 아님
│   ├── pm.md
│   ├── domain-expert.md
│   ├── architect.md
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

`00-run-setup.md`는 Root orchestrator가 작성하는 실행 메타정보다. `run-id`, 실행 위치, `mode`, 실행 디렉터리, `execution_mode`, 생성한 초기 파일 목록만 기록한다. 프로젝트 주제, 목표, 주요 사용자, 해결하려는 일/결정, 입력 데이터, 기대 출력, 성공 기준은 기록하지 않고 PM 인터뷰에서 다룬다.

`00-pm-interview.md`는 PM이 사용자에게 한 질문, 사용자 답변, 확정 요구사항, 열린 질문을 누적하는 작업 노트다. 이미 인터뷰 질문과 답변이 진행된 상태라면 그 내용을 인터뷰 기록으로 정리한다. 구현 흐름의 기술 방향/플랫폼 제약/선호도 PM 인터뷰에서 확인한다. 예: NeMo Microservices, NeMo Agent Toolkit, 특정 클라우드, 로컬 실행, 특정 프레임워크.

`briefs/<role>.md` 파일은 역할 프롬프트(`references/roles/<role>.md`)와 함께 역할 실행 입력으로 전달된다. Root orchestrator가 단계 전환 전에 생성 또는 갱신하며, `single_session`에서도 같은 입력 경계를 기록하기 위해 생성한다. 사용자에게 보여주는 최종 산출물은 아니다. 사람에게 필요한 작업 지시는 상단에 두고, 실행 추적용 메타데이터는 하단 `System Handoff`에 둔다.

## briefs/<role>.md 작업 지시서 입력

`briefs/<role>.md` 형식은 `references/handoff-template.md`를 따른다.

각 역할 작업 지시서에는 아래를 포함한다. 값이 없으면 “없음”, “아직 생성 전”, “사용자 입력 필요” 중 하나로 표시한다:

- 사용자 요청
- 저장소/프로젝트 위치
- 로드한 컨텍스트 또는 컨텍스트 실패 정보
- `00-run-setup.md` 경로
- `00-pm-interview.md` 경로와 현재 인터뷰 상태
- 기술 방향/플랫폼 제약/선호 요약
- 공통 역할 프롬프트 경로
- 사용자 요청, 컨텍스트, 프로젝트 문서에서 확인한 프로젝트별 요구사항
- 현재 입력 산출물 경로. 예: Architect는 `01-pm-spec.md`와 `02-expert-gateway-spec.md`를 입력으로 받는다.
- 작성할 출력 산출물 경로. 예: Developer는 `06-developer-implementation.md`만 작성한다.
- `assumptions.md` 경로
- `run-state.json` 경로와 `current_stage`는 하단 `System Handoff`에 기록
- 현재 역할 입력에 영향을 주는 Domain Expert Gateway 결과와 필수 수정사항. 직전 단계나 현재 반복에 관련 Domain Expert Gateway 결과가 없으면 `해당 없음`으로 표시한다.
- `stage gate` 결과 또는 실패 항목. 실패 항목은 누락된 파일/섹션, 기대값, 실제 확인값을 포함한다.

`briefs/pm.md`는 초기 파일 생성과 컨텍스트 로드가 끝나면 생성한다. PM brief에는 “PM은 먼저 사용자 인터뷰를 수행해야 한다”는 지시를 명시한다. PM은 사용자 인터뷰와 `01-pm-spec.md` 작성을 담당한다. `auto_split`에서 PM이 사용자에게 직접 질문할 수 없으면 PM이 작성한 질문을 Root orchestrator가 그대로 전달한다. 이미 인터뷰 질문과 답변이 진행된 상태라면 PM은 이를 인터뷰 기록으로 정리하고 명세를 작성한다.

`briefs/architect.md`는 Architect가 `03-architect-design.md`에 Mermaid 구조 다이어그램을 포함하도록 지시한다. 최소 Mermaid 다이어그램은 데이터 흐름도와 실행 모드 또는 제어 흐름도다. Architect는 PM 명세의 데이터 소스 역할을 변경하지 않는다. `schema_reference` 데이터는 profiling, canonical mapping, adapter 설계 참고까지만 연결하고 모델 학습/평가/추론 흐름에 직접 연결하지 않는다.

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
- Developer implementation 요약과 `06-developer-implementation.md`
- Reviewer verification 요약과 `07-reviewer-verification.md`
- 최종 Domain Expert 결정과 `08-expert-gateway-final.md`
- 주요 열린 가정과 `assumptions.md`
- `user_final_confirmation` 승인 또는 수정 요청 여부 질문

Root orchestrator는 `user_final_confirmation` 후 `09-final-report.md`를 작성한다. 최종 보고 필수 섹션은 `references/workflow-runtime.md`의 Final report `09-final-report.md` 검증 기준을 따른다.

## AI 기능 포함 시 PM/Architect 체크리스트

PM은 명세 작성 시 요청이 AI 기능을 포함하는지 판단하고, Architect는 PM 판단과 명세를 바탕으로 설계에 반영한다. 요청이 AI 기능을 포함하면 PM과 Architect는 아래 항목을 고려한다:

- 합성 데이터 생성
- 모델/프롬프트 반복을 위한 오프라인 신뢰성 반복
- 평가 데이터셋과 수용 기준
- 온라인 서빙 또는 추론 경로
- 사람 승인 또는 피드백 반복
- 모니터링 신호와 실패 처리

요청이나 컨텍스트가 데이터 플라이휠을 암시하면 PM 명세에는 데이터 수집과 라벨/승인 기준을, Architect 설계에는 학습/검증 분리와 배포 경계를, Task Plan에는 피드백 수집과 재학습 시작 조건을 포함한다.
