---
name: llm-wiki
description: LONGMEMORY 프로젝트 위키를 읽어 현재 세션에 필요한 컨텍스트를 불러온다. 기본은 Ubuntu 원격 위키를 우선 사용하고, 실패할 때만 로컬 `~/LONGMEMORY`를 fallback으로 사용한다. "/llm-wiki XQbot", "wiki-aegis", "llm-wiki 사주" 같은 요청에 사용. 사용자가 프로젝트 컨텍스트를 불러달라고 하거나 wiki, 위키, 컨텍스트 로드를 언급하면 사용.
---

# LLM Wiki Context Loader

LONGMEMORY 프로젝트 위키를 읽어 현재 세션에 필요한 컨텍스트를 정리한다.

기본 경로
- Ubuntu 우선: `geonhee-ubuntu:/home/geonhee/LONGMEMORY/wiki/index.md`, `geonhee-ubuntu:/home/geonhee/LONGMEMORY/wiki/projects/<slug>/`
- fallback: 로컬 `~/LONGMEMORY/wiki/index.md`, `~/LONGMEMORY/wiki/projects/<slug>/`

## 실행 절차

**1단계: 키워드 추출**

입력에서 프로젝트 키워드를 추출한다.
- `/llm-wiki XQbot` → `XQbot`
- `wiki-aegis` → `aegis`
- `llm-wiki 오늘-뭐먹지` → `오늘`

인수 없이 호출되면 프로젝트 목록을 먼저 보여준다.

**2단계: 위키 파일 읽기**

대상 프로젝트를 찾은 뒤 아래 순서로 시도한다.
- 1) Ubuntu 원격 위키 (`geonhee-ubuntu:/home/geonhee/LONGMEMORY`)
- 2) Ubuntu에 연결 실패하거나 파일이 없으면 로컬 `~/LONGMEMORY` fallback

그 다음 아래 파일을 우선 읽는다.
- `overview.md`
- `context.md`
- `timeline.md`
- `tasks.md`
- `decisions.md`
- 필요하면 같은 디렉토리의 raw markdown 파일과 `summaries.md`

주의
- `~/bin/wiki`가 있으면 그것을 사용해도 되지만, 동작 기준은 **Ubuntu 우선 + 로컬 fallback** 이어야 한다.
- LONGMEMORY 원본은 `geonhee-ubuntu:/home/geonhee/LONGMEMORY`를 기본값으로 본다.
- Hermes가 `geonhee-ubuntu`에서 실행 중이고 `/home/geonhee/LONGMEMORY`가 있으면 SSH를 쓰지 말고 로컬 경로를 먼저 읽는다.
- 로컬 `~/LONGMEMORY`는 캐시나 미러가 있을 때만 fallback으로 사용한다.
- 단순히 로컬 위키가 없다는 이유만으로 먼저 실패 처리하지 않는다.

**3단계: 컨텍스트 적용 후 응답**

응답 형식 예시

```text
[llm-wiki] aegis-ap 컨텍스트 로드 완료.

- 현재 상태: ...
- 최근 진행: ...
- 다음 할 일: ...
```

파일명만 나열하지 말고, 실제 내용 기준으로 3~6줄 정도로 짧게 정리한다.

## 오류 처리

| 상황 | 대응 |
|------|------|
| Ubuntu 연결 실패 | 바로 실패하지 말고 로컬 LONGMEMORY fallback을 시도 |
| 키워드 미매칭 | 전체 프로젝트 목록 또는 가까운 후보를 보여주고 다시 선택 요청 |
| 여러 매칭 | 후보 목록을 짧게 보여주고 정확한 이름 요청 |
| context.md 없음 | 다른 위키 파일(overview, timeline, tasks 등) 기준으로 요약 시도 |
| 원격/로컬 모두 없음 | "Ubuntu에도 연결할 수 없고 로컬 LONGMEMORY도 없어 컨텍스트를 읽을 수 없습니다." |

## 사용 예시

| 입력 | 동작 |
|------|------|
| `/llm-wiki XQbot` | xqbot-paper 관련 위키 파일 로드 |
| `wiki-aegis` | aegis-ap 위키 로드 |
| `llm-wiki` | 전체 프로젝트 목록 출력 |
| `wiki-사주` | 사주팔자 위키 로드 |
