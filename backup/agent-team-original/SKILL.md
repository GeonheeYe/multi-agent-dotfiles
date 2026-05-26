---
name: agent-team
description: 사용자가 $agent-team을 명시적으로 호출해 PM, Domain Expert, Architect, Developer, Reviewer 역할 기반으로 AI 기능 기획, 구현, 검토를 진행할 때 사용한다.
---

# 에이전트 팀

## 스킬 목적과 실행 범위

`$agent-team`은 AI 기능 개발을 PM, Domain Expert, Architect, Developer, Reviewer 다섯 역할로 나눠 진행한다. 사용자는 주로 PM과 요구사항을 주고받는 것처럼 대화하고, Root orchestrator는 뒤에서 `run-state.json` 실행 상태, 산출물 파일, `stage gate`, `handoff`를 관리한다.

이 스킬은 명시 호출 전용이다. 사용자가 `$agent-team`을 호출하지 않았다면 실행하지 않는다.

용어 표기는 아래를 기준으로 통일한다:

| 표준 용어 | 의미 |
| --- | --- |
| Root orchestrator | `run-state.json` 실행 상태, 산출물, 역할 전환을 관리하는 중앙 실행자. 도메인 판단이나 코드 리뷰를 직접 수행하지 않는다. |
| `sub-agent` | `auto_split`에서 역할별로 분리 실행되는 에이전트 |
| `stage gate` | Root orchestrator가 단계 전환 전에 수행하는 산출물 존재 여부, 최소 형식, `run-state.json` 갱신 가능성 검증 |
| Domain Expert Gateway | Domain Expert가 수행하는 도메인 유효성 검토. 결과는 `Approved`, `Revise`, `Blocked` 중 하나다. |
| `handoff` | 다음 역할에 넘기는 입력 파일, 출력 파일, 제약, 이전 결정, 실패 사유 정보 |
| `briefs/<role>.md` | Root orchestrator가 역할별 `sub-agent`에 전달하는 작업 지시서 |
| 산출물 | `01-pm-spec.md`부터 `09-final-report.md`까지의 결과 파일 |

## 전체 워크플로우 불변 규칙

- 흐름은 순차 진행과 제한된 반복이다.
- 기본 순서: PM 상세 사용자 시나리오 인터뷰 -> PM 명세 확정(문서 작성) -> Domain Expert Gateway -> Architect design -> Domain Expert Gateway -> Architect task plan -> Developer implementation -> Reviewer verification -> Domain Expert Gateway -> 사용자 확인 -> 최종 보고.
- 기본 실행 모드는 `auto_split`이다. `auto_split`은 역할별 `sub-agent`를 순차 실행하는 모드다.
- `sub-agent` 도구를 사용할 수 없으면 `single_session`으로 전환해 같은 대화 안에서 역할 라벨로 순차 수행한다.
- 병렬 실행은 하지 않는다. `sub-agent`를 쓰더라도 한 번에 한 역할만 실행한다.
- PM은 `01-pm-spec.md`를 쓰기 전에 상세 사용자 시나리오 인터뷰를 진행한다.
- Root orchestrator는 `run-state.json` 갱신, 산출물 경로/존재 확인, `stage gate`, Domain Expert 결정 결과 기록과 분기, 재시도 횟수 관리, `Blocked` 상태의 사용자 입력 요청, 최종 사용자 확인과 `09-final-report.md` 작성을 담당한다.
- 프로젝트 주제나 목표가 없으면 실행 디렉터리를 만들기 전에 한 번 묻는다. 주제가 있지만 목표가 추상적이면 PM 인터뷰에서 구체화하고, 실행 디렉터리는 만들 수 있다.
- 구현 흐름이라면 수정할 대상 저장소/프로젝트의 절대 경로 또는 현재 작업 디렉터리를 확인한다. 기획/명세만 진행한다면 산출물을 저장할 기준 디렉터리를 확인한다.
- 실행 산출물은 기본적으로 `<선택한 저장 위치>/docs/agent-team/<run-id>/`에 저장한다. 구현 흐름에서는 대상 저장소 루트를 선택한 저장 위치로 사용하고, 기획/명세만 진행하고 프로젝트 저장소가 없으면 사용자가 지정한 저장 위치를 사용한다.
- 사용자에게 묻는 경우는 사전 확인 정보 누락, 컨텍스트 로드 실패 후 계속 진행 확인, Domain Expert Gateway `Blocked`, 재시도 한도 초과, 최종 사용자 확인으로 제한한다.
- Git 커밋은 자동으로 하지 않는다. 대상이 Git 저장소이고 사용자가 승인한 경우에만 커밋한다.
- 공통 스킬 지침은 특정 도메인이나 기술 스택을 고정하지 않는다. 프로젝트별 요구사항은 실행 작업 지시서, 산출물, 가정에만 넣는다.
- 문장은 한글 중심으로 쓴다. 단, 역할명, 열거값, 파일명, 경로, JSON 키, 단계 값 같은 실행 식별자는 그대로 둔다.

## Root orchestrator가 읽는 참고 파일

