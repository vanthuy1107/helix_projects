"""
explore.py — Tra cứu tương tác Mondelez (thay 3 notebook .ipynb)
═══════════════════════════════════════════════════════════════
Chạy TỪNG CELL `# %%` bằng VSCode "Run Cell" / Shift+Enter (Jupyter Interactive) —
trải nghiệm như notebook nhưng là .py thuần: diff git sạch, không JSON, import da
như script, KHÔNG copy macro (hết divergence).

Đây CHỈ là nơi tra cứu tương tác (1 đơn / 1 chuyến / 1 ngày / 1 SO / ad-hoc). Phần
audit/reconcile chạy-định-kỳ-được → đã thành script trong scripts/ (xuất .md + .html):
  - scripts/otif_mtd_audit.py · scripts/flash_daily_audit.py
  - scripts/tms_report_25_audit.py · scripts/reconcile_tms_otif.py
  - scripts/run_all.py  → chạy hết + sinh reports/index.html

Quy ước (xem /da-py §1): VALUE tiếng Việt ('Hoàn tất', 'Xuất bán'...) bind qua
{x:String} — KHÔNG inline (chống corrupt UTF-8). Mã đơn/SO là ASCII → bind {x:String}.

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
# %% ⚠️ SETUP — CHẠY CELL NÀY TRƯỚC TIÊN (1 lần đầu phiên; nếu kernel báo
#    NameError: name 'da'/'client' is not defined → bạn quên chạy cell này)
import da
from da.macros import DT, NUM, ontime

cfg = da.load_tenant("mondelez")
client = da.ch_client(cfg)
da.setup_display()

TMS = cfg.table("tms_report_25")     # mdlz_tms_report_25_trip_order
OTIF = cfg.table("mv_otif")
FLASH = cfg.table("mv_flash")
GRACE = cfg.scope["ontime_grace_min"]
print(f"[OK] tenant={cfg.name} · TMS={TMS} · OTIF={OTIF} · FLASH={FLASH} · grace={GRACE}′")


# ════════════════════════════════════════════════════════════════════════════
# TMS report #25 — tra cứu chi tiết
# ════════════════════════════════════════════════════════════════════════════

# %% TMS · tra 1 ĐƠN theo OrderCode — giao nhận từng chuyến (KH vs thực giao)
ORDER_CODE = "8482517605"   # ← sửa mã đơn rồi Shift+Enter
da.run_df(client, f"""
    SELECT if(MasterCode = '', '(chưa lên chuyến)', MasterCode) AS chuyen,
           DeliveryStatus                                       AS tt_giao,
           round({NUM('QuantityOrder')}, 0)                     AS kh,
           round({NUM('QuantityBBGN')}, 0)                      AS giao_nhan,
           OrderStatus, VendorName, StockName, OPSLocationToProvince
    FROM {TMS} WHERE OrderCode = {{oc:String}} ORDER BY MasterCode
""", {"oc": ORDER_CODE})

# %% TMS · tra 1 CHUYẾN theo MasterCode — các đơn trong chuyến
MASTER_CODE = "DI0201457"   # ← sửa mã chuyến
da.run_df(client, f"""
    SELECT OrderCode                          AS don,
           DeliveryStatus                     AS tt_giao,
           round({NUM('QuantityOrder')}, 0)   AS kh,
           round({NUM('QuantityBBGN')}, 0)    AS giao_nhan,
           StockName, OPSLocationToProvince
    FROM {TMS} WHERE MasterCode = {{mc:String}} ORDER BY OrderCode
""", {"mc": MASTER_CODE})

# %% TMS · summary 1 NGÀY (theo TenderedDate / "Ngày gửi thầu")
DAY = "2026-05-19"   # ← sửa ngày YYYY-MM-DD
da.run_df(client, f"""
    SELECT uniqExact(OrderCode)                                              AS so_don,
           uniqExactIf(MasterCode, MasterCode != '')                        AS so_chuyen,
           round(100*countIf(DeliveryStatus={{done:String}})/count(), 1)     AS pct_da_giao,
           round(sum({NUM('QuantityOrder')}), 0)                            AS kh_qty,
           round(sum({NUM('QuantityBBGN')}), 0)                             AS gn_qty,
           round(100*countIf({ontime('DateToCome','ETA',GRACE)} AND DeliveryStatus={{done:String}})
                 /nullIf(countIf(DeliveryStatus={{done:String}}
                         AND {DT('DateToCome')} IS NOT NULL AND {DT('ETA')} IS NOT NULL),0),1) AS pct_ontime
    FROM {TMS}
    WHERE toDate({DT('TenderedDate')}) = toDate({{day:String}})
