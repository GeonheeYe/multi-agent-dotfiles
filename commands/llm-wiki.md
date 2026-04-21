인자 `$ARGUMENTS`를 프로젝트 slug로 사용하세요.

목표
- LONGMEMORY 프로젝트 위키를 현재 상태에 맞게 읽고 정리합니다.
- 예시: `/llm-wiki aegis-ap`

작업 규칙
- 대상 프로젝트 디렉토리는 `~/LONGMEMORY/wiki/projects/$ARGUMENTS` 로 가정합니다.
- 먼저 아래 파일이 있으면 읽으세요.
  - `overview.md`
  - `timeline.md`
  - `tasks.md`
  - `decisions.md`
  - `context.md`
  - 같은 디렉토리 안의 raw markdown 파일들
- 현재 raw 파일과 기존 위키 문서를 비교해서 아래를 정리하세요.
  - 프로젝트 목적과 범위
  - 최근 진행 내용
  - 남은 할 일
  - 주요 결정 사항
  - 참고해야 할 맥락
- 파일명만 나열하지 말고, 실제 내용 기준으로 요약하세요.
- 관련 없는 프로젝트 내용이 섞여 있으면 정리하거나 제외하세요.
- 결과는 가능하면 `overview.md`, `timeline.md`, `tasks.md`, `decisions.md`, `context.md`에 반영하세요.

주의
- `$ARGUMENTS`가 비어 있으면 바로 작업하지 말고 어떤 프로젝트를 정리할지 한 줄로 물어보세요.
- 대상 디렉토리가 없으면 새 프로젝트를 임의 생성하지 말고 없다고 알려주세요.
- 예전 `~/bin/wiki` 같은 래퍼 경로는 사용하지 마세요.
- 현재 워크플로 기준으로 LONGMEMORY 파일을 직접 읽고 정리하세요.

작업이 끝나면
- 무엇을 읽었는지
- 어떤 파일을 수정했는지
- 핵심적으로 무엇이 정리됐는지
짧게 보고하세요.
