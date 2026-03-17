# ~/meeting_tools/record.py
"""
마이크로 회의를 녹음하고 WAV 파일로 저장한다.
사용법: python record.py [출력파일경로]
종료: Enter 키
"""
import sys
import threading
from datetime import datetime
from pathlib import Path

import numpy as np
import sounddevice as sd
from scipy.io import wavfile

SAMPLE_RATE = 16000  # Whisper 최적 샘플레이트


def record(output_path: Path) -> None:
    chunks = []

    def callback(indata, frames, time, status):
        if status:
            print(f"경고: {status}")
        chunks.append(indata.copy())

    print(f"녹음 시작... (종료하려면 Enter 키를 누르세요)")
    print(f"저장 경로: {output_path}")

    stop_event = threading.Event()

    def wait_for_enter():
        try:
            with open("/dev/tty") as tty:
                tty.readline()
        except Exception:
            pass
        stop_event.set()

    t = threading.Thread(target=wait_for_enter, daemon=True)
    t.start()

    with sd.InputStream(samplerate=SAMPLE_RATE, channels=1, dtype="float32", callback=callback):
        try:
            stop_event.wait()  # 메인 스레드에서 대기 → Ctrl+C 정상 수신
        except KeyboardInterrupt:
            print("\nCtrl+C 감지, 저장 중...")

    if not chunks:
        print("녹음된 데이터가 없습니다.")
        return

    print("녹음 종료 중...")
    audio = np.concatenate(chunks, axis=0)
    audio_int16 = (audio * 32767).astype(np.int16)
    wavfile.write(str(output_path), SAMPLE_RATE, audio_int16)
    print(f"저장 완료: {output_path}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        out = Path(sys.argv[1])
    else:
        ts = datetime.now().strftime("%Y%m%d_%H%M")
        out = Path.home() / "meetings" / f"audio_{ts}.wav"

    out.parent.mkdir(parents=True, exist_ok=True)
    record(out)
