"""
DA Assessment — Anonymize raw CSVs from Mondelez ClickHouse → AcmeFoods fictional dataset.

Usage:
    cd projects/assessments/da/dataset/_internal/
    python anonymize.py

Input  : ./raw/{shipments,trips,carriers,locations,products}_raw.csv
Output : ../{shipments,trips,carriers,locations,products}.csv  + ./mapping.csv

Anonymization principles:
- Deterministic (seeded) — same raw value → same fake value across runs and files.
- Preserve cardinality and distribution (top carrier vẫn top, không reshuffle volume).
- Preserve dates, numeric measurements, statuses (OTIF flags) — KHÔNG đụng số liệu phân tích.
- Mask: carrier names, warehouse codes, MDLZ brand names (Oreo, Cosy, etc), pickup location names.
- Keep: VN region names (Ha Noi, Mekong, etc — public geo), generic FMCG terms (FRESH, DRY, MT, GT, etc), vehicle types (5T, 10T, etc).
- Translate: VN status labels (`Không có dữ liệu STM` → `Unknown`).

Sanity check sau khi chạy (verify zero leak):
    grep -ril -E 'mondelez|mdlz|oreo|cadbury|kinh do|kinh đô|trung thu|tết|solite|cosy|afc|ritz|toblerone|BKD|NKD' ../*.csv
"""

from __future__ import annotations
import csv
import hashlib
import random
import sys
from pathlib import Path

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
SEED = 20260516
RAW_DIR = Path(__file__).parent / "raw"
OUT_DIR = Path(__file__).parent.parent
MAPPING_FILE = Path(__file__).parent / "mapping.csv"

CARRIER_NAME_POOL = [
    "Nam Phat Logistics", "Truong Hai Transport", "Viet Tin Express",
    "Hoang Long Trucking", "Dai Nam Forwarding", "Phuong Bac Cargo",
    "Sai Gon Movers", "Tan Thanh Freight", "Bao Tin Logistics",
    "An Khang Transport", "Minh Quang Express", "Hung Vuong Trucking",
    "Phu Cuong Cargo", "Thai Binh Freight", "Dong A Logistics",
]

BRAND_NAME_POOL = [
    "Sunbite", "Crispero", "Velvetta", "Cocoluxe", "Mintway",
    "Goldcrunch", "Berryfizz", "Honeystix", "Snowflake", "Caramelo",
    "Choconova", "Vanilline", "Fruitello", "Wafercrest", "Sweetnook",
]

WAREHOUSE_NAME_TEMPLATE = "{region} DC {n:02d}"

# Brand names we MUST mask (case-insensitive, normalized lowercase).
# Any raw brand_code containing one of these → forced to anonymize pool.
MDLZ_BRAND_KEYWORDS = {
    "oreo", "cosy", "afc", "ritz", "lu", "solite", "kd", "kinh do", "kinh đô",
    "slide", "tết", "tet", "trung thu", "toblerone", "cadbury", "milka",
    "biscuit lu", "mondelez", "mdlz",
}

# VN region names — KEEP as is (public geo, not MDLZ-specific).
# We don't mask these because masking would destroy realistic regional pattern.
VN_REGION_PASSTHROUGH = True

# Status label translation (VN → EN) for assessment audience.
STATUS_TRANSLATION = {
    "Không có dữ liệu STM": "Unknown",
    "Ontime": "Ontime",
    "Failed Ontime": "Late",
    "Infull": "Infull",
    "Failed Infull": "Short",
    "OTIF": "OTIF",
    "Failed OTIF": "Not OTIF",
    "": "Unknown",
}


