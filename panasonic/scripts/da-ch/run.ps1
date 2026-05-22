<#
.SYNOPSIS
    Chạy SQL script .sql trên ClickHouse Cloud cho dự án Panasonic.

.DESCRIPTION
    Đọc credential từ projects/panasonic/.env (ưu tiên) hoặc projects/mondelez/.env (fallback).
    POST SQL qua HTTPS API (cổng 8443), in kết quả ra stdout với format `PrettyCompactMonoBlock` mặc định.

.PARAMETER File
    Đường dẫn .sql file cần chạy (tương đối hoặc tuyệt đối).

.PARAMETER Format
    Output format của ClickHouse. Mặc định PrettyCompactMonoBlock (đẹp cho terminal).
    Thường dùng: PrettyCompactMonoBlock, JSONEachRow, TSVWithNames, CSVWithNames, Vertical.

.PARAMETER Database
    Database mặc định trong session (mặc định: analytics_workspace).

.PARAMETER Out
    Tùy chọn: ghi output ra file thay vì stdout.

.EXAMPLE
    .\run.ps1 -File .\core\C00_profile-psv.ch.sql

.EXAMPLE
    .\run.ps1 -File .\core\C01_psv-summary.ch.sql -Format CSVWithNames -Out .\out\summary.csv

.EXAMPLE
    "SELECT count() FROM psv_target FINAL" | .\run.ps1 -Format JSONEachRow
#>
[CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [string]$File,

    [string]$Format = 'PrettyCompactMonoBlock',
    [string]$Database = 'analytics_workspace',
    [string]$Out,
    [int]$TimeoutSec = 120,
    [int]$MaxRows = 100000
)

$ErrorActionPreference = 'Stop'

# ─── Load .env ─────────────────────────────────────────────────────
function Load-DotEnv {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*#') { return }
        if ($_ -match '^\s*$') { return }
        if ($_ -match '^\s*(CLICKHOUSE_[A-Z_]+)\s*=\s*(.*?)\s*$') {
            $key = $Matches[1]
            # Strip surrounding quotes + trailing CR (Windows CRLF .env files)
            $val = $Matches[2].TrimEnd("`r").Trim('"').Trim("'")
            Set-Item -Path "env:$key" -Value $val
        }
    }
    return $true
}

$scriptDir = Split-Path -Parent $PSCommandPath
$projectDir = Resolve-Path (Join-Path $scriptDir '..\..')

$envPanasonic = Join-Path $projectDir '.env'
$envMondelez = Resolve-Path (Join-Path $projectDir '..\mondelez\.env') -ErrorAction SilentlyContinue

$envLoaded = $false
if (Test-Path $envPanasonic) {
    $envLoaded = Load-DotEnv $envPanasonic
    Write-Verbose "Loaded .env from: $envPanasonic"
} elseif ($envMondelez) {
    $envLoaded = Load-DotEnv $envMondelez.Path
    Write-Verbose "Loaded .env from: $($envMondelez.Path) (fallback)"
}

if (-not $env:CLICKHOUSE_HOST -or -not $env:CLICKHOUSE_USER -or -not $env:CLICKHOUSE_PASSWORD) {
    Write-Error "Thiếu CLICKHOUSE_HOST / CLICKHOUSE_USER / CLICKHOUSE_PASSWORD. Tạo projects/panasonic/.env từ .env.example."
    exit 1
}

# ─── Read SQL ──────────────────────────────────────────────────────
$sql = $null
if ($File) {
    if (-not (Test-Path $File)) {
        Write-Error "File not found: $File"
        exit 1
    }
    $sql = Get-Content -Raw -Path $File
} elseif ($MyInvocation.ExpectingInput) {
    $sql = ($input | Out-String).Trim()
} else {
    Write-Error "Cần truyền -File <path> hoặc pipe SQL string."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($sql)) {
    Write-Error "SQL trống."
    exit 1
}

# ─── Build URL ─────────────────────────────────────────────────────
$port = if ($env:CLICKHOUSE_PORT) { $env:CLICKHOUSE_PORT } else { '8443' }
$secure = if ($env:CLICKHOUSE_SECURE -eq 'false') { 'http' } else { 'https' }

$query = @{
    database = $Database
    default_format = $Format
    max_execution_time = $TimeoutSec
    max_result_rows = $MaxRows
}
$queryString = ($query.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
$url = "$secure`://$env:CLICKHOUSE_HOST`:$port/?$queryString"

# ─── Auth ──────────────────────────────────────────────────────────
$pair = "$env:CLICKHOUSE_USER`:$env:CLICKHOUSE_PASSWORD"
$basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{ Authorization = "Basic $basic"; 'Content-Type' = 'text/plain; charset=utf-8' }

# ─── Run ───────────────────────────────────────────────────────────
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $result = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $sql -TimeoutSec ($TimeoutSec + 30)
} catch {
    Write-Host ""
    Write-Host "[ClickHouse error] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
$sw.Stop()

# ─── Output ────────────────────────────────────────────────────────
if ($Out) {
    $outDir = Split-Path -Parent $Out
    if ($outDir -and -not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }
    $result | Out-File -Encoding utf8 -FilePath $Out
    Write-Host "  ✓ Saved → $Out  ($([math]::Round($sw.Elapsed.TotalSeconds, 2))s)"
} else {
    $result
    Write-Host ""
    Write-Host "  ⏱  $([math]::Round($sw.Elapsed.TotalSeconds, 2))s" -ForegroundColor DarkGray
}
