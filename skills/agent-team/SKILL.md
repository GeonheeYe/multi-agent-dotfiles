---
name: agent-team
description: 사용자가 $agent-team을 명시적으로 호출해 AI 기능 기획, 구현, 검토를 역할 기반으로 진행하려 할 때 사용한다.
---

# 에이전트 팀

## 스킬 목적과 실행 범위

`$agent-team`은 AI 기능 개발을 PM, Domain Expert, Architect, Developer, Reviewer 다섯 역할로 나눠 진행한다. Root orchestrator는 실행 준비, `run-state.json` 실행 상태, 산출물 파일, `stage gate`, `handoff`를 관리하고, PM은 사용자 인터뷰와 기능 명세를 담당한다.

이 스킬은 명시 호출 전용이다. 사용자가 `$agent-team`을 호출하지 않았다면 실행하지 않는다.

용어 표기는 아래를 기준으로 통일한다:

| 표준 용어 | 의미 |
| --- | --- |
| Root orchestrator | `run-state.json` 실행 상태, 산출물, 역할 전환을 관리하는 중앙 실행자. 도메인 판단이나 코드 리뷰를 직접 수행하지 않는다. |
| `sub-agent` | `auto_split`에서 역할별로 분리 실행되는 에이전트 |
| `stage gate` | Root orchestrator가 단계 전환 전에 수행하는 산출물 존재 여부, 최소 형식, `run-state.json` 갱신 가능성 검증 |
| Domain Expert Gateway | Domain Expert가 수행하는 도메인 유효성 검토. 결과는 `Approved`, `Revise`, `Blocked` 중 하나다. |
| `handoff` | 다음 역할에 넘기는 입력 파일, 출력 파일, 제약, 관련 `last_decision`, `blocked_reason` 후보, `stage gate` 실패 정보 |
| `briefs/<role>.md` | Root orchestrator가 역할별 `sub-agent`에 전달하는 작업 지시서 |
| 산출물 | `00-pm-interview.md`, `01-pm-spec.md`부터 `09-final-report.md`까지의 결과 파일 |

## 전체 워크플로우 불변 규칙

- 흐름은 순차 진행과 제한된 반복이다.
- 기본 실행 모드는 `auto_split`이다. `auto_split`은 역할별 `sub-agent`를 순차 실행하는 모드다.
- `sub-agent` 도구를 사용할 수 없으면 `single_session`으로 전환해 같은 대화 안에서 역할 라벨로 순차 수행한다.
- 병렬 실행은 하지 않는다. `sub-agent`를 쓰더라도 한 번에 한 역할만 실행한다.
- Root orchestrator는 PM 역할을 시작하기 전에 실행 위치, `mode`, `run-id`, `execution_mode`, 생성한 초기 파일만 `00-run-setup.md`에 기록한다.
- Root orchestrator는 프로젝트 의미, 목표, 주요 사용자, 문제 정의를 정리하지 않는다. 이 내용은 PM 인터뷰 책임이다.
- 주요 사용자, 해결하려는 일/결정, 입력 데이터, 기대 출력, 성공 기준, 기술 방향/플랫폼 제약/선호는 PM이 사용자 인터뷰에서 확인한다.
- Root orchestrator는 PM 인터뷰 질문을 직접 만들지 않는다. `auto_split`에서 PM이 사용자 입력을 필요로 하면 PM이 작성한 질문을 Root orchestrator가 그대로 전달하고, 답변을 PM에게 돌려준다.
- PM은 한 번에 한 가지씩 질문하고, 확인한 답변을 `00-pm-interview.md`와 `01-pm-spec.md`에 반영한다.
- 현재 대화에 이미 PM 인터뷰에 해당하는 내용이 충분히 있으면, PM이 그 내용을 `00-pm-interview.md`에 “PM 인터뷰 완료 기록”으로 정리하고 이를 입력으로 명세를 작성할 수 있다.
- `briefs/pm.md`는 초기 파일 생성과 컨텍스트 로드가 끝나면 생성한다. PM은 `00-run-setup.md`, `00-context.md`, 필요 시 기존 `00-pm-interview.md`를 입력으로 인터뷰와 명세 작성을 수행한다.
- Root orchestrator의 상태 갱신, 분기, 반복 한도, `stage gate` 책임은 `references/workflow-runtime.md`를 따른다.
- 프로젝트 주제나 초기 목표가 없어도 실행 디렉터리는 만들 수 있다. 이 경우 `run-id`는 `YYYY-MM-DD-agent-team` 형식으로 만들고, 프로젝트 의미와 목표는 PM 인터뷰에서 확인한다.
- 구현 흐름이라면 수정할 대상 저장소/프로젝트의 절대 경로 또는 현재 작업 디렉터리를 확인한다. 기획/명세만 진행한다면 산출물을 저장할 기준 디렉터리를 확인한다.
- 실행 산출물은 기본적으로 `<선택한 저장 위치>/docs/agent-team/<run-id>/`에 저장한다. 구현 흐름에서는 대상 저장소 루트를 선택한 저장 위치로 사용하고, 기획/명세만 진행하고 프로젝트 저장소가 없으면 사용자가 지정한 저장 위치를 사용한다.
- 사용자에게 묻는 경우는 실행 시작 정보 누락, PM이 작성한 인터뷰 질문 전달, 컨텍스트 로드 실패 후 계속 진행 확인, Domain Expert Gateway `Blocked`, 재시도 한도 초과, `user_final_confirmation`으로 제한한다.
- Git 커밋은 자동으로 하지 않는다. 대상이 Git 저장소이고 사용자가 승인한 경우에만 커밋한다.
- 공통 스킬 지침은 특정 도메인이나 기술 스택을 고정하지 않는다. 프로젝트별 요구사항은 실행 작업 지시서, 산출물, 가정에만 넣는다.
- 문장은 한글 중심으로 쓴다. 단, 역할명, 열거값, 파일명, 경로, JSON 키, 단계 값 같은 실행 식별자는 그대로 둔다.

