---
name: AEGIS-AP 프로젝트 용어
description: AEGIS-AP WiNG 기능 내재화 회의의 STT 교정 및 요약에 활용되는 고유명사, 기술 용어, 오인식 패턴
type: project
---

## 프로젝트명

- AEGIS-AP: 액세스망 관측/분석 솔루션 브랜드
- WiNG 기능 내재화: AEGIS-AP 내 AI 기능 적용 및 내재화 과제

## 기술 용어

- NeMo: NVIDIA NeMo. LLM/Agentic AI 개발 및 배포 관련 프레임워크/마이크로서비스 생태계
- NeMo Microservices: NeMo 기반 마이크로서비스
- Agent Toolkit: AI agent 기반 개발 및 평가에 활용할 도구 후보
- Data Flywheel: 데이터 생성, 학습, 평가, 피드백, 재학습을 반복해 성능을 개선하는 구조
- AI agent team: PM, Domain Expert, Architect, Developer, Reviewer 역할로 나누는 개발 방식
- PM: 문제 정의, 사용자 시나리오, 기능 범위, 데이터 spec 정의 담당
- Domain Expert: 도메인 가정, 제약, 검증 기준을 리뷰하고 gateway approval 제공
- Architect: 시스템 설계, 데이터 생성/학습/검증 흐름 설계, 작업 계획 수립 담당
- Developer: 설계 및 작업 계획 기반 구현 담당
- Reviewer: 구현 결과 검증 담당
- CDR: Call Detail Record 또는 통신 관측 상세 레코드. POC 입력 데이터 후보
- KPI: CDR 컬럼 또는 가공 지표 기반으로 계산되는 성능/상태 지표
- 합성 데이터: 정상 분포 생성 후 이상 패턴을 주입해 만드는 학습/검증용 데이터
- 이상탐지: 네트워크 KPI 또는 CDR 기반 이상 여부 판단
- 예측분석: 미래 시계열 또는 향후 KPI 이상 가능성 예측
- Threshold: 이상/critical 판단에 사용하는 임계값
- PR Curve: 임계값 설정과 성능 평가에 활용할 수 있는 Precision-Recall Curve
- Critical: 높은 위험도로 판단되어 문자/전화 등 알림 escalation이 필요한 상태
- Escalation: 미처리 또는 심각도 상승 시 관리자 알림 단계로 올리는 절차
- 재학습: 정기 또는 성능 하락/분포 변화 조건에 따라 모델을 다시 학습하는 과정
- Claude Code, Codex, Cursor: AI agent 기반 개발 실험에 사용할 수 있는 구독형 개발 도구
- AGENTS.md: Codex 등에서 프로젝트/역할/작업 규칙을 전달하는 지침 파일
- Skill/Profile: agent 역할과 실행 규칙을 재사용 가능하게 정의하는 방식
- X-Unified: AEGIS-AP/CP 확장 논의에서 언급된 상위 통합 관점의 이름
- ATAS: AEGIS-CP와 관련해 언급된 외부/고객사 맥락의 솔루션명
- AEGIS-CP: 코어망 관측/분석 솔루션 브랜드

## 회의록 작성 규칙

- AEGIS-AP 회의에서는 팀 공통 업무보다 AEGIS-AP WiNG 기능 내재화 관점의 문제 정의, 설계 결정, 액션 아이템을 우선 정리한다.
- 불명확한 도메인 용어는 추측해 확정하지 말고, 회의록에 "확인 필요"로 남긴다.
- CDR과 KPI의 관계, 고객사별 범위, 제품명/솔루션명은 혼동 가능성이 높으므로 가능한 한 원문 표현과 근거를 함께 남긴다.

## STT 오인식 교정 패턴

| STT 오인식 | 올바른 표기 | 비고 |
|------------|------------|------|
| 액체 분석 | 예측분석 | 과제명 |
| 이지스 에이피 / EGIS AP / EGCAP / ASAP | AEGIS-AP | 프로젝트명 |
| 윙 | WiNG | 기능 내재화 과제명 |
| 리모 / 니모 / 응모 | NeMo | NVIDIA NeMo |
| NEMO 마이크로 서비스 | NeMo Microservices | NVIDIA NeMo 용어 |
| Ancient Toolkit | Agent Toolkit | 도구명 |
| 데이터 플라웰 / 데이터 플라이어 / 데이터 플라웨이 | Data Flywheel | 워크플로우 용어 |
| 도민 엑스퍼트 / 고민 expert | Domain Expert | agent 역할 |
| 아키텍테이전트 | Architect agent | agent 역할 |
| 디벨로퍼 | Developer | agent 역할 |
| 리뷰어 | Reviewer | agent 역할 |
| 액세서마 / 액세스 랜 | 액세스망 / Access망 | AEGIS-AP 범위 |
| 의상탐지 / 의상치 / 의상신호 | 이상탐지 / 이상치 / 이상신호 | 분석 용어 |
| 인계값 / 환경값 / 트레이쉬로이드 / ThreatSold | Threshold / 임계값 | 판단 기준 |
| CTR | CDR | 데이터 용어, 문맥 확인 필요 |
| 칼럼 | 컬럼 | 데이터 컬럼 |
| Low 데이터 / No Data | Raw data / 로우 데이터 | 원천 데이터 문맥 |
| PR 커브 | PR Curve | 평가/임계값 설정 |
| 크리티컬 | Critical | 알림 심각도 |
| 에스컬레이션 | Escalation | 알림 단계 상승 |
| 서브 에이전트 / 서버 에이전트 | sub-agent | agent 팀 구성 |
| 통 파일 / 토넛파일 | .toml 파일 | 설정 파일 문맥, 확인 필요 |
| 스피드 | skill | Codex skill 문맥 |
| 프로파일 | profile | Hermes agent 등 역할 정의 방식 |
| 에이타스 | ATAS | 솔루션명 |

---
*마지막 업데이트: 2026-05-19 wing 내재화 회의*
