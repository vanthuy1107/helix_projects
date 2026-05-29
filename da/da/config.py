"""
da.config
─────────
Nạp cấu hình cho một tenant: secret từ `.env` + cấu hình nghiệp vụ từ `da.toml`.

Triết lý: mọi thứ KHÁC NHAU giữa tenant (tên bảng vật lý, service scope, grace,
cột ngày mặc định, filter loại đơn) nằm trong `da.toml` — KHÔNG hardcode trong lõi.
Lõi chỉ chứa logic GIỐNG nhau mọi tenant. Đổi tenant = đổi config, không đổi code.
"""
from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

try:
    import tomllib  # Python 3.11+ stdlib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib  # type: ignore


@dataclass(frozen=True)
class ChCreds:
    """Credential ClickHouse đọc từ .env (KHÔNG bao giờ hardcode/commit)."""
    host: str
    port: int
    user: str
    password: str
    secure: bool


@dataclass(frozen=True)
class TenantConfig:
    name: str            # "mondelez"
    root: Path           # .../mondelez
    database: str        # "analytics_workspace"
    ch: ChCreds
    tables: dict         # logical name -> physical table (từ da.toml)
    scope: dict          # grace, so_valid, otif_service, default_date_col... (từ da.toml)

    def table(self, logical: str) -> str:
        """Tên bảng vật lý fully-qualified `db`.`tbl` cho một logical name.
        Không tìm thấy mapping → coi logical chính là tên bảng vật lý."""
        phys = self.tables.get(logical, logical)
        return f"`{self.database}`.`{phys}`"


_REQUIRED_ENV = ("CLICKHOUSE_HOST", "CLICKHOUSE_USER", "CLICKHOUSE_PASSWORD")


def _find_tenant_dir(name: str | None) -> Path:
    """Tìm thư mục tenant chứa `.env`, đi lên dần từ CWD.

    Hỗ trợ layout: <root>/<name>/.env, <root>/projects/<name>/.env,
    hoặc đang đứng ngay trong thư mục tenant (CWD.name == name).
    name=None → lấy `.env` gần nhất (tenant hiện tại).
    """
    here = Path.cwd().resolve()
    for d in [here, *here.parents]:
        if name:
            if d.name == name and (d / ".env").exists():
                return d
            if (d / name / ".env").exists():
                return d / name
            if (d / "projects" / name / ".env").exists():
                return d / "projects" / name
        elif (d / ".env").exists():
            return d
    raise FileNotFoundError(
        f"Không tìm thấy thư mục tenant{f' {name!r}' if name else ''} có .env "
        f"(bắt đầu dò từ {here})."
    )


def validate_env(env_path: Path) -> None:
    """Fail-fast nếu thiếu CLICKHOUSE_* — báo rõ thiếu key nào, ở file nào.
    Phát hiện lỗi env NGAY, không để chết giữa chừng query."""
    missing = [k for k in _REQUIRED_ENV if not os.getenv(k)]
    if missing:
        print(f"[ERROR] Thiếu env trong {env_path}: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)


def load_tenant(name_or_path: str | Path | None = None) -> TenantConfig:
    """Nạp TenantConfig: `.env` (secret) + `da.toml` (config nghiệp vụ).

    name_or_path:
      - None         → tìm .env gần nhất đi lên từ CWD (tenant hiện tại)
      - "mondelez"   → tìm thư mục tenant tên 'mondelez'
      - Path(...)    → dùng trực tiếp thư mục đó
    """
    root = name_or_path.resolve() if isinstance(name_or_path, Path) \
        else _find_tenant_dir(name_or_path)

    env_path = root / ".env"
    load_dotenv(env_path if env_path.exists() else None)
    validate_env(env_path)

    toml_path = root / "da.toml"
    cfg = tomllib.loads(toml_path.read_text(encoding="utf-8")) if toml_path.exists() else {}

    ch = ChCreds(
        host=os.getenv("CLICKHOUSE_HOST", ""),
        port=int(os.getenv("CLICKHOUSE_PORT", "8443")),
        user=os.getenv("CLICKHOUSE_USER", ""),
        password=os.getenv("CLICKHOUSE_PASSWORD", ""),
        secure=os.getenv("CLICKHOUSE_SECURE", "true").lower() not in ("false", "0", "no"),
    )
    return TenantConfig(
        name=root.name,
        root=root,
        database=cfg.get("database", "analytics_workspace"),
        ch=ch,
        tables=cfg.get("tables", {}),
        scope=cfg.get("scope", {}),
    )
