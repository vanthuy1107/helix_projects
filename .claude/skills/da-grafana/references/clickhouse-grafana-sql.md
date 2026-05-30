# Grafana × ClickHouse — SQL macro, biến template, format

Áp cho plugin chính chủ **`grafana-clickhouse-datasource`** (Grafana Labs). Macro/format CÓ THỂ đổi theo major version → **verify với plugin đã cài** (Datasource → query inspector hiện SQL đã expand). Đừng đoán enum.

---

## 1. Time macro (dùng thay `WHERE window` của script)

| Macro | Expand (đại ý) | Dùng cho |
|---|---|---|
| `$__timeFilter(col)` | `col >= toDateTime(...) AND col <= toDateTime(...)` theo time picker | Cột kiểu DateTime/Date |
| `$__timeFilter_ms(col)` | bản millisecond | Cột DateTime64(3) |
| `$__fromTime` / `$__toTime` | `toDateTime(...)` biên dưới/trên | Tự ghép biểu thức |
| `$__fromTime_ms` / `$__toTime_ms` | bản ms | nt |
| `$__dateFilter(col)` | filter theo **Date** (không giờ) | Cột `Date` |
| `$__dateTimeFilter(dateCol, timeCol)` | ghép Date + Time tách rời | Hiếm |
| `$__timeInterval(col)` | làm tròn theo bucket auto của panel | Group-by động theo zoom |
| `$__interval_s` | độ rộng bucket (giây) | Tính step |

**Quy tắc:** mọi panel time series PHẢI có `$__timeFilter(<time_col>)` + `GROUP BY time ORDER BY time`, với `time` là cột DateTime đầu tiên.

### Cột thời gian là CHUỖI (TMS #25 `TenderedDate`)
Plugin có thể không nhận `$__timeFilter` lên biểu thức `parseDateTimeBestEffortOrNull(...)`. Hai cách an toàn:
```sql
-- (a) filter trên cột parse trong subquery rồi group ngoài
SELECT time, ... FROM (
  SELECT parseDateTimeBestEffortOrNull(nullIf(TenderedDate,'')) AS ts, ...
  FROM analytics_workspace.mdlz_tms_report_25_trip_order
) WHERE $__timeFilter(ts) ...

-- (b) tự ghép biên bằng $__fromTime / $__toTime
WHERE parseDateTimeBestEffortOrNull(nullIf(TenderedDate,'')) BETWEEN $__fromTime AND $__toTime
```
Smoke-test (a) trước; nếu lỗi, rơi về (b).

---

## 2. Biến template (Variables)

### Khai báo (Dashboard settings → Variables)

| Biến | Type | Query / value | Multi / All |
|---|---|---|---|
| `whseid` | Query | `SELECT DISTINCT whseid FROM analytics_workspace.mv_otif WHERE whseid != '' ORDER BY whseid` | ✅ / ✅ |
| `kenh` | Query | `SELECT DISTINCT group_name FROM analytics_workspace.mv_otif WHERE group_name != '' ORDER BY group_name` | ✅ / ✅ |
| `nvt` | Query | `SELECT DISTINCT ten_ngan_nha_van_tai FROM analytics_workspace.mv_otif WHERE ten_ngan_nha_van_tai != '' ORDER BY 1` | ✅ / ✅ |
| Date range | (native time picker) | — | — |

> Query variable cũng nên bọc `$__timeFilter` nếu danh sách phụ thuộc kỳ; thường để full để filter ổn định.

### Dùng trong panel — format & escape

| Cú pháp | Kết quả | Khi nào |
|---|---|---|
| `${whseid}` | `a,b,c` (raw) | hiếm — dễ vỡ với chuỗi có khoảng trắng |
| `${whseid:singlequote}` | `'a','b','c'` | **chuỗi → dùng cái này trong `IN (...)`** |
| `${whseid:csv}` | `a,b,c` | số |
| `${whseid:sqlstring}` | escape SQL | text tự do |

