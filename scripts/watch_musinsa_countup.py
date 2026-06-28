#!/usr/bin/env python3
"""무신사 무진장 누적 판매 금액을 감시하고 기준 도달 시 Dooray DM을 보낸다."""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEFAULT_MUSINSA_URL = "https://rcb.musinsa.com/rcb-tick.json"
DEFAULT_SECRETS_PATH = Path.home() / "dotfiles" / "mcp" / "secrets.json"
DEFAULT_DOORAY_API_BASE = "https://api.dooray.com"
DEFAULT_FLAG_PATH = Path("/tmp/musinsa_countup_2398_sent.flag")


def now_text() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z")


def log(message: str) -> None:
    print(f"[{now_text()}] {message}", flush=True)


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def request_json(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    body: dict[str, Any] | None = None,
    timeout: int = 20,
) -> dict[str, Any]:
    data = None
    request_headers = headers.copy() if headers else {}

    if body is not None:
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    req = Request(url, data=data, headers=request_headers, method=method)
    with urlopen(req, timeout=timeout) as res:
        raw = res.read().decode("utf-8")
    return json.loads(raw)


def fetch_musinsa_amount(url: str) -> dict[str, int]:
    # 캐시 회피를 위해 페이지 번들과 동일하게 timestamp 쿼리를 붙인다.
    payload = request_json(f"{url}?timestamp={int(time.time() * 1000)}")
    return {
        "pay_amount": int(payload.get("pay_amount", 0)),
        "total_order_qty": int(payload.get("total_order_qty", 0)),
        "discount_amount": int(payload.get("discount_amount", 0)),
        "timestamp": int(payload.get("timestamp", 0)),
    }


def send_dooray_dm(
    *,
    token: str,
    member_id: str,
    text: str,
    api_base: str = DEFAULT_DOORAY_API_BASE,
) -> dict[str, Any]:
    response = request_json(
        f"{api_base.rstrip('/')}/messenger/v1/channels/direct-send",
        method="POST",
        headers={"Authorization": f"dooray-api {token}"},
        body={"organizationMemberId": member_id, "text": text},
    )

    header = response.get("header", {})
    if header and not header.get("isSuccessful", False):
        raise RuntimeError(header.get("resultMessage") or "Dooray DM send failed")
    return response.get("result", response)


def format_won(value: int) -> str:
    return f"{value:,}원"


def build_message(pay_amount: int, threshold: int, url: str) -> str:
    return "\n".join(
        [
            "무신사 무진장 누적 판매 금액이 기준을 넘었습니다.",
            f"기준 금액: {format_won(threshold)}",
            f"현재 누적 판매 금액: {format_won(pay_amount)}",
            f"URL: {url}",
        ]
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--threshold", type=int, required=True)
    parser.add_argument("--member-id", required=True)
    parser.add_argument("--interval", type=int, default=30)
    parser.add_argument("--secrets", type=Path, default=DEFAULT_SECRETS_PATH)
    parser.add_argument("--flag", type=Path, default=DEFAULT_FLAG_PATH)
    parser.add_argument("--once", action="store_true", help="현재 값만 확인하고 종료한다.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    secrets = read_json(args.secrets)
    token = secrets.get("DOORAY_API_TOKEN")
    if not token:
        raise RuntimeError("DOORAY_API_TOKEN이 secrets.json에 없습니다.")

    log(
        "감시 시작: "
        f"threshold={format_won(args.threshold)}, interval={args.interval}s, "
        f"member_id={args.member_id}"
    )

    while True:
        try:
            data = fetch_musinsa_amount(DEFAULT_MUSINSA_URL)
            pay_amount = data["pay_amount"]
            remain = max(args.threshold - pay_amount, 0)
            log(
                "확인: "
                f"pay_amount={format_won(pay_amount)}, "
                f"remain={format_won(remain)}, "
                f"total_order_qty={data['total_order_qty']:,}"
            )

            if pay_amount >= args.threshold:
                if args.flag.exists():
                    log(f"이미 발송 플래그가 있어 종료: {args.flag}")
                    return 0

                message = build_message(
                    pay_amount,
                    args.threshold,
                    "https://www.musinsa.com/campaign/mujinjangsale/benefit#countup",
                )
                result = send_dooray_dm(
                    token=token,
                    member_id=args.member_id,
                    text=message,
                )
                args.flag.write_text(
                    json.dumps(
                        {
                            "sentAt": now_text(),
                            "payAmount": pay_amount,
                            "threshold": args.threshold,
                            "doorayResult": result,
                        },
                        ensure_ascii=False,
                        indent=2,
                    ),
                    encoding="utf-8",
                )
                log("Dooray DM 발송 완료. 감시를 종료합니다.")
                return 0

            if args.once:
                return 0

        except (HTTPError, URLError, TimeoutError, json.JSONDecodeError, RuntimeError) as e:
            log(f"오류: {e}")
            if args.once:
                return 1

        time.sleep(args.interval)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        log("사용자 중단")
        raise SystemExit(130)