# -----------------------------------------------------------------------------
# Deterministic mapping store
# -----------------------------------------------------------------------------
class MappingStore:
    def __init__(self, seed: int):
        self.seed = seed
        self._maps: dict[str, dict[str, str]] = {}
        self._rng_state: dict[str, random.Random] = {}

    def _rng(self, namespace: str) -> random.Random:
        if namespace not in self._rng_state:
            ns_seed = int(hashlib.sha256(f"{self.seed}:{namespace}".encode()).hexdigest()[:8], 16)
            self._rng_state[namespace] = random.Random(ns_seed)
        return self._rng_state[namespace]

    def map(self, namespace: str, raw_value: str, fake_generator) -> str:
        if raw_value is None or raw_value == "":
            return ""
        bucket = self._maps.setdefault(namespace, {})
        if raw_value not in bucket:
            bucket[raw_value] = fake_generator(self._rng(namespace), len(bucket))
        return bucket[raw_value]

    def export(self, path: Path) -> None:
        with path.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["namespace", "raw_value", "fake_value"])
            for ns, bucket in sorted(self._maps.items()):
                for raw, fake in sorted(bucket.items()):
                    w.writerow([ns, raw, fake])


# -----------------------------------------------------------------------------
# Fake generators per namespace
# -----------------------------------------------------------------------------
def gen_carrier_code(rng, idx):
    return f"CAR{idx + 1:03d}"

def gen_carrier_name(rng, idx):
    if idx < len(CARRIER_NAME_POOL):
        return CARRIER_NAME_POOL[idx]
    return f"Generic Carrier {idx + 1}"

def gen_warehouse_code(rng, idx):
    return f"WH{idx + 1:03d}"

