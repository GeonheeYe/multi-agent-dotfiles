---
name: llm-wiki
description: S20 LONGMEMORY에서 프로젝트 context.md를 가져와 현재 세션에 주입한다. "/llm-wiki XQbot", "wiki-aegis", "llm-wiki 사주" 같은 요청에 사용. 사용자가 프로젝트 컨텍스트를 불러달라고 하거나 wiki, 위키, 컨텍스트 로드를 언급하면 사용.
---

# LLM Wiki Context Loader

S20의 LONGMEMORY에서 `context.md`를 SCP로 가져와 현재 세션 컨텍스트로 주입한다.

## 실행 절차

**1단계: 키워드 추출**

입력에서 프로젝트 키워드를 추출한다.
- `/llm-wiki XQbot` → `XQbot`
- `wiki-aegis` → `aegis`
- `llm-wiki 오늘-뭐먹지` → `오늘`

인수 없이 호출 시 전체 목록을 반환한다.

**2단계: wiki.sh 실행**

```bash
~/bin/wiki <키워드>
```

- 퍼지 매칭으로 프로젝트를 찾아 `context.md`를 출력한다.
- 인수 없으면 전체 프로젝트 목록 출력.
- 여러 프로젝트 매칭 시 후보 목록 출력 → 사용자에게 선택 요청.

**3단계: 컨텍스트 적용 후 응답**

```
[llm-wiki] <project-name> 컨텍스트 로드 완료.

현재 상태: <context.md의 "현재 상태" 섹션 1-2줄 요약>

이어서 진행하려면 말씀해 주세요.
```

## 오류 처리

| 상황 | 대응 |
|------|------|
| S20 연결 실패 | "S20에 연결할 수 없습니다. VPN/네트워크를 확인해 주세요." |
| 키워드 미매칭 | 전체 프로젝트 목록 출력 후 선택 요청 |
| 여러 매칭 | 후보 목록 나열 후 선택 요청 |

## 사용 예시

| 입력 | 동작 |
|------|------|
| `/llm-wiki XQbot` | xqbot-paper context.md 로드 |
| `wiki-aegis` | aegis-ap context.md 로드 |
| `llm-wiki` | 전체 프로젝트 목록 출력 |
| `wiki-사주` | 사주팔자 context.md 로드 |
