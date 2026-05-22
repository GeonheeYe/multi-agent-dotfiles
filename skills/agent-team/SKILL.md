---
name: agent-team
description: 사용자가 $agent-team을 명시적으로 호출해 PM, Domain Expert, Architect, Developer, Reviewer 역할 기반으로 AI 기능 기획, 구현, 검토를 진행할 때 사용한다.
---

# 에이전트 팀

## 개요

`$agent-team`은 AI 기능 개발을 PM, Domain Expert, Architect, Developer, Reviewer 다섯 역할로 통제해 진행한다. 사용자와 직접 요구사항을 주고받는 역할은 PM이고, Root orchestrator는 뒤에서 state, artifacts, gateway, handoff를 관리한다.

이 스킬은 명시 호출 전용이다. 사용자가 `$agent-team`을 호출하지 않았다면 실행하지 않는다.

## 핵심 규칙

- 흐름은 순차 진행과 제한된 반복이다.
- 기본 순서: PM 상세 사용자 시나리오 인터뷰 -> PM 명세 확정(문서 작성) -> Domain Expert Gateway -> Architect design -> Domain Expert Gateway -> Architect task plan -> Developer implementation -> Reviewer verification -> Domain Expert Gateway -> 사용자 확인.
- 실행 모드는 `auto_split` 기본값이다.
- `auto_split`에서는 Root orchestrator가 각 역할별 `briefs/<role>.md`를 handoff 패킷으로 생성해 역할 서브에이전트로 별도 분리 실행한다.
- 서브에이전트를 사용할 수 없으면 같은 대화 안에서 `## PM`, `## Domain Expert`, `## Architect`, `## Developer`, `## Reviewer` 라벨로 순차 수행한다.
- 병렬 실행은 하지 않는다. 서브에이전트를 쓰더라도 한 번에 한 역할만 실행한다.
- PM은 `01-pm-spec.md`를 쓰기 전에 상세 사용자 시나리오 인터뷰를 진행한다.
- Root orchestrator는 `run-state.json`, artifacts, gateway 결정, retry count, `Blocked` 입력 요청, 최종 사용자 확인을 관리한다.
- 프로젝트 주제나 목표가 없으면 run 디렉터리를 만들기 전에 묻는다.
- 구현 흐름이라면 대상 저장소/프로젝트 위치를 확인한다. 기획/명세만 진행한다면 artifacts 저장 위치를 확인한다.
- 실행 산출물은 기본적으로 `docs/agent-team/<run-id>/`에 저장한다. 기획/명세만 진행하고 프로젝트 저장소가 없으면 사용자가 지정한 저장 위치를 사용한다.
- 사용자에게 묻는 경우는 사전 확인 정보 누락, 컨텍스트 로드 실패 후 계속 진행 확인, 게이트웨이 `Blocked`, 재시도 한도 초과, 최종 사용자 확인으로 제한한다.
- Git 커밋은 자동으로 하지 않는다. 대상이 Git 저장소이고 사용자가 승인한 경우에만 커밋한다.
- 공통 스킬 지침은 특정 도메인이나 기술 스택을 고정하지 않는다. 프로젝트별 요구사항은 실행 작업 지시서, 산출물, 가정에만 넣는다.
- 문장은 한글 중심으로 쓴다. 단, 역할명, 열거값, 파일명, 경로, JSON 키, 단계 값 같은 실행 식별자는 그대로 둔다.

## 필수 참고 파일

관련 단계에서 필요한 파일만 읽는다:

- 실행 시점, state, gateway, resume, 보조 도구 규칙: `references/workflow-runtime.md`
- 실행 디렉터리, 산출물 목록, 출력 규칙, 가정 목록, AI 기능 체크리스트: `references/artifacts.md`
- 역할 프롬프트:
  - PM: `references/agents/pm/agent.md`
  - Domain Expert: `references/agents/domain-expert/agent.md`
  - Architect: `references/agents/architect/agent.md`
  - Developer: `references/agents/developer/agent.md`
  - Reviewer: `references/agents/reviewer/agent.md`

