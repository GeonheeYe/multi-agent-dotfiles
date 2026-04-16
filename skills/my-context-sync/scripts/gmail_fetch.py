"""Gmail 이메일 수집 스크립트

Google Gmail API를 사용하여 최근 이메일을 수집한다.
첫 실행 시 브라우저에서 Google 로그인이 필요하다.

사전 준비:
1. https://console.cloud.google.com 에서 프로젝트 생성
2. Gmail API 활성화
3. OAuth 2.0 클라이언트 ID 생성 (데스크톱 앱)
4. credentials.json 다운로드 → 이 스크립트와 같은 폴더에 저장

실행:
  uv run python .claude/skills/my-context-sync/scripts/gmail_fetch.py --days 7
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
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

# Gmail API 읽기 전용 권한
SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]

SCRIPT_DIR = Path(__file__).parent
CREDENTIALS_FILE = SCRIPT_DIR / "credentials.json"
TOKEN_FILE = SCRIPT_DIR / "token_gmail.json"


def get_gmail_service():
    """Gmail API 서비스 객체를 생성한다. 첫 실행 시 브라우저 인증이 필요하다."""
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

    return build("gmail", "v1", credentials=creds)


def fetch_emails(days: int = 7) -> dict:
    """최근 N일간의 이메일을 수집한다."""
    service = get_gmail_service()

    # 날짜 범위 계산
    after_date = (datetime.now() - timedelta(days=days)).strftime("%Y/%m/%d")
    query = f"after:{after_date}"

    # 메시지 목록 조회
    results = service.users().messages().list(
        userId="me", q=query, maxResults=50
    ).execute()

    messages = results.get("messages", [])

    emails = []
    unread_count = 0

    for msg_info in messages:
        msg = service.users().messages().get(
            userId="me", id=msg_info["id"], format="metadata",
            metadataHeaders=["From", "Subject", "Date"]
        ).execute()

        headers = {h["name"]: h["value"] for h in msg["payload"]["headers"]}
        is_unread = "UNREAD" in msg.get("labelIds", [])

        if is_unread:
            unread_count += 1

        emails.append({
            "from": headers.get("From", ""),
            "subject": headers.get("Subject", ""),
            "date": headers.get("Date", ""),
            "unread": is_unread,
            "snippet": msg.get("snippet", ""),
        })

    return {
        "total": len(emails),
        "unread": unread_count,
        "period": f"최근 {days}일",
        "emails": emails,
    }


def main():
    parser = argparse.ArgumentParser(description="Gmail 이메일 수집")
    parser.add_argument("--days", type=int, default=7, help="수집 기간 (일)")
    parser.add_argument("--json", action="store_true", help="JSON 형식으로 출력")
    args = parser.parse_args()

    print(f"📧 Gmail에서 최근 {args.days}일간 이메일을 수집합니다...")

    result = fetch_emails(args.days)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"\n총 {result['total']}개 이메일 (안 읽음: {result['unread']}개)")
        print(f"기간: {result['period']}")
        print("-" * 50)

        for email in result["emails"][:20]:  # 상위 20개만 표시
            status = "📩" if email["unread"] else "  "
            print(f"{status} [{email['date'][:16]}] {email['from'][:30]}")
            print(f"   {email['subject']}")
            print()


if __name__ == "__main__":
    main()
