# ~/meeting_tools/transcribe.py
"""
Whisper로 오디오 파일을 텍스트로 변환한다.
pyannote로 화자를 분리하고 두 결과를 병합한다.
"""
import os
from pathlib import Path

import torch
import whisper
from dotenv import load_dotenv

# PyTorch 2.6에서 weights_only 기본값이 True로 변경되어 pyannote 모델 로딩 실패
# pyannote는 신뢰된 소스이므로 weights_only=False로 강제 (2.5 이전 동작)
_original_torch_load = torch.load
def _patched_torch_load(*args, **kwargs):
    kwargs["weights_only"] = False  # setdefault 대신 강제 덮어쓰기
    return _original_torch_load(*args, **kwargs)
torch.load = _patched_torch_load

from pyannote.audio import Pipeline

load_dotenv(Path(__file__).parent / ".env")


def run_whisper(audio_path: str) -> list[dict]:
    """Whisper STT 실행. 타임스탬프 포함 세그먼트 반환."""
    print("Whisper STT 실행 중... (처음 실행 시 모델 다운로드 필요)")
    model = whisper.load_model("large-v3-turbo")
    result = model.transcribe(audio_path, language="ko", verbose=False)
    segments = [
        {"start": seg["start"], "end": seg["end"], "text": seg["text"].strip()}
        for seg in result["segments"]
    ]
    print(f"STT 완료: {len(segments)}개 세그먼트")
    return segments


def run_diarization(audio_path: str) -> list[tuple]:
    """pyannote로 화자 분리. [(speaker, start, end), ...] 반환."""
    hf_token = os.environ.get("HF_TOKEN")
    if not hf_token:
        raise ValueError("HF_TOKEN 환경변수가 설정되지 않았습니다.")

    print("화자 분리 실행 중...")
    pipeline = Pipeline.from_pretrained(
        "pyannote/speaker-diarization-3.1",
        use_auth_token=hf_token,
    )
    diarization = pipeline(audio_path)

    turns = []
    for turn, _, speaker in diarization.itertracks(yield_label=True):
        turns.append((speaker, turn.start, turn.end))
    print(f"화자 분리 완료: {len(set(t[0] for t in turns))}명 감지")
    return turns


def _find_speaker(start: float, end: float, turns: list[tuple]) -> str:
    """세그먼트 시간과 가장 많이 겹치는 화자 반환."""
    overlap: dict[str, float] = {}
    for speaker, t_start, t_end in turns:
        o = max(0.0, min(end, t_end) - max(start, t_start))
        if o > 0:
            overlap[speaker] = overlap.get(speaker, 0) + o
    if not overlap:
        return "Unknown"
    return max(overlap, key=overlap.get)


def merge(segments: list[dict], turns: list[tuple]) -> list[dict]:
    """STT 세그먼트에 화자 정보를 붙인다."""
    speaker_map: dict[str, str] = {}

    def _label(n: int) -> str:
        # A-Z, 이후 AA, AB...
        if n < 26:
            return f"Speaker {chr(65 + n)}"
        return f"Speaker {chr(65 + n // 26 - 1)}{chr(65 + n % 26)}"

    result = []
    for seg in segments:
        raw = _find_speaker(seg["start"], seg["end"], turns)
        if raw not in speaker_map:
            speaker_map[raw] = _label(len(speaker_map))
        result.append({
            "speaker": speaker_map[raw],
            "start": seg["start"],
            "end": seg["end"],
            "text": seg["text"],
        })
    return result


def transcribe(audio_path: str) -> list[dict]:
    """전체 파이프라인: STT + 화자분리 + 병합."""
    segments = run_whisper(audio_path)
    turns = run_diarization(audio_path)
    merged = merge(segments, turns)
    return merged


def format_transcript(merged: list[dict]) -> str:
    """대화록을 읽기 좋은 텍스트로 변환."""
    lines = []
    prev_speaker = None
    for item in merged:
        if item["speaker"] != prev_speaker:
            lines.append(f"\n[{item['speaker']}]")
            prev_speaker = item["speaker"]
        lines.append(item["text"])
    return "\n".join(lines).strip()


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("사용법: python transcribe.py <오디오파일>")
        sys.exit(1)
    merged = transcribe(sys.argv[1])
    print("\n=== 대화록 ===")
    print(format_transcript(merged))