관련 단계에서 필요한 파일만 읽는다. “필요한 파일”은 현재 단계의 입력, 출력 형식, 상태 전환 규칙을 판단하는 데 직접 쓰이는 파일이다:

- 실행 시작/재개, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리 규칙: `references/workflow-runtime.md`
- 실행 디렉터리, 산출물 목록, 출력 규칙, 가정 목록, AI 기능 체크리스트: `references/artifacts.md`
- 역할 프롬프트:
  - PM: `references/agents/pm/agent.md`
  - Domain Expert: `references/agents/domain-expert/agent.md`
  - Architect: `references/agents/architect/agent.md`
  - Developer: `references/agents/developer/agent.md`
  - Reviewer: `references/agents/reviewer/agent.md`

## 실행 전 필수 확인

1. `$agent-team` 요청에서 프로젝트 주제와 목표를 확인한다.
   - 둘 다 없으면 실행 디렉터리를 만들거나 역할을 시작하기 전에 묻는다.
   - 주제는 있지만 목표가 모호하면 PM 상세 시나리오 인터뷰에서 구체화한다.
2. 실행 위치를 확인한다.
   - 구현 흐름: 코드나 설정을 수정할 대상 저장소/프로젝트 경로가 절대 경로이거나 현재 작업 디렉터리 기준으로 해석 가능한 상대 경로여야 한다.
   - 기획/명세 전용: 산출물만 저장할 기준 디렉터리가 절대 경로이거나 현재 작업 디렉터리 기준으로 해석 가능한 상대 경로여야 한다.
3. 기존 실행을 이어간다면 `<선택한 저장 위치>/docs/agent-team/<run-id>/run-state.json`을 읽고 `references/workflow-runtime.md`를 따른다.
4. 새 실행이면 `YYYY-MM-DD-topic-slug` 형식으로 실행 ID를 만든다. 중복되면 `-2`, `-3`을 붙인다.
5. 새 실행이면 `run-state.json`, `00-context.md`, `assumptions.md`, `briefs/`를 초기화한다. 기존 실행이면 `run-state.json`을 로드한다.
6. `$llm-wiki <keyword>`, `wiki-<keyword>`, `컨텍스트 불러와`가 있으면 PM 명세 전에 컨텍스트를 로드한다.
   - 현재 세션에서 `llm-wiki` 스킬을 읽고 실행할 수 있으면 그 절차를 따른다.
   - 성공하면 요약과 참고 파일을 `00-context.md`에 쓴다.
   - `llm-wiki`를 사용할 수 없거나 매칭 실패하면 확인한 출처와 실패 내용을 `00-context.md`에 기록하고 계속 진행할지 묻는다.
   - 별도 컨텍스트 요청이 없으면 `00-context.md`에 `컨텍스트 없음`과 요청 요약을 쓴다.

## 역할 실행 방식과 단계 전환

실행 디렉터리 준비, 컨텍스트 처리, 상태 초기화, 역할별 작업 지시서 생성이 끝난 뒤 실행한다. `auto_split` 사용 가능 여부, 재개 처리, 단계 완료 후 `run-state.json` 갱신 방식은 `references/workflow-runtime.md`를 따른다:

- [auto_split] 각 역할을 공통 역할 프롬프트와 `briefs/<role>.md`를 함께 넘겨 별도 `sub-agent`로 실행한다.
- [single_session] 모드에서는 같은 대화 안에서 `## PM`, `## Domain Expert`, `## Architect`, `## Developer`, `## Reviewer` 라벨로 순차 수행한다.
- 단계 전환 전에 Root orchestrator는 `stage gate`를 수행하고 다음 역할의 `briefs/<role>.md`를 갱신/재생성한다. `briefs/<role>.md` 안에는 `handoff` 정보가 포함된다.
- 각 `sub-agent` 완료 후 출력 파일이 생성되면 `run-state.json`로 수신 검증한 뒤 다음 단계로 이동한다.
- `single_session`에서도 같은 산출물을 만들고, 같은 가정 목록을 갱신하며, 같은 `stage gate`/상태 규칙을 따른다.

## auto_split sub-agent 실행 규칙

`auto_split`이 활성화되면 Root orchestrator는 매 단계별로 다음 역할의 `briefs/<role>.md`를 만들고 전달한다.

- 실행 상태(`run-state.json`)의 기본 `execution_mode`는 `auto_split`다.
- `briefs/<role>.md`의 `handoff` 섹션에는 아래가 들어간다:
  - 현재 단계와 다음 Domain Expert Gateway 목표
  - 사용자 목표 요약
  - 이전 Domain Expert 결정/필수 수정사항
  - `assumptions.md` 참조
  - 읽을 파일 목록과 출력 파일 경로
  - 포함 범위, 제외 범위, 통과해야 할 `stage gate` 항목
- `auto_split`에서는 `briefs/<role>.md`의 `handoff` 섹션을 매 단계마다 새로 갱신한다.
- 역할은 자기 역할 범위의 산출물만 작성한다. 역할 실행이 끝나면 Root orchestrator가 상태를 갱신할 수 있도록 완료한 산출물 경로, 다음 단계 제안, 차단 사유, 추가/변경한 가정 ID를 짧게 보고한다.

