"""
da.ch
─────
Kết nối ClickHouse + chạy truy vấn → DataFrame. MỘT factory duy nhất —
thay 13 bản `get_client(...)` copy trong notebook/script.

Quy ước binding (chống corrupt UTF-8 — xem /da-py §1):
  - GIÁ TRỊ (ngày, chuỗi tiếng Việt) → bind server-side qua `params=`
    với placeholder {tên:Kiểu}, vd {svc:String}, {stt:Array(String)}.
    KHÔNG inline chuỗi tiếng Việt vào SQL (clickhouse-connect corrupt UTF-8 → 0 row sai).
  - ĐỊNH DANH (tên bảng/cột) + mảnh SQL → nội suy bằng f-string ở call site
    (clickhouse-connect chỉ bind được value, không bind được identifier).
"""
from __future__ import annotations

from typing import Any

import pandas as pd
import clickhouse_connect

from .config import TenantConfig


def ch_client(cfg: TenantConfig, *, connect_timeout: int = 30,
              send_receive_timeout: int = 120):
    """Factory client ClickHouse duy nhất cho toàn bộ DA Python."""
    return clickhouse_connect.get_client(
        host=cfg.ch.host,
        port=cfg.ch.port,
        username=cfg.ch.user,
        password=cfg.ch.password,
        secure=cfg.ch.secure,
        connect_timeout=connect_timeout,
        send_receive_timeout=send_receive_timeout,
    )


def run_df(client, sql: str, params: dict[str, Any] | None = None) -> pd.DataFrame:
    """Chạy SQL → DataFrame. Truyền VALUE qua `params` (bind an toàn).

    Vd:
        run_df(client,
               "SELECT count() c FROM t WHERE svc = {svc:String}",
               {"svc": "Xuất bán"})
    """
    return client.query_df(sql, parameters=params or {})


def meta(client, table: str, date_col: str) -> dict[str, Any]:
    """Metadata nhanh để chạy TRƯỚC query chính (xem /da-py Bước 4): khoảng ngày,
    số row, độ trễ freshness theo `date_col`. Nếu max_date < ngày hỏi → query chính
    sẽ 0 row, biết trước đỡ tốn thời gian.

    `table` là tên fully-qualified (dùng cfg.table('...')).
    """
    df = run_df(client, f"""
        SELECT count()                                    AS rows,
               toDate(min({date_col}))                    AS min_date,
               toDate(max({date_col}))                    AS max_date,
               dateDiff('minute', max({date_col}), now()) AS lag_min
        FROM {table}
    """)
    return df.iloc[0].to_dict() if len(df) else {}
