# Triage status distribution — auto-generated

_Total tracked: 212 items (from 2026-05-09 triage of `Edit UX_UI_MDLZ.xlsx`)_


## By status prefix

| Prefix | Count | % | Meaning |
|---|---|---|---|
| `[D]` | 170 | 80.2% | Done — fixed by SLG, MDLZ verified |
| `[W]` | 29 | 13.7% | WIP — đang làm hoặc pending dev pickup |
| `[U]` | 13 | 6.1% | Unmapped — raw status không khớp convention, cần BA clarify |
| **Total** | **212** | 100% | |


## By tech_layer (guess from heuristic)

| Tech layer | Count |
|---|---|
| `backend-config` | 12 |
| `cross-stack` | 1 |
| `etl-data` | 2 |
| `frontend-config` | 97 |
| `frontend-widget` | 79 |
| `unknown` | 21 |

## By folder

| Folder | Count |
|---|---|
| `bugs/unknown/` | 2 |
| `discoveries/etl-data/` | 2 |
| `discoveries/frontend-config/` | 5 |
| `discoveries/frontend-widget/` | 16 |
| `discoveries/unknown/` | 3 |
| `prd-asks/backend-config/` | 12 |
| `prd-asks/cross-stack/` | 1 |
| `prd-asks/frontend-config/` | 92 |
| `prd-asks/frontend-widget/` | 63 |
| `prd-asks/unknown/` | 16 |

## Notes

- `tech_layer` là **guess heuristic** từ keyword trong item text. Khi review từng stub, có thể override (đổi folder).
- Move stub giữa folder = thay đổi tech_layer. Re-run `regen-indexes.py` sau khi move.
- Khi 1 `[W]` chuyển thành `[D]`: rename file (`mv '[W]-...'.md '[D]-...'.md`) + thêm history row + re-run script.
