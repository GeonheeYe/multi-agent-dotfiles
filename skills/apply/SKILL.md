---
name: apply
description: 취업 지원폼 자동 작성 + Notion 기록. "/apply [URL]", "지원서 작성", "폼 채워줘" 요청에 사용. 사용자가 "기록해"라고 하면 Notion에 저장.
---

# Apply Skill

취업 지원폼 URL을 받아 이력서 PDF를 기반으로 폼을 자동으로 채운다.
사용자가 직접 제출한 후 "기록해"라고 하면 Notion 지원 현황 DB에 기록한다.

## 기본 정보

- 이름: 예건희 (성: 예, 이름: 건희)
- 한문이름: 芮乾熙
- 이메일: dprjsgml@gmail.com
- 전화번호: 010-4011-6851
- 우편번호: 12772
- 주소: 경기도 광주시 수레실길 217 (능평동)
- 상세주소: B동 2호
- 비상연락처: 010-2076-6851 (관계: 모)

- 학업성적 기본값: 3.96 / 4.5
- 전공성적 기본값: 4.07 / 4.5

- 입사가능일: 2026-05-04 (협의 가능)
- 이력서 PDF: `/Users/geonhee/Library/CloudStorage/GoogleDrive-dprjsgml@gmail.com/내 드라이브/취직관련/자소서 및 제출서류/2026/AI_Engineer_예건희_이력서.pdf`
- 포트폴리오 PDF: `/Users/geonhee/Library/CloudStorage/GoogleDrive-dprjsgml@gmail.com/내 드라이브/취직관련/자소서 및 제출서류/2026/AI_Engineer_예건희_포트폴리오.pdf`
- 증명사진: `/Users/geonhee/Library/CloudStorage/GoogleDrive-dprjsgml@gmail.com/내 드라이브/취직관련/사진34.jpg`
- 고등학교: 금곡고등학교 (부산, 2012.03 ~ 2015.02, 졸업)
- 대학교: 경상대학교 정보통신공학과 (2015.03 ~ 2019.02, 학사 졸업)
- 경력 요약:
  - 총 경력 4년 7개월
  - LIG Accuver (2023.07 ~ 현재): AI Engineer, LLM 기반 Text-to-SQL/RAG/추론 최적화 및 서비스 적용
  - (주)아이렘기술개발 (2021.07 ~ 2023.05): AI Engineer, 드론·위성 영상 기반 컴퓨터 비전 모델 연구개발 및 서비스화

## 자격증 등록번호

- 정보처리기사: 21201021593B (취득일: 2021.06.02, 발급기관: 한국산업인력공단)
- 컴퓨터활용능력 1급: 20-K9-047042 (취득일: 2020.06.12, 발급기관: 대한상공회의소)

## 컴퓨터 활용능력

- 언어 Python: 5년, 고급
- 언어 SQL: 1년, 입문

## 정보 위치 가이드

> SKILL.md = 고정 정보 (자주 안 바뀜) | Notion = 가변 정보 (자주 바뀌거나 내용이 긴 것)

| 항목 | 위치 |
|------|------|
| 이름/연락처/이메일 | SKILL.md 기본 정보 |
| 한문이름/입사가능일 | SKILL.md 기본 정보 |
| 이력서/포트폴리오/증명사진 경로 | SKILL.md 기본 정보 |
| 자격증 등록번호 | SKILL.md 자격증 등록번호 |
| 컴퓨터 활용능력 | SKILL.md 컴퓨터 활용능력 |
| 경력/프로젝트/학력/기술스택 | Notion 이력서 페이지 |
| 생년월일 | Notion 참고자료 페이지 |
| 주소/상세주소/비상연락처 | SKILL.md 기본 정보 |
| 직전연봉/희망연봉 | Notion 참고자료 페이지 |
| 병역사항 | Notion 참고자료 페이지 |
| 총학점/전공학점 | Notion 참고자료 페이지 |
| 담당업무/이직사유 | Notion 참고자료 페이지 |

## 이력서 참고 Notion 페이지

- **이력서 (경력/프로젝트/학력/기술스택)**: `https://www.notion.so/AI-Engineer-2de2489a0046808a897ad8243dbbf96e`
  - page_id: `2de2489a-0046-808a-897a-d8243dbbf96e`
- **참고자료 (생년월일/주소/연봉/병역/학점/담당업무/이직사유)**: `https://www.notion.so/3292489a004680f49c69c79af7031c43`
  - page_id: `3292489a-0046-80f4-9c69-c79af7031c43`

## 사전 조건 확인

1. 위 기본 정보 사용 (변경 필요 시 이 파일 수정)
2. Chrome remote debugging 실행 여부 확인:
   - 안 돼있으면 사용자에게 안내: "터미널에서 `chrome-debug` 실행 후 다시 시도해주세요."

## 입력 URL 유형 처리