""", {"done": "Hoàn tất", "day": DAY})

# %% TMS · free query — sửa SQL tự do (nhớ bind value tiếng Việt qua {x:String})
da.run_df(client, f"""
    SELECT OrderCode, MasterCode, OrderStatus, DeliveryStatus,
           QuantityBBGN, OrderCreatedDate, ETD, ETA, DateToCome
    FROM {TMS} LIMIT 50
""")


# ════════════════════════════════════════════════════════════════════════════
# mv_otif — tra cứu 1 SO + drill
# ════════════════════════════════════════════════════════════════════════════

# %% OTIF · tra 1 SO — timeline (giờ VN) + volume + trạng thái OTIF
SO_LOOKUP = "8482509466"   # ← sửa mã SO
_d = da.run_df(client, f"""
    SELECT so, whseid, group_of_cago, group_name, customer_name, khu_vuc_doi_xe,
           ten_ngan_nha_van_tai,
           toDateTime(thoi_gian_gui_thau,'Asia/Ho_Chi_Minh')    AS ngay_gui_thau,
           toDateTime(etd_chuyen_gui_thau,'Asia/Ho_Chi_Minh')   AS etd,
           toDateTime(eta_giao_hang_cho_npp,'Asia/Ho_Chi_Minh') AS eta,
           toDateTime(actual_ship_date,'Asia/Ho_Chi_Minh')      AS actual_ship_vn,
           toDateTime(ata_den,'Asia/Ho_Chi_Minh')               AS ata_den_vn,
           dateDiff('minute', eta_giao_hang_cho_npp, ata_den)   AS tre_phut,
           round(toFloat64(sum_original_cse),2)       AS plan_cse,
           round(toFloat64(sum_shipped_cse),2)        AS shipped_cse,
           round(toFloat64(sum_san_luong_giao_cse),2) AS delivered_cse,
           ontime_status, infull_status, otif_status, not_ontime_reason, not_infull_reason
    FROM {OTIF} WHERE so = {{so:String}}
""", {"so": SO_LOOKUP})
_d.T if len(_d) else "Không tìm thấy SO."

# %% OTIF · drill OTIF=Failed dù Ontime+Infull (gap grace) trong 1 window
F, T = "2026-05-01", "2026-05-29"   # ← sửa window
da.run_df(client, f"""
    SELECT so, whseid, ten_ngan_nha_van_tai,
           toDateTime(eta_giao_hang_cho_npp,'Asia/Ho_Chi_Minh') AS eta,
           toDateTime(ata_den,'Asia/Ho_Chi_Minh')               AS ata,
           dateDiff('minute', eta_giao_hang_cho_npp, ata_den)   AS tre_phut,
           ontime_status, infull_status, otif_status
    FROM {OTIF}
    WHERE toDate(thoi_gian_gui_thau) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
      AND ontime_status='Ontime' AND infull_status='Infull' AND otif_status='Failed OTIF'
    ORDER BY tre_phut DESC LIMIT 100
""", {"f": F, "t": T})


# ════════════════════════════════════════════════════════════════════════════
# mv_flash_and_drop_report — ad-hoc
# ════════════════════════════════════════════════════════════════════════════

# %% FLASH · ad-hoc — lọc theo SO / whseid / e2e_label (bỏ comment dòng cần)
FA_FROM, FA_TO = "2026-05-01", "2026-05-29"
da.run_df(client, f"""
    SELECT so, orderlinenumber, whseid, customer_code, status, e2e_label,
           toDateTime(delivery_date_1,'Asia/Ho_Chi_Minh') AS gi_date,
           original_cse, shipped_cse, san_luong_giao_cse
    FROM {FLASH}
    WHERE toDate(delivery_date_1) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
      -- AND so = '...'
      -- AND whseid = 'NKD'
      -- AND e2e_label = {{lbl:String}}   -- nhớ thêm 'lbl' vào params nếu mở dòng này
    ORDER BY delivery_date_1 DESC, so
    LIMIT 100
""", {"f": FA_FROM, "t": FA_TO})