## Root orchestrator가 읽는 참고 파일

관련 단계에서 필요한 파일만 읽는다. “필요한 파일”은 현재 단계의 입력, 출력 형식, 상태 전환 규칙을 판단하는 데 직접 쓰이는 파일이다:

- 실행 시작/재개, `run-state.json` 상태 전환, `stage gate`, Domain Expert Gateway 결과 처리 규칙: `references/workflow-runtime.md`
- 실행 디렉터리, 산출물 목록, 출력 규칙, 가정 목록, AI 기능 체크리스트: `references/artifacts.md`
- 역할 프롬프트:
  - PM: `references/roles/pm.md`
  - Domain Expert: `references/roles/domain-expert.md`
  - Architect: `references/roles/architect.md`
  - Developer: `references/roles/developer.md`
  - Reviewer: `references/roles/reviewer.md`

## 실행 전 필수 확인

1. 실행 위치와 `mode`를 확인한다.
   - 구현 흐름: 코드나 설정을 수정할 대상 저장소/프로젝트 경로가 절대 경로이거나 현재 작업 디렉터리 기준으로 해석 가능한 상대 경로여야 한다. 이 경우 `run-state.json`의 `mode`는 `implementation`으로 초기화한다.
   - 기획/명세 전용: 산출물만 저장할 기준 디렉터리가 절대 경로이거나 현재 작업 디렉터리 기준으로 해석 가능한 상대 경로여야 한다. 이 경우 `run-state.json`의 `mode`는 `planning`으로 초기화한다. `planning` 모드에서는 Developer/Reviewer 단계가 코드 변경 없이 산출물 작성에 한정된다.
2. 기존 실행을 이어간다면 `<선택한 저장 위치>/docs/agent-team/<run-id>/run-state.json`을 읽고 `references/workflow-runtime.md`를 따른다.
3. 새 실행이면 사용자가 명시한 주제어가 있을 때만 `YYYY-MM-DD-topic-slug` 형식으로 실행 ID를 만든다. 주제어가 없으면 `YYYY-MM-DD-agent-team` 형식으로 만들고, 프로젝트 의미와 목표는 PM 인터뷰에서 확인한다. 중복되면 `-2`, `-3`을 붙인다.
4. 새 실행이면 `run-state.json`, `00-run-setup.md`, `00-context.md`, `00-pm-interview.md`, `assumptions.md`, `briefs/`를 초기화한다. 기존 실행이면 `run-state.json`을 로드한다.
5. `$llm-wiki <keyword>`, `wiki-<keyword>`, `컨텍스트 불러와`가 있으면 PM 명세 전에 컨텍스트를 로드한다.
   - 현재 세션에서 `llm-wiki` 스킬을 읽고 실행할 수 있으면 그 절차를 따른다.
   - 성공하면 요약과 참고 파일을 `00-context.md`에 쓴다.
   - `llm-wiki`를 사용할 수 없거나 매칭 실패하면 확인한 출처와 실패 내용을 `00-context.md`에 기록하고 계속 진행할지 묻는다.
   - 별도 컨텍스트 요청이 없으면 `00-context.md`에 `컨텍스트 없음`과 요청 요약을 쓴다.

## 역할 실행 방식과 단계 전환

실행 디렉터리 준비, 컨텍스트 처리, 상태 초기화, 역할별 작업 지시서 생성이 끝난 뒤 실행한다. `auto_split`/`single_session` 선택, 재개 처리, `stage gate`, `run-state.json` 갱신 방식은 `references/workflow-runtime.md`를 따른다.

## auto_split handoff 규칙