### `$__conditionalAll` — "All" không cần OR rườm rà
```sql
AND $__conditionalAll(whseid IN (${whseid:singlequote}), $whseid)
```
- Nếu user chọn "All" → macro bỏ luôn điều kiện (thành `1=1`).
- Nếu chọn cụ thể → áp `whseid IN ('a','b')`.
Đây là cách chuẩn để 1 panel filter được mọi dim mà không nhân bản query.

---

## 3. `format` của target — KHỚP loại panel

Field `format` trong target quyết định plugin trả time series hay table. **Enum đổi theo major version** — mở query inspector / docs plugin đã cài để xác nhận. Dấu hiệu sai:
- Time series panel báo "No data" dù SQL chạy ra số → sai `format` (đang ở table) hoặc thiếu cột `time` DateTime đầu tiên.
- Table panel gộp cột lạ → đang ở chế độ time series.

Checklist:
1. Time series: cột đầu là `DateTime`/`DateTime64` tên `time`, các cột sau là số → mỗi cột = 1 series.
2. Table: `format` table, mọi cột giữ nguyên.
3. Stat/Gauge: thường `format` table, panel tự lấy ô cuối/giá trị reduce.

---

## 4. Thresholds & màu RAG (field config, KHÔNG trong SQL)

Trong panel JSON, `fieldConfig.defaults.thresholds`:
```json
"thresholds": {
  "mode": "absolute",
  "steps": [
    { "color": "red",   "value": null },
    { "color": "yellow","value": 85 },
    { "color": "green", "value": 90 }
  ]
}
```
- "Lower is better" (lag, vi phạm, Δ): đảo bậc (`green` ở dưới, `red` ở trên) hoặc bật color scheme invert.
- Target line cho time series: thêm `fieldConfig.defaults.thresholds` + `custom.thresholdsStyle.mode = "line"` (hoặc `"area"` cho band).
- Per-field override (mỗi % một target khác nhau) qua `fieldConfig.overrides` matcher `byName`.

---

## 5. Performance (kế thừa /da-ch)

- **Đừng `SELECT *`** — chỉ cột panel cần (columnar).
- Filter chạm cột đầu `ORDER BY` của MV để prune granule; `$__timeFilter` trên cột partition (`toYYYYMM`) → skip part.
- `uniqExact(so)` cho số đơn (đối soát) · `uniqCombined` nếu panel chấp nhận ~1% sai số để nhanh.
- Set datasource "Max rows" / panel "Max data points" hợp lý — đừng kéo triệu dòng về browser.
- Dashboard refresh khớp MV refresh (5′) — auto-refresh ngắn hơn = đốt query vô ích.

---

## 6. Provisioning (Mode D)

`provisioning/datasources/clickhouse.yaml`:
```yaml
apiVersion: 1
datasources:
  - name: ClickHouse-analytics_workspace
    type: grafana-clickhouse-datasource
    access: proxy
    jsonData:
      host: ${CLICKHOUSE_HOST}
      port: 8443
      protocol: http        # HTTPS 8443 → protocol http + secure tls
      secure: true
      username: ${CLICKHOUSE_USER}
      defaultDatabase: analytics_workspace
    secureJsonData:
      password: ${CLICKHOUSE_PASSWORD}   # từ env, KHÔNG plaintext commit
```
`provisioning/dashboards/da.yaml`:
```yaml
apiVersion: 1
providers:
  - name: da-mondelez
    folder: 'DA / Mondelez'
    type: file
    options:
      path: /var/lib/grafana/dashboards/mondelez
```
> Mọi secret qua env substitution (`GF_...` hoặc `${VAR}`); không commit password. Khớp tên env với [`mondelez/.env`](../../../../mondelez/.env): `CLICKHOUSE_HOST/PORT/USER/PASSWORD/SECURE`.

---

## 7. Import / API (verify trước, không tự push)

- **UI**: Dashboards → Import → upload JSON → chọn datasource khi hỏi.
- **API** (chỉ khi user cấp token & đồng ý): `POST /api/dashboards/db` body `{"dashboard": <model>, "folderUid": "...", "overwrite": false}` header `Authorization: Bearer <token>`. Mặc định KHÔNG tự gọi — đây là hành động outward-facing.