## Root orchestrator와 고정 역할 구조

Root orchestrator는 실행 디렉터리 생성, `run-state.json` 갱신, `stage gate`, `briefs/<role>.md` 갱신, Domain Expert 결정 결과에 따른 분기, 재시도 횟수 관리, 사용자 입력 요청, 최종 보고 작성을 담당한다. PM, Domain Expert, Architect, Developer, Reviewer는 고정 역할이며 서로 직접 지시하지 않는다. 한 역할의 결과가 다음 역할에 필요하면 Root orchestrator가 `briefs/<role>.md`를 갱신해 전달한다.

PM 단계는 사용자가 PM과 직접 대화하는 느낌이어야 한다. Root orchestrator는 설정, 단계 전환, 진행 차단 조건, 산출물 경로, 최종 확인을 알려야 할 때만 드러난다.

각 역할은 자기 책임 범위 안에서 명령 실행, 파일 읽기, 웹 검증을 수행할 수 있다. 명령이나 외부 검증을 실행했다면 명령/출처, 성공 또는 실패 결과, 그 결과가 산출물 판단에 준 영향을 해당 역할 산출물에 기록한다.

## 역할별 책임과 주요 산출물

| 역할 | 책임 | 주요 산출물 |
| --- | --- | --- |
| PM | 상세 사용자 시나리오 인터뷰와 기능 명세 | `01-pm-spec.md` |
| Domain Expert | Domain Expert Gateway에서 도메인 유효성 판단 | `02/04/08-expert-gateway-*.md` |
| Architect | 시스템 설계와 순서 있는 Task Plan | `03-architect-design.md`, `05-work-plan.md` |
| Developer | 확정된 Task Plan 기반 구현 | `06-developer-implementation.md` |
| Reviewer | 검증과 발견 이슈 | `07-reviewer-verification.md` |
| Root orchestrator | 최종 사용자 확인과 최종 보고 | `09-final-report.md` |

Domain Expert는 코드 리뷰어가 아니다. Domain Expert는 도메인 용어, KPI, 데이터 열, 라벨 정의, 업무 제약, 미해결 가정이 다음 단계에서 잘못된 설계나 구현을 만들지 않을 정도로 구체적이고 검증 가능한지 판단한다. 코드 스타일, 테스트 구조, 구현 품질은 Reviewer와 Developer의 책임이다.

## 사용자에게 보여줄 시작 안내

필수 사전 확인과 실행 준비가 끝나고 PM 인터뷰/명세 작업을 시작하기 전에 아래를 보여준다:

### 에이전트 팀

| 에이전트 | 이 프로젝트에서 맡는 역할 | 사용자가 보게 될 산출물 |
| --- | --- | --- |
| PM | 상세 사용자 시나리오 인터뷰와 기능 명세 정의 | 페르소나, 시작 조건, 정상 흐름, 예외 사례, 실패 상황, 범위, 목표, 데이터 명세, 도메인 가정 후보/열린 질문 |
| Domain Expert | 단계별 도메인 유효성 검토 | `Approved`/`Revise`/`Blocked` 결정, 도메인 리스크, 도메인 가정 후보 검토 |
| Architect | 시스템 설계와 Task Plan 수립 | 아키텍처, 데이터/모델 흐름, 기술 스택 후보, 작업 분해 |
| Developer | 확정된 Task Plan 구현 | 명세와 계획에 연결된 코드/설정/문서/테스트 변경 |
| Reviewer | 구현 결과 검증 | 테스트/평가 결과, 발견 이슈, 남은 차이 |

- 실행 방식: <auto_split: sub-agent 순차 실행 / single_session: 역할 라벨 순차 실행>
- 실행 디렉터리: <선택한 저장 위치>/docs/agent-team/<run-id>/
- 컨텍스트 상태: <없음 또는 "{키워드} wiki 로드 완료" 또는 "{키워드} wiki 로드 실패">
- 재개 상태: <새 실행 또는 "{run-id}에서 {stage} 다음 단계부터 재개">
- execution mode: <auto_split / single_session>
- 현재 단계: 역할 지정 완료, PM 상세 사용자 시나리오 인터뷰 시작
- 상태 단계: <run-state.json의 영문 단계 값>

이어서 요약 흐름을 보여준다:

PM 상세 사용자 시나리오 인터뷰 -> PM 명세 확정(문서 작성) -> Domain Expert Gateway -> Architect design -> Domain Expert Gateway -> Architect task plan -> Developer implementation -> Reviewer verification -> Domain Expert Gateway -> 사용자 확인 -> 최종 보고

## 단계별 실행 순서

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
12. Reviewer가 수정 필요 이슈를 발견하면 Developer fix -> Reviewer re-verification 반복
13. Domain Expert Gateway 3: 최종
14. 사용자 최종 확인
15. 최종 보고

각 단계가 끝나면 대화에는 요약과 산출물 경로만 보여준다. 전체 내용은 실행 디렉터리에 저장한다.
