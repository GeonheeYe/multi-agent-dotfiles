# ~/meeting_tools/pipeline.py
"""
전체 파이프라인 실행:
오디오 파일 → STT → 화자분리 → 병합 → JSON 저장
요약 및 Notion 업로드는 /meeting 스킬이 직접 처리한다.
"""
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

from transcribe import format_transcript, transcribe

# soundfile이 직접 읽지 못하는 포맷 → ffmpeg로 wav 변환
_NEEDS_CONVERSION = {".m4a", ".mp3", ".mp4", ".aac", ".ogg", ".flac"}


def _to_wav(path: Path) -> Path:
    """ffmpeg로 16kHz mono wav로 변환. 변환된 임시 파일 경로 반환."""
    out = Path(f"/tmp/{path.stem}_converted.wav")
    subprocess.run(
        ["ffmpeg", "-i", str(path), "-ar", "16000", "-ac", "1", str(out), "-y"],
        check=True, capture_output=True,
    )
    return out


def run(audio_path: str, title: Optional[str] = None) -> str:
    """파이프라인 실행. 대화록 JSON 파일 경로 반환."""
    path = Path(audio_path).expanduser().resolve()
    if not path.exists():
        raise FileNotFoundError(f"오디오 파일을 찾을 수 없습니다: {path}")

    # soundfile이 지원하지 않는 포맷은 wav로 변환
    converted = None
    if path.suffix.lower() in _NEEDS_CONVERSION:
        print(f"{path.suffix} 포맷 감지 → wav로 변환 중...")
        converted = _to_wav(path)
        path = converted

    # 제목 자동 생성
    ts = datetime.now().strftime("%Y-%m-%d")
    if not title:
        title = f"[{ts}] 회의"

    print(f"\n{'='*50}")
    print(f"파이프라인 시작: {path.name}")
    print(f"{'='*50}\n")

    # STT + 화자 분리
    merged = transcribe(str(path))
    transcript = format_transcript(merged)
    speaker_count = len(set(item["speaker"] for item in merged))

    # 결과 JSON 저장 (요약/Notion 업로드는 스킬이 처리)
    result = {
        "title": title,
        "date": ts,
        "speaker_count": speaker_count,
        "transcript": transcript,
    }
    out_path = Path(f"/tmp/meeting_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
    out_path.write_text(json.dumps(result, ensure_ascii=False, indent=2))

    # 변환된 임시 wav 파일 정리
    if converted and converted.exists():
        converted.unlink()

    print(f"\n{'='*50}")
    print(f"처리 완료. 결과: {out_path}")
    print(f"{'='*50}\n")
    return str(out_path)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("사용법: python3 pipeline.py <오디오파일> [회의제목]")
        sys.exit(1)

    audio = sys.argv[1]
    title = sys.argv[2] if len(sys.argv) > 2 else None
    print(run(audio, title))
