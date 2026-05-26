<#
.SYNOPSIS
  Sync da-* Claude Code skills and commands between the local workspace and the helix_projects repo.

.DESCRIPTION
  Mirrors two parts of .claude/ between two locations on the same machine:
    SIDE A - workspace : <repo-root>/.claude/           (your local Claude assets, gitignored from main repo)
    SIDE B - projects  : <repo-root>/projects/.claude/  (committed to helix_projects, shared with team)

  Scope (only these are touched):
    skills    : .claude/skills/da-*/        (whole directories)
    commands  : .claude/commands/da-*.md    (single files)

  Non-da assets (built-ins, _template, etc.) are ignored on both sides.

  Modes:
    push   - copy workspace -> projects (use when YOU updated an asset and want to share)
    pull   - copy projects  -> workspace (use after teammate pushed an update)
    check  - report drift, exit 1 if any (use in CI / pre-commit)

  Both push and pull are STRICT MIRRORS: extra da-* assets on the destination side are deleted.
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

$pairs = @(
  [PSCustomObject]@{
    Name      = 'skills'
    Workspace = (Join-Path $workspaceRoot '.claude\skills')
    Projects  = (Join-Path $projectsRoot  '.claude\skills')
    Scope     = 'dir-da'   # enumerate da-* directories, hash all files inside
  },
  [PSCustomObject]@{
    Name      = 'commands'
    Workspace = (Join-Path $workspaceRoot '.claude\commands')
    Projects  = (Join-Path $projectsRoot  '.claude\commands')
    Scope     = 'file-da'  # enumerate da-*.md files directly
  }
)

# Ensure destination folders exist on both sides (safe no-op if already present)
foreach ($p in $pairs) {
  foreach ($side in @($p.Workspace, $p.Projects)) {
    if (-not (Test-Path $side)) { New-Item -ItemType Directory -Path $side -Force | Out-Null }
  }
}

# ---- Helpers ----------------------------------------------------------------
function Get-DaSnapshot {
  param(
    [string]$Root,
    [string]$Scope,
    [string]$Prefix  # e.g. "skills/" or "commands/" - keys returned are <Prefix><relative-path>
  )
  $result = @{}
  if (-not (Test-Path $Root)) { return $result }

  if ($Scope -eq 'dir-da') {
    $daDirs = Get-ChildItem -Path $Root -Directory -Filter 'da-*' -ErrorAction SilentlyContinue
    foreach ($d in $daDirs) {
      $files = Get-ChildItem -Path $d.FullName -Recurse -File -ErrorAction SilentlyContinue
      foreach ($f in $files) {
        $rel  = $f.FullName.Substring($Root.Length).TrimStart('\','/').Replace('\','/')
        $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash
        $result[$Prefix + $rel] = $hash
      }
    }
  }
  elseif ($Scope -eq 'file-da') {
    $daFiles = Get-ChildItem -Path $Root -File -Filter 'da-*.md' -ErrorAction SilentlyContinue
    foreach ($f in $daFiles) {
      $rel  = $f.Name
      $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash
      $result[$Prefix + $rel] = $hash
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

function Invoke-MirrorDirDa {
  # Mirror only da-* subdirectories of $Source into $Destination using robocopy /MIR
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
    Write-Error "robocopy failed with exit code $LASTEXITCODE for $Source -> $Destination"
    exit $LASTEXITCODE
  }
}

function Invoke-MirrorFileDa {
  # Strict-mirror da-*.md files at the top level of $Source into $Destination
  param(
    [string]$Source,
    [string]$Destination,
    [switch]$DryRun
  )
  $srcFiles = @(Get-ChildItem -Path $Source      -File -Filter 'da-*.md' -ErrorAction SilentlyContinue)
  $dstFiles = @(Get-ChildItem -Path $Destination -File -Filter 'da-*.md' -ErrorAction SilentlyContinue)

  # Delete files on destination that don't exist on source (strict mirror semantics)
  foreach ($df in $dstFiles) {
    if (-not ($srcFiles | Where-Object { $_.Name -eq $df.Name })) {
      if ($DryRun) {
        Write-Host "  [dry] would delete: $($df.FullName)"
      } else {
        Remove-Item -Path $df.FullName -Force
      }
    }
  }

  # Copy each source file over
  foreach ($sf in $srcFiles) {
    $target = Join-Path $Destination $sf.Name
    $needCopy = $true
    if (Test-Path $target) {
      $srcHash = (Get-FileHash -Algorithm SHA256 -Path $sf.FullName).Hash
      $tgtHash = (Get-FileHash -Algorithm SHA256 -Path $target).Hash
      if ($srcHash -eq $tgtHash) { $needCopy = $false }
    }
    if ($needCopy) {
      if ($DryRun) {
        Write-Host "  [dry] would copy:   $($sf.FullName) -> $target"
      } else {
        Copy-Item -Path $sf.FullName -Destination $target -Force
      }
    }
  }
}

function Invoke-PairMirror {
  param($Pair, [string]$Direction, [switch]$DryRun)
  if ($Direction -eq 'push') { $src = $Pair.Workspace; $dst = $Pair.Projects }
  else                       { $src = $Pair.Projects;  $dst = $Pair.Workspace }

  switch ($Pair.Scope) {
    'dir-da'  { Invoke-MirrorDirDa  -Source $src -Destination $dst -DryRun:$DryRun }
    'file-da' { Invoke-MirrorFileDa -Source $src -Destination $dst -DryRun:$DryRun }
  }
}

# ---- Build snapshots --------------------------------------------------------

Write-Host ""
Write-Host "DA-ASSETS SYNC" -ForegroundColor Cyan
Write-Host "  Mode        : $Mode"
foreach ($p in $pairs) {
  Write-Host ("  {0,-9}   : {1}" -f $p.Name, $p.Workspace)
  Write-Host ("  {0,-9} mirror : {1}" -f $p.Name, $p.Projects)
}
Write-Host ""

$snapA = @{}
$snapB = @{}
foreach ($p in $pairs) {
  $prefix = $p.Name + '/'
  (Get-DaSnapshot -Root $p.Workspace -Scope $p.Scope -Prefix $prefix).GetEnumerator() | ForEach-Object { $snapA[$_.Key] = $_.Value }
  (Get-DaSnapshot -Root $p.Projects  -Scope $p.Scope -Prefix $prefix).GetEnumerator() | ForEach-Object { $snapB[$_.Key] = $_.Value }
}

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
    foreach ($p in $pairs) { Invoke-PairMirror -Pair $p -Direction 'push' -DryRun:$DryRun }
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
    foreach ($p in $pairs) { Invoke-PairMirror -Pair $p -Direction 'pull' -DryRun:$DryRun }
    if ($DryRun) {
      Write-Host "DRY RUN complete - no changes written." -ForegroundColor Yellow
    } else {
      Write-Host "Pulled. Restart Claude Code to pick up the updated assets." -ForegroundColor Green
    }
    exit 0
  }
}