## 사전 확인

1. `$agent-team` 요청에서 프로젝트 주제와 목표를 확인한다.
   - 둘 다 없으면 run 디렉터리를 만들거나 역할을 시작하기 전에 묻는다.
   - 주제는 있지만 목표가 모호하면 PM 상세 시나리오 인터뷰에서 구체화한다.
2. 위치 정보를 확인한다.
   - 구현 흐름: 대상 저장소/프로젝트 위치가 명확해야 한다.
   - 기획/명세 전용: 산출물 저장 위치가 명확해야 한다.
3. 기존 실행을 이어간다면 `docs/agent-team/<run-id>/run-state.json`을 읽고 `references/workflow-runtime.md`를 따른다.
4. 새 실행이면 `YYYY-MM-DD-topic-slug` 형식으로 실행 ID를 만든다. 중복되면 `-2`, `-3`을 붙인다.
5. `run-state.json`을 초기화하거나 로드한다.
6. `$llm-wiki <keyword>`, `wiki-<keyword>`, `컨텍스트 불러와`가 있으면 PM 명세 전에 컨텍스트를 로드한다.
   - 성공하면 `00-context.md`에 쓴다.
   - 실패하면 확인한 출처와 실패 내용을 `00-context.md`에 기록하고 계속 진행할지 묻는다.
   - 별도 컨텍스트 요청이 없으면 `00-context.md`에 `컨텍스트 없음`과 요청 요약을 쓴다.

## 실행 방식

실행 디렉터리 준비, 컨텍스트 처리, state 초기화, 역할별 작업 지시서 생성이 끝난 뒤 실행한다:

- [auto_split] 실행 가능한 환경이면 각 역할을 공통 역할 프롬프트와 `briefs/<role>.md`를 함께 넘겨 별도 서브에이전트로 실행한다.
- [single_session] 모드에서는 같은 대화 안에서 `## PM`, `## Domain Expert`, `## Architect`, `## Developer`, `## Reviewer` 라벨로 순차 수행한다.
- 단계 전환 전에 Root orchestrator는 다음 역할의 `briefs/<role>.md`를 갱신/재생성해서 handoff를 완성한다.
- 각 서브에이전트 완료 후 output 파일이 생성되면 `run-state.json`로 수신 검증한 뒤 다음 단계로 이동한다.
- 대체 실행에서도 같은 artifacts를 만들고, 같은 가정 목록을 갱신하며, 같은 gateway/state 규칙을 따른다.

## 자동 분리 실행 모드

`auto_split`이 활성화되면 Root orchestrator는 매 단계별로 분리 handoff를 만들고 전달한다.

- 실행 상태(`run-state.json`)의 기본 `execution_mode`는 `auto_split`다.
- 전달 handoff에는 아래가 들어간다:
  - 현재 단계와 다음 게이트웨이 목표
  - 사용자 목표 요약
  - 이전 게이트웨이 결정/필수 수정사항
  - `assumptions.md` 참조
  - 읽을 파일 목록과 출력 파일 경로
  - 제한 조건(범위/비범위/검증 임계치)
- handoff는 사용자가 `single_session`을 요청하지 않는 한 매 단계마다 새로 갱신한다.
- 역할은 자기 역할 범위만 작성하고 마지막에 `run-state.json` 갱신 포인트만 Root orchestrator에게 리턴한다.

## 에이전트 구조

Root orchestrator는 flow, state, gateway, `Blocked` 입력 요청, 보조 도구 사용, 최종 사용자 확인을 관리한다. PM, Domain Expert, Architect, Developer, Reviewer는 고정 서브에이전트이며 서로 직접 지시하지 않는다.

PM 단계는 사용자가 PM과 직접 대화하는 느낌이어야 한다. Root orchestrator는 설정, 단계 전환, 진행 차단 조건, artifacts 경로, 최종 확인을 알려야 할 때만 드러난다.

