<#
.SYNOPSIS
  Generate one slash command per da-* skill so that .claude/commands/ mirrors .claude/skills/.

.DESCRIPTION
  For every <workspace>/.claude/skills/da-*/SKILL.md the script:
    1. Parses the YAML frontmatter to get `name` and `description`
    2. Writes <workspace>/.claude/commands/da-<name>.md with that description and a thin
       body pointing teammates at the skill definition.

  Hand-written commands (e.g. da-sync.md) are left alone unless they happen to share a name
  with a skill - in that case the skill version wins (regeneration is the source of truth).

.EXAMPLE
  .\generate-da-commands.ps1
  .\generate-da-commands.ps1 -DryRun
#>

param([switch]$DryRun)

$ErrorActionPreference = 'Stop'

$scriptDir     = Split-Path -Parent $PSCommandPath
$projectsRoot  = Split-Path -Parent $scriptDir
$workspaceRoot = Split-Path -Parent $projectsRoot

$skillsRoot   = Join-Path $workspaceRoot '.claude\skills'
$commandsRoot = Join-Path $workspaceRoot '.claude\commands'

if (-not (Test-Path $skillsRoot))   { Write-Error "Skills folder missing: $skillsRoot"; exit 2 }
if (-not (Test-Path $commandsRoot)) { New-Item -ItemType Directory -Path $commandsRoot -Force | Out-Null }

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Read-Utf8Lines {
  param([string]$Path)
  $text = [System.IO.File]::ReadAllText($Path, $utf8NoBom)
  return $text -split "`r?`n"
}

function Write-Utf8File {
  param([string]$Path, [string]$Content)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-SkillFrontmatter {
  param([string]$Path)
  $lines = Read-Utf8Lines -Path $Path
  $inFm = $false
  $name = ''
  $description = ''
  $foldedDesc = $false
  $accum = @()
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -eq '---') {
      if (-not $inFm) { $inFm = $true; continue } else { break }
    }
    if (-not $inFm) { continue }

    if ($foldedDesc) {
      if ($line -match '^\s+(\S.*)$') {
        $accum += $matches[1].Trim()
        continue
      } else {
        $description = ($accum -join ' ')
        $foldedDesc = $false
        $accum = @()
      }
    }

    if ($line -match '^name:\s*(.+?)\s*$') { $name = $matches[1].Trim('"').Trim("'") }
    elseif ($line -match '^description:\s*>-?\s*$') { $foldedDesc = $true }
    elseif ($line -match '^description:\s*(.+?)\s*$') { $description = $matches[1].Trim('"').Trim("'") }
  }
  if ($foldedDesc -and $accum.Count -gt 0) { $description = ($accum -join ' ') }
  return [PSCustomObject]@{ Name = $name; Description = $description }
}

function Format-FoldedDescription {
  param([string]$Description, [int]$Wrap = 100)
  $words = $Description -split '\s+' | Where-Object { $_ }
  $lines = @()
  $current = ''
  foreach ($w in $words) {
    if ($current.Length -gt 0 -and ($current.Length + 1 + $w.Length) -gt $Wrap) {
      $lines += '  ' + $current
      $current = $w
    } elseif ($current.Length -eq 0) {
      $current = $w
    } else {
      $current = $current + ' ' + $w
    }
  }
  if ($current.Length -gt 0) { $lines += '  ' + $current }
  return ($lines -join "`r`n")
}

function New-CommandBody {
  param([string]$Name, [string]$Description)
  $folded = Format-FoldedDescription -Description $Description
  @"
---
description: >-
$folded
---

Engage the ``$Name`` skill - follow the instructions in ``.claude/skills/$Name/SKILL.md`` to handle this request.

Treat ``/$Name`` as the user explicitly asking to run that skill. If you need the full skill body, read the SKILL.md file directly.
"@
}

$skillDirs = Get-ChildItem -Path $skillsRoot -Directory -Filter 'da-*' -ErrorAction SilentlyContinue
$generated = 0
$skipped = 0
$unchanged = 0

foreach ($dir in $skillDirs) {
  $skillFile = Join-Path $dir.FullName 'SKILL.md'
  if (-not (Test-Path $skillFile)) {
    Write-Host "  [skip] no SKILL.md in $($dir.Name)" -ForegroundColor DarkYellow
    $skipped++
    continue
  }

  $fm = Get-SkillFrontmatter -Path $skillFile
  if (-not $fm.Name) {
    Write-Host "  [skip] no name in $skillFile" -ForegroundColor DarkYellow
    $skipped++
    continue
  }
  if (-not $fm.Description) {
    Write-Host "  [skip] no description in $skillFile" -ForegroundColor DarkYellow
    $skipped++
    continue
  }

  $cmdPath = Join-Path $commandsRoot ("{0}.md" -f $fm.Name)
  $newBody = New-CommandBody -Name $fm.Name -Description $fm.Description

  $needWrite = $true
  if (Test-Path $cmdPath) {
    $existing = [System.IO.File]::ReadAllText($cmdPath, $utf8NoBom)
    if ($existing.TrimEnd() -eq $newBody.TrimEnd()) { $needWrite = $false }
  }

  if (-not $needWrite) {
    Write-Host "  [ok]  $($fm.Name) (unchanged)" -ForegroundColor DarkGray
    $unchanged++
    continue
  }

  if ($DryRun) {
    Write-Host "  [dry] would write $cmdPath" -ForegroundColor Yellow
  } else {
    Write-Utf8File -Path $cmdPath -Content $newBody
    Write-Host "  [gen] $($fm.Name)" -ForegroundColor Green
  }
  $generated++
}

Write-Host ""
Write-Host ("Generated: {0}  Unchanged: {1}  Skipped: {2}" -f $generated, $unchanged, $skipped)
if ($DryRun) { Write-Host "DRY RUN - no files written." -ForegroundColor Yellow }
