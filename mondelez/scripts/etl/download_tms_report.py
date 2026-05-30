"""
download_tms_report.py
──────────────────────
Lấy access token (OIDC password grant) → gọi API export report TMS →
nhận URL file .xlsx trên S3 → tải về.

Mặc định chạy report #25 (Báo cáo theo đơn hàng và chuyến) với payload mẫu:
    knowledge-base/tms/reports/25-trip-and-order/samples/request.json

Cách chạy:
    python projects/mondelez/scripts/etl/download_tms_report.py
    python projects/mondelez/scripts/etl/download_tms_report.py --from 2026-05-01 --to 2026-05-15
    python projects/mondelez/scripts/etl/download_tms_report.py --request <path.json> --functionid 78

Mặc định window (khi không truyền --from/--to): từ NGÀY CUỐI THÁNG TRƯỚC → HÔM NAY.
Đệm 1 ngày của tháng trước để chạy đúng ngày 1 không bị rớt dữ liệu ngày 1 ở biên
cắt timezone UTC↔+07 (xem default_window()).

Env (projects/mondelez/.env):
    TMS_AUTH_URL TMS_REPORT_HOST TMS_TENANT_HOST TMS_CLIENT_ID TMS_SCOPE
    TMS_USERNAME TMS_PASSWORD

Output: projects/mondelez/.downloads/tms/  (gitignored — dữ liệu tenant, không commit)
"""

import os
import sys
import json
import argparse
from pathlib import Path
from datetime import date, datetime, timedelta

import requests
from dotenv import load_dotenv

_TENANT_DIR = next(p for p in Path(__file__).resolve().parents
                   if (p / "da.toml").exists())             # tenant root = nơi có da.toml (relocation-proof)
_PROJECTS_DIR = _TENANT_DIR.parent                          # projects/
_ENV = _TENANT_DIR / ".env"
if _ENV.exists():
    load_dotenv(_ENV)
else:
    load_dotenv()

DEFAULT_REQUEST = (
    _PROJECTS_DIR / "knowledge-base" / "tms" / "reports"
    / "25-trip-and-order" / "samples" / "request.json"
)
DEFAULT_ENDPOINT = "REPDIOPSPlan_SettingDownload"
DEFAULT_FUNCTIONID = "78"
OUT_DIR = _TENANT_DIR / ".downloads" / "tms"

AUTH_URL = os.getenv("TMS_AUTH_URL")
REPORT_HOST = (os.getenv("TMS_REPORT_HOST") or "").rstrip("/")
TENANT_HOST = os.getenv("TMS_TENANT_HOST")
CLIENT_ID = os.getenv("TMS_CLIENT_ID")
SCOPE = os.getenv("TMS_SCOPE", "openid profile email address phone role Auth offline_access")
USERNAME = os.getenv("TMS_USERNAME")
PASSWORD = os.getenv("TMS_PASSWORD")


def validate_env() -> None:
    required = {
        "TMS_AUTH_URL": AUTH_URL,
        "TMS_REPORT_HOST": REPORT_HOST,
        "TMS_TENANT_HOST": TENANT_HOST,
        "TMS_CLIENT_ID": CLIENT_ID,
        "TMS_USERNAME": USERNAME,
        "TMS_PASSWORD": PASSWORD,
    }
    missing = [k for k, v in required.items() if not v]
    if missing:
        print(f"[ERROR] Thiếu env trong {_ENV}: {', '.join(missing)}")
        sys.exit(1)


def get_token() -> str:
    print("[INFO] Lấy access token (password grant)...")
    resp = requests.post(
        AUTH_URL,
        data={
            "grant_type": "password",
            "username": USERNAME,
            "password": PASSWORD,
            "client_id": CLIENT_ID,
            "scope": SCOPE,
        },
        headers={"content-type": "application/x-www-form-urlencoded", "d": TENANT_HOST},
        timeout=60,
    )
    if resp.status_code != 200:
        print(f"[ERROR] Token thất bại {resp.status_code}: {resp.text[:300]}")
        sys.exit(1)
    token = resp.json().get("access_token")
    if not token:
        print(f"[ERROR] Response không có access_token: {resp.text[:300]}")
        sys.exit(1)
    print("[OK] Đã có token.")
    return token