웹 검증기, 데이터 프로파일러, 보안 검사기, 벤치마크 실행기 같은 보조 도구는 선택 사항이다. 보조 도구는 고정 서브에이전트를 대체하지 않는다. 보조 도구 사용은 `references/workflow-runtime.md`에 따라 기록한다.

## 역할

| 역할 | 책임 | 주요 산출물 |
| --- | --- | --- |
| PM | 상세 사용자 시나리오 인터뷰와 기능 명세 | `01-pm-spec.md` |
| Domain Expert | 도메인 게이트웨이 승인 | `02/04/08-expert-gateway-*.md` |
| Architect | 시스템 설계와 순서 있는 Task Plan | `03-architect-design.md`, `05-work-plan.md` |
| Developer | 확정된 Task Plan 기반 구현 | `06-developer-implementation.md` |
| Reviewer | 검증과 발견 이슈 | `07-reviewer-verification.md` |

Domain Expert는 code reviewer가 아니다. 도메인 용어, KPI, 데이터 열, 라벨 정의, 업무 제약, 미해결 가정이 다음 단계의 근거로 충분한지 판단한다.

## 시작 출력

필수 사전 확인과 실행 준비가 끝나고 PM 인터뷰/명세 작업을 시작하기 전에 아래를 보여준다:

```markdown
## 에이전트 팀

| 에이전트 | 이 프로젝트에서 맡는 역할 | 사용자가 보게 될 산출물 |
| --- | --- | --- |
| PM | 상세 사용자 시나리오 인터뷰와 기능 명세 정의 | 페르소나, 시작 조건, 정상 흐름, 예외 사례, 실패 상황, 범위, 목표, 데이터 명세, 도메인 가정 후보/열린 질문 |
| Domain Expert | 단계별 도메인 유효성 검토 | `Approved`/`Revise`/`Blocked` 결정, 도메인 리스크, 도메인 가정 후보 검토 |
| Architect | 시스템 설계와 Task Plan 수립 | 아키텍처, 데이터/모델 흐름, 기술 스택 후보, 작업 분해 |
| Developer | 확정된 Task Plan 구현 | 명세와 계획에 연결된 코드/설정/문서/테스트 변경 |
| Reviewer | 구현 결과 검증 | 테스트/평가 결과, 발견 이슈, 남은 차이 |

- 실행 방식: <실제 서브에이전트 또는 라벨링된 순차 역할 수행>
- 실행 디렉터리: <저장 위치>/docs/agent-team/<run-id>/
- context state: <없음 또는 "{키워드} wiki 로드 완료" 또는 "{키워드} wiki 로드 실패">
- resume state: <새 실행 또는 "{run-id}에서 {stage} 다음 단계부터 재개">
- execution mode: <auto_split / single_session>
- 현재 단계: 역할 지정 완료, PM 상세 사용자 시나리오 인터뷰 시작
```

이어서 요약 흐름을 보여준다:

PM 상세 사용자 시나리오 인터뷰 -> PM 명세 확정(문서 작성) -> Domain Expert Gateway -> Architect design -> Domain Expert Gateway -> Architect task plan -> Developer implementation -> Reviewer verification -> Domain Expert Gateway -> 사용자 확인

## 기본 진행 순서

1. 역할 지정
2. 실행 디렉터리 준비
3. 컨텍스트 로드
4. 역할별 작업 지시서 생성
5. PM 상세 사용자 시나리오 인터뷰와 PM 명세
6. Domain Expert Gateway 1: 명세
7. Architect design
8. Domain Expert Gateway 2: 설계
9. Architect task plan
10. Developer implementation
11. Reviewer verification
12. 필요 시 Developer fix -> Reviewer re-verification 반복
13. Domain Expert Gateway 3: 최종
14. 사용자 최종 확인
15. 최종 보고

각 단계가 끝나면 대화에는 요약과 산출물 경로만 보여준다. 전체 내용은 run 디렉터리에 저장한다.
