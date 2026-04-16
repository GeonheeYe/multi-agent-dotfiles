"""Google Calendar 일정 수집 스크립트

Google Calendar API를 사용하여 앞으로 N일간의 일정을 수집한다.
첫 실행 시 브라우저에서 Google 로그인이 필요하다.

사전 준비:
1. https://console.cloud.google.com 에서 프로젝트 생성
2. Google Calendar API 활성화
3. OAuth 2.0 클라이언트 ID 생성 (데스크톱 앱)
4. credentials.json 다운로드 → 이 스크립트와 같은 폴더에 저장
   (Gmail과 같은 credentials.json을 공유할 수 있다)

실행:
  uv run python .claude/skills/my-context-sync/scripts/calendar_fetch.py --days 7
"""

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Google API 라이브러리가 없으면 설치 안내
try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
except ImportError:
    print("필요한 패키지를 설치합니다:")
    print("  pip install google-auth google-auth-oauthlib google-api-python-client")
    sys.exit(1)

# Calendar API 읽기 전용 권한
SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]

SCRIPT_DIR = Path(__file__).parent
CREDENTIALS_FILE = SCRIPT_DIR / "credentials.json"
TOKEN_FILE = SCRIPT_DIR / "token_calendar.json"


def get_calendar_service():
    """Calendar API 서비스 객체를 생성한다. 첫 실행 시 브라우저 인증이 필요하다."""
    creds = None

    # 기존 토큰이 있으면 재사용
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    # 토큰이 없거나 만료되었으면 갱신
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not CREDENTIALS_FILE.exists():
                print(f"❌ {CREDENTIALS_FILE} 파일이 없습니다.")
                print()
                print("Google Cloud Console에서 OAuth 인증 정보를 다운로드하세요:")
                print("  1. https://console.cloud.google.com 접속")
                print("  2. API 및 서비스 > 사용자 인증 정보")
                print("  3. OAuth 2.0 클라이언트 ID 생성 (데스크톱 앱)")
                print("  4. JSON 다운로드 → credentials.json으로 저장")
                sys.exit(1)

            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES
            )
            creds = flow.run_local_server(port=0)

        # 토큰 저장 (다음 실행 시 재사용)
        with open(TOKEN_FILE, "w") as f:
            f.write(creds.to_json())

    return build("calendar", "v3", credentials=creds)


def fetch_events(days: int = 7) -> dict:
    """앞으로 N일간의 일정을 수집한다."""
    service = get_calendar_service()

    now = datetime.now(timezone.utc)
    time_min = now.isoformat()
    time_max = (now + timedelta(days=days)).isoformat()

    # 일정 조회
    events_result = service.events().list(
        calendarId="primary",
        timeMin=time_min,
        timeMax=time_max,
        maxResults=50,
        singleEvents=True,
        orderBy="startTime",
    ).execute()

    events = events_result.get("items", [])

    # 날짜별로 그룹핑
    by_date = {}
    for event in events:
        start = event["start"].get("dateTime", event["start"].get("date"))
        # 날짜 부분만 추출
        date_key = start[:10]

        if date_key not in by_date:
            by_date[date_key] = []

        by_date[date_key].append({
            "summary": event.get("summary", "(제목 없음)"),
            "start": start,
            "end": event["end"].get("dateTime", event["end"].get("date")),
            "location": event.get("location", ""),
            "attendees": len(event.get("attendees", [])),
            "description": event.get("description", "")[:100],
        })

    # 일정 충돌 감지
    conflicts = []
    sorted_events = sorted(events, key=lambda e: e["start"].get("dateTime", e["start"].get("date")))
    for i in range(len(sorted_events) - 1):
        curr_end = sorted_events[i]["end"].get("dateTime", "")
        next_start = sorted_events[i + 1]["start"].get("dateTime", "")
        if curr_end and next_start and curr_end > next_start:
            conflicts.append({
                "event1": sorted_events[i].get("summary", ""),
                "event2": sorted_events[i + 1].get("summary", ""),
            })

    return {
        "total": len(events),
        "period": f"오늘 ~ {days}일 후",
        "by_date": by_date,
        "conflicts": conflicts,
    }


def main():
    parser = argparse.ArgumentParser(description="Google Calendar 일정 수집")
    parser.add_argument("--days", type=int, default=7, help="수집 기간 (일)")
    parser.add_argument("--json", action="store_true", help="JSON 형식으로 출력")
    args = parser.parse_args()

    print(f"📅 Google Calendar에서 앞으로 {args.days}일간 일정을 수집합니다...")

    result = fetch_events(args.days)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"\n총 {result['total']}개 일정")
        print(f"기간: {result['period']}")
        if result["conflicts"]:
            print(f"⚠️ 일정 충돌: {len(result['conflicts'])}건")
        print("-" * 50)

        for date, events in sorted(result["by_date"].items()):
            print(f"\n📆 {date}")
            for event in events:
                time_str = event["start"][11:16] if len(event["start"]) > 10 else "종일"
                print(f"  {time_str} {event['summary']}")
                if event["location"]:
                    print(f"        📍 {event['location']}")


if __name__ == "__main__":
    main()
