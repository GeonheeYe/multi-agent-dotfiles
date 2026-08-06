# AI 플랫폼 회의 프로젝트 문맥 설계

## 목적

Notion의 `AI 플랫폼 > 회의록`에 누적된 합의와 용어를 meeting skill이 재사용할 수 있는 프로젝트 문맥으로 만든다. 회의별 세부 기록을 복제하지 않고, 반복해서 필요한 역할·범위·기술 용어·STT 교정 규칙만 저장한다.

## 파일 구조

- `skills/meeting/projects/ai-platform/config.md`: 프로젝트 범위, 조직 역할, 확인된 인물, Notion 기준 문서, 회의록 작성 규칙
- `skills/meeting/projects/ai-platform/terms.md`: 확정된 기술 용어, 확정된 STT 교정 패턴, 확인이 필요한 표현

## 분류 원칙

1. 여러 회의록에서 일관되거나 사용자가 직접 확인한 내용만 확정 정보로 기록한다.
2. 오인식 가능성 또는 의미가 여러 개인 표현은 `확인 필요 용어`에 원문·후보·근거·상태를 남긴다.
3. `확인 필요 용어`는 자동 STT 교정 패턴에 넣지 않는다.
4. LIG Accuver는 PoC 주관·리드 및 고객 대응, LIG System은 고객 대면 없이 AI 플랫폼·기술 구현 지원으로 구분한다.
5. 사람의 직급·역할은 확인된 값만 기록하고 추정하지 않는다.

## 포함 범위

- RCA, Rule-based RCA, CDR/XDR, XDB, KPI, Attach 성공률
- Isolation Forest, Feature Engineering, MLflow, MLOps
- Dify, Agent Builder, Workflow, LLM 보고서
- Ontology, Semantic Layer, Neo4j, Cypher
- GPU, MIG, Kubernetes, Cloudera Data Platform(CDP)

## 제외 범위

- 회의 녹취 전문
- 회의마다 달라질 수 있는 미확정 일정
- 출처가 없는 사람·직급·제품명 추정
- 잘못된 자동 교정을 유발할 수 있는 유력 후보 표기

## 검증 기준

- 두 파일의 frontmatter에 `type: project`가 있다.
- 조직 역할과 이주승 수석 표기가 사용자 확인 내용과 일치한다.
- `확인 필요 용어`와 `STT 오인식 교정 패턴`이 분리되어 있다.
- 애매한 후보가 확정 교정표에 포함되지 않는다.
- 변경 범위는 새 프로젝트 디렉터리와 본 설계·계획 문서로 제한한다.

