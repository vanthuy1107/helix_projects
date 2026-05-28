# TMS #25 — API contract

> **Trạng thái:** 🟢 đầy đủ. Cách tải report #25 qua API (token → export → S3).

## Endpoint

| Field | Giá trị |
|---|---|
| Method | POST |
| URL | `{TMS_REPORT_HOST}/api/REP/REPDIOPSPlan_SettingDownload` |
| Host (prod) | `https://api-stm-prod-report.smartlogvn.com` |
| functionid | `78` |
| Content-Type | `application/json; charset=UTF-8` |
| Output | Response trả **chuỗi URL** file `.xlsx` trên S3 (tự tải về sau) |

> `REPDIOPSPlan_SettingDownload` là handler **dùng chung** cho nhiều report; phân biệt báo cáo nào bằng `item.TypeExport` (25) + header `functionid` (78). Xem [_shared/endpoints.md](../../_shared/endpoints.md).

## Headers bắt buộc

| Header | Giá trị |
|---|---|
| `authorization` | `Bearer <access_token>` — xem [_shared/auth.md](../../_shared/auth.md) |
| `d` | `mondelez.smartlogvn.com` (tenant) |
| `functionid` | `78` |
| `content-type` | `application/json; charset=UTF-8` |

## Request body

Payload đầy đủ (đã chạy thật, **không** chứa token) lưu ở `samples/request.json`. Các field then chốt:

| Field | Giá trị mẫu | Ý nghĩa |
|---|---|---|
| `item.TypeExport` | `25` | Chọn báo cáo #25 |
| `item.ReferID` | `78` | = functionid |
| `item.Name` | `Báo cáo theo đơn hàng và chuyến` | |
| `item.TypeDateRange` | `3` | Khoảng ngày tùy chọn (dùng `dtfrom`/`dtto`) |
| `item.TypeOfDate` | `9` | Loại ngày lọc (xem [_shared/date-params.md](../../_shared/date-params.md)) |
| `item.ListCustomer` | `[{ CustomerCode: "MDLZ", ... }]` | Lọc theo khách |
| `item.ListFilterAvailable` | 40 codes | Bộ lọc khả dụng (xem [_shared/filters.md](../../_shared/filters.md)) |
| `dtfrom` / `dtto` | `2026-05-22T17:00:00.000Z` / `2026-05-26T17:00:00.000Z` | Cửa sổ ngày (UTC; `17:00Z` = `00:00 +07`) |
| `Week` / `Year` | `1` / `2026` | |

> **Quy ước ngày:** `dtfrom` = ngày local đầu − 1 lúc `17:00Z`; `dtto` = ngày local cuối lúc `17:00Z`. Mẫu trên = local **23→26/05/2026**.

## Response

```json
"https://smartlog-stm-docs.s3.amazonaws.com/mondelez.smartlog.vn/2026/05/27/reportAuto/REPDIOPSPlan_25_TripAndOrder_<id>.xlsx"
```

→ GET URL này (S3 public-read) để tải file `.xlsx`.

## Script

`projects/mondelez/scripts/download_tms_report.py` làm trọn flow: lấy token → POST export → tải S3.