- `briefs/<role>.md`의 필수 입력 항목은 `references/artifacts.md`를 따른다.
- `briefs/<role>.md` 형식은 `references/handoff-template.md`를 따른다. 사람에게 필요한 작업 지시는 상단에 두고, 실행 추적용 값은 하단 `System Handoff`에 둔다.
- `briefs/pm.md`는 초기 파일 생성과 컨텍스트 로드 후 만든다. PM에게 사용자 인터뷰와 `01-pm-spec.md` 작성을 맡기고, Root orchestrator는 `00-run-setup.md`, `00-context.md`, 기존 `00-pm-interview.md`가 있으면 그 경로를 입력으로 넘긴다.
- 역할은 자기 역할 범위의 산출물만 작성한다. 역할 실행이 끝나면 Root orchestrator가 `run-state.json`을 갱신할 수 있도록 완료한 산출물 경로, 제안하는 `next_stage`, `blocked_reason` 후보, 추가/변경한 가정 ID를 짧게 보고한다.

## Root orchestrator 노출 기준

초기 파일 생성 단계에서 Root orchestrator는 실행 위치와 mode처럼 파일 생성에 필요한 값만 확인한다. PM 단계에서는 PM이 사용자 인터뷰를 담당하며, `auto_split`에서 PM이 직접 질문을 표시할 수 없으면 Root orchestrator가 PM 질문을 그대로 전달한다. 그 외에는 설정, 단계 전환, `Blocked` 상태 또는 `blocked_reason`, 산출물 경로, `user_final_confirmation`을 알려야 할 때만 드러난다.

각 역할은 자기 책임 범위 안에서 명령 실행, 파일 읽기, 웹 검증을 수행할 수 있다. 명령이나 외부 검증을 실행했다면 명령/출처, 성공 또는 실패 결과, 그 결과가 산출물 판단에 준 영향을 해당 역할 산출물에 기록한다.

## 역할별 책임과 주요 산출물

| 역할 | 책임 | 주요 산출물 |
| --- | --- | --- |
| PM | 사용자 인터뷰를 통해 요구사항을 정리하고 검토 가능한 기능 명세로 구조화 | `00-pm-interview.md`, `01-pm-spec.md` |
| Domain Expert | Domain Expert Gateway에서 도메인 유효성 판단 | `02/04/08-expert-gateway-*.md` |
| Architect | 시스템 설계와 순서 있는 Task Plan | `03-architect-design.md`, `05-work-plan.md` |
| Developer | 확정된 Task Plan 기반 구현 | `06-developer-implementation.md` |
| Reviewer | 검증과 발견 이슈 | `07-reviewer-verification.md` |
| Root orchestrator | `user_final_confirmation`과 최종 보고 | `09-final-report.md` |

Domain Expert는 코드 리뷰어가 아니다. Domain Expert는 도메인 용어, KPI, 데이터 열, 라벨 정의, 업무 제약, 미해결 가정이 다음 단계에서 잘못된 설계나 구현을 만들지 않을 정도로 구체적이고 검증 가능한지 판단한다. 코드 스타일, 테스트 구조, 구현 품질은 Reviewer와 Developer의 책임이다.

## 사용자에게 보여줄 시작 안내

필수 사전 확인과 실행 준비가 끝나고 PM 인터뷰를 시작하기 전에 아래를 보여준다:

### 에이전트 팀

- 실행 방식: <auto_split: sub-agent 순차 실행 / single_session: 역할 라벨 순차 실행>
- 실행 디렉터리: <선택한 저장 위치>/docs/agent-team/<run-id>/
- 컨텍스트 상태: <없음 또는 "{키워드} wiki 로드 완료" 또는 "{키워드} wiki 로드 실패">
- 재개 상태: <새 실행 또는 "{run-id}에서 {stage} 다음 단계부터 재개">
- execution mode: <auto_split / single_session>
- 사용자 표시 단계: PM 인터뷰 시작
- `current_stage`: <run-state.json에 기록할 영문 단계 값>

## 단계별 실행 순서

| 사용자에게 보이는 단계 | `run-state.json` 단계 값 |
| --- | --- |
| 역할 지정 | `initialized` |
| 실행 디렉터리 준비 | `initialized` |
| 컨텍스트 로드 | `context_load` |
| 역할별 작업 지시서 생성 | `briefs_created` |
| PM 인터뷰 및 명세 | `pm_spec` |
| Domain Expert Gateway 1: 명세 | `expert_gateway_spec` |
| Architect design | `architect_design` |
| Domain Expert Gateway 2: 설계 | `expert_gateway_design` |
| Architect task plan | `work_plan` |
| Developer implementation | `developer_implementation` |
| Reviewer verification | `reviewer_verification` |
| Developer fix -> Reviewer re-verification 반복 | `developer_implementation` 또는 `reviewer_verification` |
| Domain Expert Gateway 3: 최종 | `expert_gateway_final` |
| 사용자 최종 확인 | `user_final_confirmation` |
| 최종 보고 | `final_report` |

각 단계가 끝나면 대화에는 요약과 산출물 경로만 보여준다. 전체 내용은 실행 디렉터리에 저장한다.
