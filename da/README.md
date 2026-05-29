# `da` — Thư viện Data Analysis dùng chung (đa tenant)

Lõi tenant-agnostic cho mọi notebook/script DA của Smartlog Control Tower. Diệt copy-paste
boilerplate (kết nối ClickHouse, macro SQL, reconcile, export) — một nguồn chân lý, mọi tenant
(`mondelez/`, `panasonic/`, …) import chung.

> Kiến trúc & lộ trình đầy đủ: [`mondelez/03-build/da-python-platform-plan.md`](../mondelez/03-build/da-python-platform-plan.md)

## Cài (editable — chạy 1 lần)

```bash
pip install -e ./da[viz,excel]      # từ thư mục gốc helix-projects/
```

Sau đó ở bất kỳ notebook/script nào: `import da` — không cần `sys.path` hack.

## Dùng nhanh

```python
import da
cfg    = da.load_tenant("mondelez")          # .env (secret) + mondelez/da.toml (config)
client = da.ch_client(cfg)

# Giá trị (ngày, chuỗi tiếng Việt) → bind server-side; định danh (bảng/cột) → f-string
df = da.run_df(client,
    f"SELECT count() c FROM {cfg.table('mv_otif')} "
    f"WHERE otif_status = {{svc:String}}",
    {"svc": "Xuất bán"})

da.save_md([ "## Kết quả", df ], cfg.root / "reports" / "demo.md")
```

## Module

| Module | Vai trò |
|---|---|
| `da.config` | `load_tenant()` → `TenantConfig` (.env + da.toml), `validate_env()` |
| `da.ch` | `ch_client()`, `run_df()`, `meta()` (freshness) |
| `da.macros` | `DT()`, `NUM()`, `ontime()` — fragment SQL generic |
| `da.reconcile` | `align_grain`, `full_outer_by`, `delta_flags`, `reconcile_by_day` |
| `da.report` | `save_md()`, `setup_display()`, `PALETTE` |
| `da.cli` | `build_parser()`, `resolve()` — scaffold script CLI |

## Quy ước binding (chống corrupt UTF-8)

- **VALUE** (ngày, chuỗi tiếng Việt) → `params={"x": "Xuất bán"}` + placeholder `{x:String}`.
- **IDENTIFIER** (tên bảng/cột) + mảnh SQL → f-string ở call site (clickhouse-connect chỉ bind value).
