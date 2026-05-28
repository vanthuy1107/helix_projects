# TMS — Xác thực (lấy access token)

Mọi lệnh tải report TMS đều cần header `Authorization: Bearer <access_token>`. Token lấy từ IdentityServer (OIDC) của Smartlog.

## Token endpoint

| Field | Giá trị |
|---|---|
| Method | POST |
| URL | `https://auth-be.smartlogvn.com/connect/token` |
| Content-Type | `application/x-www-form-urlencoded` |
| Grant type | `password` (Resource Owner Password Credentials) |
| Client ID | `STM` |

> Căn cứ: access_token chứa `"amr":["pwd"]`, `"idp":"local"`, `"client_id":"STM"`, scope có `offline_access` → ROPC + refresh token.

## Form body (x-www-form-urlencoded)

| Field | Giá trị | Ghi chú |
|---|---|---|
| grant_type | `password` | |
| username | `<TMS_USERNAME>` | tài khoản service, vd `helixbi.mdlz@gosmartlog.com` |
| password | `<TMS_PASSWORD>` | **KHÔNG commit** |
| client_id | `STM` | |
| client_secret | `<nếu server yêu cầu>` | thử bỏ trống trước; nếu trả `invalid_client` thì thêm |
| scope | `openid profile email address phone role Auth offline_access` | |

> ⚠️ Request Postman gốc có `--body ''` (rỗng) → tự nó **không** lấy được token. Phải điền các field form ở trên.

## Response (mẫu)

```json
{
  "access_token": "<JWT>",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "refresh_token": "<...>"
}
```

- `access_token` sống ~**30 ngày** → cache lại, không xin mới mỗi lần tải report.
- `refresh_token` để gia hạn khi hết hạn (nhờ scope `offline_access`).

## Flow tải report end-to-end

1. `POST /connect/token` → lấy `access_token`.
2. Gọi report (vd #25 `REPDIOPSPlan`): `POST https://api-stm-prod-report.smartlogvn.com/api/REP/...`
   - header `Authorization: Bearer <access_token>`
   - header `d: {tenant}.smartlogvn.com` (vd `mondelez.smartlogvn.com`)
   - header `functionid: <id report>`
   - body = payload report (xem `reports/{...}/*.api.md`)
3. Response trả URL `.xlsx` trên S3 → tải về.

## Quản lý bí mật (BẮT BUỘC)

- username / password / client_secret / token / cookie **KHÔNG bao giờ** nằm trong repo.
- Lưu ở `.env` per-tenant gitignored — vd `projects/mondelez/.env` (keys `TMS_USERNAME` / `TMS_PASSWORD`); schema không secret ở `projects/mondelez/.env.example`. Script đọc từ env.
- File này chỉ mô tả flow bằng placeholder `<...>`.
- Cookie `AWSALB*` trong request chỉ là sticky-session của load balancer — không cần lưu.
