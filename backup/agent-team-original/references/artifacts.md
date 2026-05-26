# 에이전트 팀 산출물

이 파일은 실행 디렉터리 구조, 역할 작업 지시서, 출력 규칙, 가정 목록, AI 기능 체크리스트를 다룬다. 실행 시작/재개, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리와 반복 한도, `run-state.json` 상태 재구성, 산출물 검증 기준은 `workflow-runtime.md`를 따른다.

## 실행 디렉터리와 생성 파일

각 실행은 선택한 저장 위치 아래에 산출물을 쓴다:

```text
<선택한 저장 위치>/docs/agent-team/<run-id>/
├── run-state.json                # 실행 상태 파일, 최종 산출물이 아님
├── 00-context.md                 # 로드한 컨텍스트 또는 컨텍스트 없음/실패 기록
├── assumptions.md                # 가정 목록
├── briefs/                       # 생성된 역할 작업 지시서, 최종 산출물이 아님
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

`briefs/<role>.md` 파일은 각 역할에 전달하는 생성 지시서이며, 이전 단계에서 다음 역할로 넘어가는 `handoff` 정보를 함께 담는다. Root orchestrator가 단계 전환 전에 생성 또는 갱신한다. `single_session`에서도 같은 입력 경계와 기록을 유지하기 위해 생성한다. 사용자에게 보여주는 최종 산출물은 아니다.

Root orchestrator는 역할 프롬프트(`references/agents/<role>/agent.md`)를 참고해 `briefs/<role>.md`를 생성한다. 역할 `sub-agent`는 역할 프롬프트와 `briefs/<role>.md`를 함께 입력으로 받는다. 역할 프롬프트의 실행 입력 섹션은 `sub-agent` 실행 시 제공되는 입력 목록이며, `briefs/<role>.md` 생성을 위한 선행 입력 목록이 아니다.

역할별 `briefs/<role>.md`는 아래 입력과 출력을 연결한다:

| 역할 | brief 파일 | 주요 입력 산출물 | 역할이 작성하는 산출물 |
| --- | --- | --- | --- |
| PM | `briefs/pm.md` | 사용자 요청, `00-context.md`, 기존 프로젝트 맥락 | `01-pm-spec.md` |
| Domain Expert | `briefs/domain-expert.md` | 검토 대상 산출물, `assumptions.md`, 이전 Domain Expert 결정 | `02/04/08-expert-gateway-*.md` |
| Architect | `briefs/architect.md` | `01-pm-spec.md`, `02-expert-gateway-spec.md`, 프로젝트 맥락 | `03-architect-design.md`, `05-work-plan.md` |
| Developer | `briefs/developer.md` | `03-architect-design.md`, `04-expert-gateway-design.md`, `05-work-plan.md`, 대상 저장소 | `06-developer-implementation.md`와 실제 코드/설정/문서 변경 |
| Reviewer | `briefs/reviewer.md` | `01-pm-spec.md`, `03-architect-design.md`, `05-work-plan.md`, `06-developer-implementation.md`, 구현 변경 내역 | `07-reviewer-verification.md` |

## briefs/<role>.md 작업 지시서 입력

`briefs/<role>.md` 안의 `handoff` 섹션 형식은 `references/handoff-template.md`를 따른다.

각 역할 작업 지시서에는 아래를 포함한다. 값이 없으면 빈 항목으로 두지 말고 “없음”, “아직 생성 전”, “사용자 입력 필요” 중 하나로 표시한다:

- 사용자 요청
- 저장소/프로젝트 위치
- 로드한 컨텍스트 또는 컨텍스트 실패 정보
- 공통 역할 프롬프트 경로
- 사용자 요청, 컨텍스트, 프로젝트 문서에서 확인한 프로젝트별 요구사항
- 현재 입력 산출물 경로. 예: Architect는 `01-pm-spec.md`와 `02-expert-gateway-spec.md`를 입력으로 받는다.
- 작성할 출력 산출물 경로. 예: Developer는 `06-developer-implementation.md`만 작성한다.
- `assumptions.md` 경로
- `run-state.json` 경로와 현재 단계
- 이전 Domain Expert 결정과 필수 수정사항
- `stage gate` 결과 또는 실패 항목. 실패 항목은 누락된 파일/섹션, 기대값, 실제 확인값을 포함한다.

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

각 단계가 끝나면 대화에는 짧은 요약과 산출물 경로만 보여준다. 짧은 요약은 완료한 역할, 생성/갱신한 파일, 다음 단계 또는 차단 사유까지만 포함한다. 전체 내용은 실행 디렉터리에 저장한다.

사용자 최종 확인에는 아래를 포함한다:

- PM 명세 요약과 `01-pm-spec.md`
- 아키텍처 설계 요약과 `03-architect-design.md`
- Task Plan 요약과 `05-work-plan.md`
- Developer implementation 요약과 `06-developer-implementation.md`
- Reviewer verification 요약과 `07-reviewer-verification.md`
- 최종 Domain Expert 결정과 `08-expert-gateway-final.md`
- 주요 열린 가정과 `assumptions.md`
- 최종 확인 또는 수정 요청 여부 질문

Root orchestrator는 사용자 최종 확인 후 `09-final-report.md`를 작성한다. 최종 보고에는 아래를 포함한다:

- 무엇을 만들었거나 명세화했는지
- 주요 산출물 경로
- 테스트/평가 결과
- 남은 차이 또는 열린 가정
- 최종 Domain Expert 결정
- 사용자 최종 확인 결과 또는 수정 요청 내용

## AI 기능 포함 시 PM/Architect 체크리스트

PM은 명세 작성 시 요청이 AI 기능을 포함하는지 판단하고, Architect는 PM 판단과 명세를 바탕으로 설계에 반영한다. 요청이 AI 기능을 포함하면 PM과 Architect는 아래 항목을 고려한다:

- 합성 데이터 생성
- 모델/프롬프트 반복을 위한 오프라인 신뢰성 반복
- 평가 데이터셋과 수용 기준
- 온라인 서빙 또는 추론 경로
- 사람 승인 또는 피드백 반복
- 모니터링 신호와 실패 처리

요청이나 컨텍스트가 데이터 플라이휠을 암시하면 PM 명세에는 데이터 수집과 라벨/승인 기준을, Architect 설계에는 학습/검증 분리와 배포 경계를, Task Plan에는 피드백 수집과 재학습 시작 조건을 포함한다.