# Cửa sổ local [S, E] bao gồm 2 đầu: 17:00Z = 00:00 +07 (giờ VN)
def to_dtfrom(local_start: str) -> str:
    dt = datetime.strptime(local_start, "%Y-%m-%d") - timedelta(days=1)
    return dt.strftime("%Y-%m-%dT17:00:00.000Z")


def to_dtto(local_end: str) -> str:
    dt = datetime.strptime(local_end, "%Y-%m-%d")
    return dt.strftime("%Y-%m-%dT17:00:00.000Z")


# Mặc định khi không truyền --from/--to:
#   from = NGÀY CUỐI THÁNG TRƯỚC (không phải đầu tháng này như MTD chuẩn).
# Lý do: chạy đúng vào ngày 1, nếu from=đầu tháng thì ngày 1 dễ rớt ở biên
# cắt timezone UTC↔+07 — đệm thêm 1 ngày của tháng trước để CHẮC CHẮN bao trọn
# ngày 1. Dữ liệu thừa của ngày cuối tháng trước lọc lại ở bước phân tích.
def default_window() -> tuple[str, str]:
    today = date.today()
    last_of_prev = today.replace(day=1) - timedelta(days=1)
    return last_of_prev.isoformat(), today.isoformat()


def main() -> None:
    parser = argparse.ArgumentParser(description="Tải report TMS từ S3.")
    parser.add_argument("--request", default=str(DEFAULT_REQUEST), help="Đường dẫn payload JSON")
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT, help="Tên endpoint REP/*")
    parser.add_argument("--functionid", default=DEFAULT_FUNCTIONID)
    parser.add_argument("--from", dest="dfrom",
                        help="Ngày local bắt đầu YYYY-MM-DD (mặc định: ngày cuối tháng trước)")
    parser.add_argument("--to", dest="dto",
                        help="Ngày local kết thúc YYYY-MM-DD (mặc định: hôm nay)")
    parser.add_argument("--out", default=str(OUT_DIR))
    args = parser.parse_args()

    print("=" * 60)
    print("download_tms_report.py — MDLZ Control Tower")
    print("=" * 60)
    validate_env()

    body = json.loads(Path(args.request).read_text(encoding="utf-8"))
    def_from, def_to = default_window()
    dfrom = args.dfrom or def_from
    dto = args.dto or def_to
    body["dtfrom"] = to_dtfrom(dfrom)
    body["dtto"] = to_dtto(dto)
    print(f"[INFO] Window local: {dfrom} → {dto} "
          f"{'(mặc định: cuối tháng trước → hôm nay)' if not args.dfrom else ''}")
    print(f"[INFO] Report TypeExport={body.get('item', {}).get('TypeExport')} "
          f"| dtfrom={body.get('dtfrom')} dtto={body.get('dtto')}")

    token = get_token()
    url = f"{REPORT_HOST}/api/REP/{args.endpoint}"
    print(f"[INFO] POST {url} (functionid={args.functionid})")
    resp = requests.post(
        url,
        json=body,
        headers={
            "authorization": f"Bearer {token}",
            "content-type": "application/json; charset=UTF-8",
            "d": TENANT_HOST,
            "functionid": str(args.functionid),
            "origin": f"https://{TENANT_HOST}",
            "referer": f"https://{TENANT_HOST}/",
        },
        timeout=300,
    )
    if resp.status_code != 200:
        print(f"[ERROR] Export thất bại {resp.status_code}: {resp.text[:500]}")
        sys.exit(1)

    try:
        file_url = resp.json()
    except ValueError:
        file_url = resp.text.strip().strip('"')
    if not isinstance(file_url, str) or not file_url.startswith("http"):
        print(f"[ERROR] Response không phải URL: {str(file_url)[:300]}")
        sys.exit(1)
    print(f"[OK] File URL: {file_url}")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    fname = file_url.split("/")[-1].split("?")[0]
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = out_dir / f"{stamp}_{fname}"

    print(f"[INFO] Tải về {dest} ...")
    with requests.get(file_url, stream=True, timeout=300) as r:
        r.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in r.iter_content(chunk_size=65536):
                f.write(chunk)
    print(f"[OK] Đã tải: {dest} ({dest.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
