# 에이전트 팀 산출물

이 파일은 실행 디렉터리 구조, 역할 작업 지시서, 출력 규칙, 가정 목록, AI 기능 체크리스트를 다룬다. 실행 시점 상태 전환, 게이트웨이 반복, 재개/재구성, 산출물 검증 기준은 `workflow-runtime.md`를 따른다.

## 실행 디렉터리

각 실행은 선택한 저장 위치 아래에 산출물을 쓴다:

```text
docs/agent-team/<run-id>/
├── run-state.json                # 실행 상태, 최종 산출물이 아님
├── 00-context.md                 # 로드한 컨텍스트 또는 컨텍스트 없음/실패 기록
├── assumptions.md                # 가정 목록
├── briefs/                       # 생성된 역할 작업 지시서, 최종 산출물이 아님
│   ├── pm.md
│   ├── domain-expert.md
│   ├── architect.md
│   ├── developer.md
│   └── reviewer.md
├── handoffs/                     # auto_split 전용 handoff 패킷, 최종 산출물이 아님
│   ├── auto-split-mode.md
├── 01-pm-spec.md
├── 02-expert-gateway-spec.md
├── 03-architect-design.md
├── 04-expert-gateway-design.md
├── 05-work-plan.md
├── 06-developer-implementation.md
├── 07-reviewer-verification.md
└── 08-expert-gateway-final.md
```

`briefs/<role>.md` 파일은 각 역할에 전달하는 생성 지시서다. `handoffs/auto-split-mode.md`는 `auto_split` 실행에서 handoff 전환 내역을 모아 저장한다. 둘 다 사용자에게 보여주는 최종 산출물이 아니다.

## 작업 지시서 입력

auto_split 모드 handoff 패킷 형식은 `references/handoff-template.md`를 따른다.

각 역할 작업 지시서에는 아래를 포함한다:

- 사용자 요청
- 저장소/프로젝트 위치
- 로드한 컨텍스트 또는 컨텍스트 실패 정보
- 공통 역할 프롬프트 경로
- 사용자 요청, 컨텍스트, 프로젝트 문서에서 확인한 프로젝트별 요구사항
- 현재 입력 산출물 경로
- 작성할 출력 산출물 경로
- `assumptions.md` 경로
- `run-state.json` 경로와 현재 단계
- 이전 게이트웨이 결정과 필수 수정사항

## 가정 목록

모든 가정은 `assumptions.md`에 유지한다. 단계별 산출물에는 해당 단계에서 추가되거나 바뀐 가정만 적고 가정 ID를 참조한다.

가정 목록 형식:

| ID | 단계 | 담당 | 가정 | 근거 | 틀렸을 때 리스크 | 검증 방법 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- |

상태 값:

- `open`: 아직 검증하지 않음
- `accepted`: 일단 받아들이고 진행
- `needs-validation`: 의존하기 전에 반드시 검증 필요
- `rejected`: 틀린 것으로 확인됨
- `resolved`: 검증되었거나 닫힘

가정을 본문에 숨기지 않는다. 가정 목록에 넣고 명세, 설계, 계획, 검토, 게이트웨이 메모에서 ID로 참조한다.

## 출력 규칙

각 단계가 끝나면 대화에는 짧은 요약과 산출물 경로만 보여준다. 전체 내용은 run 디렉터리에 저장한다.

사용자 최종 확인에는 아래를 포함한다:

- PM 명세 요약과 `01-pm-spec.md`
- 아키텍처 설계 요약과 `03-architect-design.md`
- Task Plan 요약과 `05-work-plan.md`
- Developer implementation 요약과 `06-developer-implementation.md`
- Reviewer verification 요약과 `07-reviewer-verification.md`
- 최종 Domain Expert 결정과 `08-expert-gateway-final.md`
- 주요 열린 가정과 `assumptions.md`
- 최종 확인 또는 수정 요청 여부 질문

최종 보고에는 아래를 포함한다:

- 무엇을 만들었거나 명세화했는지
- 주요 산출물 경로
- 테스트/평가 결과
- 남은 차이 또는 열린 가정
- 최종 Domain Expert 결정

## AI 기능 체크리스트

요청이 AI 기능을 포함하면 PM과 Architect는 아래 항목을 고려한다:

- 합성 데이터 생성
- 모델/프롬프트 반복을 위한 오프라인 신뢰성 반복
- 평가 데이터셋과 수용 기준
- 온라인 서빙 또는 추론 경로
- 사람 승인 또는 피드백 반복
- 모니터링 신호와 실패 처리

요청이나 컨텍스트가 데이터 플라이휠을 암시하면 데이터 수집, 라벨링 또는 승인, 학습/검증 분리, 평가 지표, 배포 경계, 피드백 수집, 재학습 시작 조건을 적절한 명세/설계/계획 산출물에 포함한다.
