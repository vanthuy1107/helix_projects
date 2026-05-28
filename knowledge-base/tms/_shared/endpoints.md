# TMS — Danh mục endpoint

Host prod: `https://api-stm-prod-report.smartlogvn.com`. Auth: Bearer — xem [auth.md](auth.md).

## `POST /api/REP/REPDIOPSPlan_SettingDownload`

Handler **dùng chung** để export báo cáo họ `REPDIOPSPlan`. Phân biệt báo cáo cụ thể bằng:

- `item.TypeExport` — số báo cáo (vd `25`)
- header `functionid` — vd `78`

Response: **chuỗi URL** file `.xlsx` trên S3 (`smartlog-stm-docs.s3.amazonaws.com/...`), tải về bằng GET.

| Report | TypeExport | functionid | Tài liệu |
|---|---|---|---|
| Báo cáo theo đơn hàng và chuyến | 25 | 78 | [reports/25-trip-and-order](../reports/25-trip-and-order/25-tms-trip-and-order.md) |

> Hồ sơ #25 có nhắc báo cáo lân cận **26** và **38** (cùng họ trường) — bổ sung vào bảng khi có request mẫu.
