"""Google Calendar API - 조회, 추가, 수정, 삭제"""

import sys
import os
import json
from datetime import datetime, timezone, timedelta

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# 읽기+쓰기 권한
SCOPES = ["https://www.googleapis.com/auth/calendar"]

# 프로젝트 루트 기준 경로 (skills/gcal/scripts/ → 3단계 상위 → .claude 상위)
PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
CREDENTIALS_PATH = os.path.join(PROJECT_DIR, "credentials.json")
TOKEN_PATH = os.path.join(PROJECT_DIR, "token_calendar.json")


def get_service():
    """인증 후 Calendar 서비스 객체 반환"""
    creds = None

    if os.path.exists(TOKEN_PATH):
        creds = Credentials.from_authorized_user_file(TOKEN_PATH, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_PATH, SCOPES)
            creds = flow.run_local_server(port=0)

        with open(TOKEN_PATH, "w") as f:
            f.write(creds.to_json())

    return build("calendar", "v3", credentials=creds)


def list_events(max_results=10, days=7):
    """다가오는 일정 조회"""
    service = get_service()
    now = datetime.now(timezone.utc)
    time_max = now + timedelta(days=days)

    result = service.events().list(
        calendarId="primary",
        timeMin=now.isoformat(),
        timeMax=time_max.isoformat(),
        maxResults=max_results,
        singleEvents=True,
        orderBy="startTime",
    ).execute()

    events = result.get("items", [])
    if not events:
        print("일정이 없습니다.")
        return

    print(f"다가오는 일정 ({days}일 이내, {len(events)}개):\n")
    for e in events:
        start = e["start"].get("dateTime", e["start"].get("date"))
        event_id = e["id"]
        print(f"  {start} | {e['summary']} (id: {event_id})")


def add_event(summary, start, end, description=""):
    """일정 추가. start/end 형식: 'YYYY-MM-DD' 또는 'YYYY-MM-DDTHH:MM:SS'"""
    service = get_service()

    # 종일 일정인지 시간 지정 일정인지 판단
    if len(start) == 10:  # YYYY-MM-DD
        body = {
            "summary": summary,
            "description": description,
            "start": {"date": start},
            "end": {"date": end},
        }
    else:
        # 타임존 추가
        if "+" not in start and "Z" not in start:
            start += "+09:00"
            end += "+09:00"
        body = {
            "summary": summary,
            "description": description,
            "start": {"dateTime": start},
            "end": {"dateTime": end},
        }

    event = service.events().insert(calendarId="primary", body=body).execute()
    print(f"일정 추가 완료: {event['summary']} (id: {event['id']})")


def update_event(event_id, **kwargs):
    """일정 수정. kwargs: summary, start, end, description"""
    service = get_service()

    event = service.events().get(calendarId="primary", eventId=event_id).execute()

    if "summary" in kwargs:
        event["summary"] = kwargs["summary"]
    if "description" in kwargs:
        event["description"] = kwargs["description"]
    if "start" in kwargs:
        s = kwargs["start"]
        event["start"] = {"date": s} if len(s) == 10 else {"dateTime": s if "+" in s or "Z" in s else s + "+09:00"}
    if "end" in kwargs:
        e = kwargs["end"]
        event["end"] = {"date": e} if len(e) == 10 else {"dateTime": e if "+" in e or "Z" in e else e + "+09:00"}

    updated = service.events().update(calendarId="primary", eventId=event_id, body=event).execute()
    print(f"일정 수정 완료: {updated['summary']}")


def delete_event(event_id):
    """일정 삭제"""
    service = get_service()
    service.events().delete(calendarId="primary", eventId=event_id).execute()
    print(f"일정 삭제 완료 (id: {event_id})")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        list_events()
    elif sys.argv[1] == "list":
        days = int(sys.argv[2]) if len(sys.argv) > 2 else 7
        max_results = int(sys.argv[3]) if len(sys.argv) > 3 else 10
        list_events(max_results=max_results, days=days)
    elif sys.argv[1] == "add":
        # python gcal.py add "제목" "2026-02-20" "2026-02-21" "설명(선택)"
        desc = sys.argv[5] if len(sys.argv) > 5 else ""
        add_event(sys.argv[2], sys.argv[3], sys.argv[4], desc)
    elif sys.argv[1] == "update":
        # python gcal.py update EVENT_ID key=value ...
        kwargs = {}
        for arg in sys.argv[3:]:
            k, v = arg.split("=", 1)
            kwargs[k] = v
        update_event(sys.argv[2], **kwargs)
    elif sys.argv[1] == "delete":
        delete_event(sys.argv[2])
    else:
        print("사용법: python gcal.py [list|add|update|delete] ...")
