<#
.SYNOPSIS
  Sync da-* Claude Code skills between the local workspace and the helix_projects repo.

.DESCRIPTION
  Mirrors `.claude/skills/da-*/` folders between two locations on the same machine:
    SIDE A - workspace : <repo-root>/.claude/skills/           (your local skills, gitignored from main repo)
    SIDE B - projects  : <repo-root>/projects/.claude/skills/  (committed to helix_projects, shared with team)

  Only directories matching `da-*` are touched. Non-da skills (built-ins, _template, etc.) are ignored.

  Modes:
    push   - copy workspace -> projects (use when YOU updated a skill and want to share)
    pull   - copy projects  -> workspace (use after teammate pushed an update)
    check  - report drift, exit 1 if any (use in CI / pre-commit)

  Both push and pull are STRICT MIRRORS: extra da-* skills on the destination side are deleted.
  Run with -DryRun first to preview, or -Force to skip the confirmation prompt.

.EXAMPLE
  .\sync-da-skills.ps1 -Mode check
  .\sync-da-skills.ps1 -Mode push -DryRun
  .\sync-da-skills.ps1 -Mode pull -Force
#>

param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('push','pull','check')]
  [string]$Mode,

  [switch]$DryRun,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ---- Resolve paths ----------------------------------------------------------
$scriptDir     = Split-Path -Parent $PSCommandPath
$projectsRoot  = Split-Path -Parent $scriptDir
$workspaceRoot = Split-Path -Parent $projectsRoot

$workspaceSkills = Join-Path $workspaceRoot '.claude\skills'
$projectsSkills  = Join-Path $projectsRoot  '.claude\skills'

if (-not (Test-Path $workspaceSkills)) {
  Write-Error "Workspace skills folder not found: $workspaceSkills"
  exit 2
}
if (-not (Test-Path $projectsSkills)) {
  New-Item -ItemType Directory -Path $projectsSkills -Force | Out-Null
}

# ---- Helpers ----------------------------------------------------------------
function Get-DaSkillSnapshot {
  param([string]$Root)
  $result = @{}
  if (-not (Test-Path $Root)) { return $result }
  $daDirs = Get-ChildItem -Path $Root -Directory -Filter 'da-*' -ErrorAction SilentlyContinue
  foreach ($d in $daDirs) {
    $files = Get-ChildItem -Path $d.FullName -Recurse -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
      $rel = $f.FullName.Substring($Root.Length).TrimStart('\','/').Replace('\','/')
      $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash
      $result[$rel] = $hash
    }
  }
  return $result
}

function Compare-Snapshots {
  param($A, $B)
  $allKeys = ($A.Keys + $B.Keys) | Sort-Object -Unique
  $diffs = @()
  foreach ($k in $allKeys) {
    if (-not $A.ContainsKey($k))      { $diffs += [PSCustomObject]@{ Path=$k; Status='only-in-B' } }
    elseif (-not $B.ContainsKey($k))  { $diffs += [PSCustomObject]@{ Path=$k; Status='only-in-A' } }
    elseif ($A[$k] -ne $B[$k])        { $diffs += [PSCustomObject]@{ Path=$k; Status='differs'   } }
  }
  return $diffs
}

function Invoke-Mirror {
  param(
    [string]$Source,
    [string]$Destination,
    [switch]$DryRun
  )
  $excludeSrc = Get-ChildItem -Path $Source      -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike 'da-*' } | ForEach-Object { $_.FullName }
  $excludeDst = Get-ChildItem -Path $Destination -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike 'da-*' } | ForEach-Object { $_.FullName }
  $excludeAll = @($excludeSrc) + @($excludeDst) | Where-Object { $_ }

  $rcArgs = @($Source, $Destination, '/MIR', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/R:1', '/W:1')
  if ($excludeAll.Count -gt 0) { $rcArgs += '/XD'; $rcArgs += $excludeAll }
  if ($DryRun) { $rcArgs += '/L' }

  & robocopy @rcArgs | Out-Null
  if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}

# ---- Build snapshots --------------------------------------------------------

Write-Host ""
Write-Host "DA-SKILLS SYNC" -ForegroundColor Cyan
Write-Host "  Mode        : $Mode"
Write-Host "  Workspace   : $workspaceSkills"
Write-Host "  Projects    : $projectsSkills"
Write-Host ""

$snapA = Get-DaSkillSnapshot -Root $workspaceSkills
$snapB = Get-DaSkillSnapshot -Root $projectsSkills
$diffs = @(Compare-Snapshots -A $snapA -B $snapB)

if ($diffs.Count -eq 0) {
  Write-Host ("No drift. Both sides are identical ({0} files)." -f $snapA.Count) -ForegroundColor Green
  exit 0
}

Write-Host ("Drift detected - {0} file(s):" -f $diffs.Count) -ForegroundColor Yellow
$diffs | ForEach-Object {
  $tag = switch ($_.Status) {
    'only-in-A' { '+ workspace' }
    'only-in-B' { '+ projects ' }
    'differs'   { '~ differs  ' }
  }
  Write-Host "  $tag  $($_.Path)"
}
Write-Host ""

switch ($Mode) {
  'check' {
    Write-Host "FAIL: drift present. Run 'push' or 'pull' to reconcile." -ForegroundColor Red
    exit 1
  }
  'push' {
    Write-Host "Action: copy workspace -> projects (workspace wins)" -ForegroundColor Cyan
    if (-not $Force -and -not $DryRun) {
      $resp = Read-Host "Proceed? [y/N]"
      if ($resp -notmatch '^[yY]') { Write-Host "Aborted."; exit 0 }
    }
    Invoke-Mirror -Source $workspaceSkills -Destination $projectsSkills -DryRun:$DryRun
    if ($DryRun) {
      Write-Host "DRY RUN complete - no changes written." -ForegroundColor Yellow
    } else {
      Write-Host ('Pushed. Next: git -C "{0}" status  (then commit & push helix_projects)' -f $projectsRoot) -ForegroundColor Green
    }
    exit 0
  }
  'pull' {
    Write-Host "Action: copy projects -> workspace (projects wins)" -ForegroundColor Cyan
    if (-not $Force -and -not $DryRun) {
      $resp = Read-Host "Proceed? [y/N]"
      if ($resp -notmatch '^[yY]') { Write-Host "Aborted."; exit 0 }
    }
    Invoke-Mirror -Source $projectsSkills -Destination $workspaceSkills -DryRun:$DryRun
    if ($DryRun) {
      Write-Host "DRY RUN complete - no changes written." -ForegroundColor Yellow
    } else {
      Write-Host "Pulled. Restart Claude Code to pick up the updated skills." -ForegroundColor Green
    }
    exit 0
  }
}
