---
name: 팀 회의 누적 용어/교정 패턴
description: 매 팀 회의 종료 시 업데이트되는 고유명사, 기술 용어, STT 오인식 교정 패턴
type: project
---

## 프로젝트명

- VQML: ITU-T 표준화 및 라이선스 사업화 (시청자 MOS 수집)
- XTelLM: Base Private SLM 확보 및 Telco 특화 성능 개선
- NDR: 네트워크 보안 솔루션 (PoC, Graph 기반 데이터 전처리)
- AEGIS-AP: WiNG 기능 내재화 (통신 도메인 특화 embedding model)

## 기술 용어

- ITU-T, MOS, SLM, MLX (Apple Silicon 프레임워크)
- inspect (.eval 파일 분석 라이브러리)
- VAD (Voice Activity Detection)
- VESSL (ML 플랫폼)
- LIG Accuver (회사명)
- 퓨처랩
- NeMo (NVIDIA NeMo — LLM 훈련~Agentic AI 배포 올인원 프레임워크)
- NeMo Curator (데이터 전처리/정제 마이크로서비스)
- NeMo Skills (데이터생성→훈련→평가 파이프라인 오픈소스)
- AutoResearch (AI가 training.py를 반복 수정해 최적 학습 탐색하는 도구)
- BPB (Bits Per Byte — 언어모델 평가 지표)
- Qwen (중국 오픈소스 LLM 시리즈)
- GraphIDS (Graph 기반 네트워크 침입 탐지 baseline 프레임워크, NDR PoC)
- AI Dev team commons (팀 공통 AI 개발 컨텍스트 Git 저장소 — MCP·룰·스킬 포함)
- Aerial (NVIDIA Aerial — RAN/통신 시뮬레이션 및 합성 데이터 생성 플랫폼)
- NIM (NVIDIA Inference Microservices — 엔터프라이즈 서빙 라이선스, MS당 연 $4,500)
- NeMo Data Designer (NeMo의 특수 데이터셋 생성 툴)
- NeMo Guardrails (가드레일 — NeMo 생태계)
- Open Telco / OTEL Q&A (통신 도메인 평가 벤치마크)
- Telecom TS (통신 TS 데이터셋 — Q&A 중심 큐레이트 세트)
- PLCC / SRCC (VQML 평가 지표 — Pearson/Spearman 상관)
- Tier 1 / Tier 2 (VQML 표준화 모델 그레이드)
- VOC (Voice of Customer — 고객 품질 이슈 텍스트)
- Copilot Pro Plus (Alphabet/GitHub Copilot 상위 요금제)

## 회의록 작성 규칙

- **액션 아이템은 팀 공통 항목만 정리한다.** 개별 프로젝트별 세부 업무(e.g. "OOO 완료", "OOO 분석")는 제외하고, 팀 전체에 해당하는 공통 결정·공유 사항·다 같이 해야 하는 것만 포함한다.

## STT 오인식 교정 패턴

| STT 오인식 | 올바른 표기 | 비고 |
|------------|------------|------|
| 베슬 | VESSL | ML 플랫폼명 |
| LRG | LIG Accuver | 회사명 |
| 엑셀렘 | XTelLM | 프로젝트명 |
| 엑스텔레 | XTelLM | 프로젝트명 |
| 니모어 | NeMo | NVIDIA NeMo |
| 그래프 아이디에스 | GraphIDS | NDR baseline |
| 에리얼 / 에어리얼 | Aerial | NVIDIA Aerial 플랫폼 |
| 오토리 설치 | AutoResearch | 자동 학습 코드 보완 도구 |
| 텔레데이터 | Telecom TS | 통신 Q&A 데이터셋 |
| 쾌멜 | Qwen | 오픈소스 LLM |
| 트레이쉬로이드 / ThreatSold | Threshold | 임계값 |
| 파인트닝 / 파인튜닝 | Fine-tuning | 파인튜닝 |
| 밀리데이션 | Validation | 검증 |
| 리컨스트럭션 | Reconstruction | NDR 재구성 에러 |
| 무거스 / 물라이트 | moonlight | AI 논문 |
| 이기스 에이피 / EGCAP | AEGIS-AP | 프로젝트명 |

---
*마지막 업데이트: 2026-04-14 팀 주간 회의*