### job-detail URL인 경우 (예: `toss.im/career/job-detail?job_id=...`)
1. `mcp__chrome-devtools__new_page`로 채용공고 페이지 열기
2. 페이지 로딩 후 `mcp__chrome-devtools__take_screenshot`으로 **채용공고 전체 캡처** (fullPage: true)
3. "지원하기" 버튼 찾아서 클릭 → 지원폼 URL로 이동
4. 이후 일반 폼 작성 프로세스 진행

### 지원폼 URL인 경우 (예: `toss.im/career/apply/...`)
바로 폼 작성 프로세스 진행

## 폼 작성 프로세스

### 1단계: 페이지 열기 및 분석
- `mcp__chrome-devtools__new_page`로 URL 열기
- `mcp__chrome-devtools__take_snapshot`으로 폼 구조 파악
- 필드 목록 확인: 이름, 이메일, 전화번호, 경력, 자기소개서 질문 등

### 2단계: 이력서 정보 읽기
- `mcp__notion-personal__API-get-block-children`으로 Notion 이력서 페이지 읽기 (page_id: `2de2489a-0046-808a-897a-d8243dbbf96e`)
- 필요 시 참고자료 페이지도 읽기 (page_id: `3292489a-0046-80f4-9c69-c79af7031c43`)
- 추출 항목:
  - 기본 정보 (이름, 연락처, 생년월일, 주소, 비상연락처)
  - 경력 (회사명, 직무, 기간, 재직 여부, 이직사유)
  - 총 경력 기간
  - 기술 스택
  - 프로젝트 경험
  - 희망연봉 / 직전연봉
  - 군 복무 정보

### 3단계: 자기소개서 답변 생성
- 폼에서 자기소개서/에세이 질문 필드 감지
- 각 질문에 대해 PDF 이력서 내용 기반으로 답변 생성
- 글자 수 제한이 있으면 해당 제한에 맞게 작성

### 4단계: 필드 채우기
- `mcp__chrome-devtools__fill`로 텍스트 필드 입력
- `mcp__chrome-devtools__click`으로 라디오/체크박스/드롭다운 선택
- `mcp__chrome-devtools__upload_file`로 이력서 PDF 업로드 (포트폴리오 필드 있으면 포트폴리오도 업로드)
- 각 섹션 채운 후 `mcp__chrome-devtools__take_snapshot`으로 상태 확인
- **대략적으로 채워도 됨**: 사용자가 직접 수정할 예정이므로 빠르게 채우는 것이 우선
- React combobox(회사명 검색 등) 선택 실패 시 스킵하고 메모만 남길 것 (반복 시도 금지)

### 5단계: 검토 요청
- `mcp__chrome-devtools__take_screenshot`으로 전체 화면 캡처
- 사용자에게 보여주며 검토 요청: "작성 완료했어요. 확인 후 직접 제출해주세요."
- **여기서 멈춤** — 제출은 사용자가 직접

## Notion 기록 ("기록해" 트리거)

사용자가 "기록해", "노션에 기록", "저장해" 등을 입력하면 실행.

### 기록할 정보 준비
- 회사명: 폼 URL 또는 페이지 제목에서 추출
- 직무: 폼 페이지에서 확인한 포지션명
- 지원일: 오늘 날짜 (YYYY-MM-DD)
- 전형 단계: "서류 준비"
- 자기소개서: 작성한 질문 + 답변 전체
- 채용공고: job-detail URL이 있었다면 해당 페이지 내용 포함

### 채용공고 내용 수집 (job-detail URL이 있었던 경우)
1. **B안 우선 (스크린샷)**: job-detail 페이지 fullPage 스크린샷을 `/tmp/job_capture.png`에 저장해두고, Notion 페이지 본문에 이미지로 첨부 시도
2. **실패 시 A안 (텍스트)**: `mcp__chrome-devtools__take_snapshot`으로 job-detail 페이지 텍스트 추출 → Notion 본문 "## 채용공고" 섹션에 텍스트로 저장

### Notion DB에 페이지 생성
- DB: collection://4e57fc87-ebfe-41d8-9070-e072dc23006c
- Notion DB 페이지를 생성한 뒤, **반드시 페이지 본문에도 내용 추가**
- properties:
  ```
  회사명: [회사명] (title)
  직무: [포지션명] (text)
  지원일: [오늘 날짜] (date)
  전형 단계: "서류 준비" (select)
  ```
- 페이지 본문 구성:
  ```
  ## 채용공고
  [스크린샷 이미지 또는 텍스트 추출 내용]

  ## 자기소개서
  [질문별 답변 전체]
  ```
- `메모` 속성은 보조 요약용으로만 사용하고, **자기소개서/채용공고 원문은 페이지 본문에 정리하는 것을 기본값으로 함**
- 본문 추가가 실패한 경우에만 임시로 `메모` 속성에 전체 내용을 넣고, 사용자에게 본문 저장 실패를 명시할 것

## 주의사항
- 폼마다 구조가 다르므로 snapshot 기반으로 동적으로 필드 파악
- combobox/select 요소는 fill 후 드롭다운 옵션 클릭 필요
- spinbutton(날짜)은 fill로 직접 입력
- 파일 업로드는 upload_file 도구 사용
- 필드 채우다 오류 나면 evaluate_script로 우회 시도