def gen_warehouse_name(rng, idx):
    regions = ["North", "Central", "South"]
    return WAREHOUSE_NAME_TEMPLATE.format(region=regions[idx % 3], n=(idx // 3) + 1)

def gen_pickup_location(rng, idx):
    return f"Hub-{idx + 1:02d}"

def gen_brand(rng, idx):
    if idx < len(BRAND_NAME_POOL):
        return BRAND_NAME_POOL[idx]
    return f"Brand-{idx + 1:03d}"

def gen_shipment_id(rng, idx):
    return f"SH-2026-{idx + 1:06d}"

def gen_trip_id(rng, idx):
    return f"TR-2026-{idx + 1:06d}"


def is_mdlz_brand(name: str) -> bool:
    """Check if a brand name matches known MDLZ keywords."""
    if not name:
        return False
    lo = name.lower().strip()
    return any(kw in lo for kw in MDLZ_BRAND_KEYWORDS)


def translate_status(raw: str) -> str:
    return STATUS_TRANSLATION.get(raw, raw if raw else "Unknown")


# -----------------------------------------------------------------------------
# Anonymization per file
# -----------------------------------------------------------------------------
def anonymize_shipments(rows, store):
    """Output candidate-facing shipments.csv.

    NOTE: ontime/infull/otif status columns are intentionally DROPPED — they
    are pre-computed answers that would trivialize Phase 2 aggregation. The
    candidate must derive their own KPIs from timestamps + quantities.

    Source status values are exported separately to _internal/expected_status.csv
    for reviewer benchmarking only (NOT shared with candidate)."""
    out = []
    for r in rows:
        out.append({
            "shipment_id":       store.map("shipment", r["shipment_id_raw"], gen_shipment_id),
            "warehouse_code":    store.map("warehouse_code", r["warehouse_code_raw"], gen_warehouse_code),
            "delivery_area":     r["delivery_area_raw"],
            "cargo_group":       r["cargo_group_raw"],
            "carrier_code":      store.map("carrier_code", r["carrier_code_raw"], gen_carrier_code) if r["carrier_code_raw"] else "",
            "sales_channel":     r["sales_channel_raw"],
            "vehicle_type":      r["vehicle_type_raw"],
            "gi_date":           r["gi_date"],
            "etd_planned":       r["etd_planned"],
            "eta_planned":       r["eta_planned"],
            "atd_actual":        r["atd_actual"],
            "ata_actual":        r["ata_actual"],
            "planned_qty_cse":   r["planned_qty_cse"],
            "planned_weight_kg": r["planned_weight_kg"],
            "planned_volume_cbm":r["planned_volume_cbm"],
            "planned_pallets":   r["planned_pallets"],
            "delivered_qty_cse": r["delivered_qty_cse"],
        })
    return out

def export_expected_status(rows, store, out_path: Path):
    """Reviewer-only file: shipment_id -> source-computed status.
    Used to benchmark candidate's derived KPIs."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["shipment_id", "ontime_status", "infull_status", "otif_status"])
        for r in rows:
            ship_id = store.map("shipment", r["shipment_id_raw"], gen_shipment_id)
            w.writerow([
                ship_id,
                translate_status(r["ontime_status_raw"]),
                translate_status(r["infull_status_raw"]),
                translate_status(r["otif_status_raw"]),
            ])

def anonymize_trips(rows, store):
    out = []
    for r in rows:
        out.append({
            "trip_id":           store.map("trip", r["trip_id_raw"], gen_trip_id),
            "tender_date":       r["tender_date"],
            "eta_operation":     r["eta_operation"],
            "ata_operation":     r["ata_operation"],
            "pickup_location":   store.map("pickup_location", r["pickup_location_raw"], gen_pickup_location) if r["pickup_location_raw"] else "",
            "delivery_area":     r["delivery_area_raw"],  # KEEP
            "carrier_code":      store.map("carrier_code", r["carrier_code_raw"], gen_carrier_code) if r["carrier_code_raw"] else "",
            "vehicle_type":      r["vehicle_type_raw"],
            "cargo_group":       _clean_audience_text(r["cargo_group_raw"]),
            "vfr_pct":           r["vfr_pct"],
            "vfr_by_ton":        r["vfr_by_ton"],
            "vfr_by_volume":     r["vfr_by_volume"],
            "planned_ton":       r["planned_ton"],
            "planned_cbm":       r["planned_cbm"],
        })
    return out

def anonymize_carriers(rows, store):
    out = []
    for r in rows:
        if not r["carrier_code_raw"]:
            continue
        code = store.map("carrier_code", r["carrier_code_raw"], gen_carrier_code)
        name = store.map("carrier_name", r["carrier_short_name_raw"], gen_carrier_name)
        out.append({
            "carrier_code": code,
            "carrier_name": name,
        })
    return out

def anonymize_locations(rows, store):
    out = []
    for r in rows:
        t = r["location_type"]
        if t == "WAREHOUSE":
            code = store.map("warehouse_code", r["location_code_raw"], gen_warehouse_code)
            name = store.map("warehouse_name", r["location_name_raw"], gen_warehouse_name)
        elif t == "PICKUP_LOCATION":
            code = store.map("pickup_location", r["location_code_raw"], gen_pickup_location)
            name = code
        else:  # DELIVERY_AREA
            code = r["location_code_raw"]  # KEEP — VN public geo
            name = r["location_name_raw"]
        out.append({
            "location_type": t,
            "location_code": code,
            "location_name": name,
            "location_group": r["location_group_raw"],
        })
    return out

def anonymize_products(rows, store):
    out = []
    seen = set()
    for r in rows:
        if r["dim_type"] == "BRAND_CARGO":
            raw_code = r["code_raw"]
            # Force-mask anything MDLZ-recognizable
            if is_mdlz_brand(raw_code):
                code = store.map("brand", raw_code, gen_brand)
                name = code
            elif raw_code == "Other":
                code = "Other"
                name = "Other"
            else:
                code = store.map("brand", raw_code, gen_brand)
                name = code
            row = (r["dim_type"], code, r["parent_group_raw"])
            if row in seen:
                continue
            seen.add(row)
            out.append({
                "dim_type":     "BRAND_CARGO",
                "code":         code,
                "name":         name,
                "parent_group": r["parent_group_raw"],
            })
        else:  # SALES_CHANNEL
            out.append({
                "dim_type":     "SALES_CHANNEL",
                "code":         r["code_raw"],  # KEEP — generic
                "name":         r["name_raw"],
                "parent_group": "",
            })
    return out


# -----------------------------------------------------------------------------
# IO helpers
# -----------------------------------------------------------------------------
CH_NULL_MARKER = "\\N"  # ClickHouse exports NULL as literal "\N" in CSV

def _has_non_ascii(s: str) -> bool:
    return any(ord(c) > 127 for c in s)

def _normalize_null(v: str) -> str:
    return "" if v == CH_NULL_MARKER else v

def _clean_audience_text(v: str) -> str:
    """For fields that pass through to candidate without going through the
    deterministic mapping (vd trips.cargo_group denormalized as 'X, Y, Z'):
    drop non-ASCII tokens, fall back to 'Other' if nothing remains.
    DO NOT apply to mapping-key fields — would collapse distinct raws."""
    if not v or not _has_non_ascii(v):
        return v
    if "," in v:
        parts = [p.strip() for p in v.split(",")]
        parts = [p for p in parts if p and not _has_non_ascii(p)]
        return ", ".join(parts) if parts else "Other"
    return "Other"

def read_csv(path: Path):
    """Normalize \\N → '' on every cell. Leave non-ASCII intact so mapping-key
    fields (warehouse names, brand codes, pickup locations) stay distinct.
    Non-ASCII cleaning is applied selectively per-field in anonymize_*()."""
    rows = []
    with path.open(newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rows.append({k: _normalize_null(v) for k, v in r.items()})
    return rows

def write_csv(path: Path, rows, fieldnames):
    """Write CSV with UTF-8 BOM so Excel on Windows opens correctly."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main():
    if not RAW_DIR.exists():
        print(f"ERROR: raw dir not found: {RAW_DIR}", file=sys.stderr)
        sys.exit(1)

    store = MappingStore(seed=SEED)

    jobs = [
        ("shipments_raw.csv", "shipments.csv", anonymize_shipments,
         ["shipment_id", "warehouse_code", "delivery_area", "cargo_group", "carrier_code",
          "sales_channel", "vehicle_type", "gi_date", "etd_planned", "eta_planned",
          "atd_actual", "ata_actual",
          "planned_qty_cse", "planned_weight_kg", "planned_volume_cbm",
          "planned_pallets", "delivered_qty_cse"]),

        ("trips_raw.csv", "trips.csv", anonymize_trips,
         ["trip_id", "tender_date", "eta_operation", "ata_operation",
          "pickup_location", "delivery_area", "carrier_code", "vehicle_type",
          "cargo_group", "vfr_pct", "vfr_by_ton", "vfr_by_volume",
          "planned_ton", "planned_cbm"]),

        ("carriers_raw.csv", "carriers.csv", anonymize_carriers,
         ["carrier_code", "carrier_name"]),

        ("locations_raw.csv", "locations.csv", anonymize_locations,
         ["location_type", "location_code", "location_name", "location_group"]),

        ("products_raw.csv", "products.csv", anonymize_products,
         ["dim_type", "code", "name", "parent_group"]),
    ]

    shipments_raw_rows = None
    for raw_name, out_name, fn, fields in jobs:
        raw_path = RAW_DIR / raw_name
        if not raw_path.exists():
            print(f"  [skip] {raw_name} not found")
            continue
        rows_in = read_csv(raw_path)
        if raw_name == "shipments_raw.csv":
            shipments_raw_rows = rows_in
        rows_out = fn(rows_in, store)
        out_path = OUT_DIR / out_name
        write_csv(out_path, rows_out, fields)
        print(f"  [ok] {raw_name} ({len(rows_in)} rows) -> {out_name} ({len(rows_out)} rows)")

    # Export expected status (reviewer-only) — must run after shipment mappings created
    if shipments_raw_rows is not None:
        expected_path = Path(__file__).parent / "expected_status.csv"
        export_expected_status(shipments_raw_rows, store, expected_path)
        print(f"  [ok] expected_status.csv (reviewer-only) -> {expected_path.name}")

    store.export(MAPPING_FILE)
    print(f"\nMapping exported: {MAPPING_FILE}")


if __name__ == "__main__":
    main()
