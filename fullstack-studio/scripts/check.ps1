#requires -Version 5.1
<#
  check.ps1 - the quality gate.

  Runs whatever the project actually has: typecheck, lint, tests, build.
  Prints one summary line per step and a final verdict. Exit code 1 on failure.

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1
    ... -Path ../my-app
    ... -Quick        # typecheck + lint only
#>
[CmdletBinding()]
param(
    [string]$Path = '.',
    [switch]$Quick
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Write-Section($name) { Write-Host ""; Write-Host "=== $name ===" -ForegroundColor Cyan }

$root = (Resolve-Path -LiteralPath $Path).Path
Push-Location $root
$results = New-Object System.Collections.Generic.List[object]
$failed = $false

try {
    # ------------------------------------------------------------- node ----
    $pkgPath = Join-Path $root 'package.json'
    if (Test-Path -LiteralPath $pkgPath) {
        $pkg = Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json
        $scripts = @{}
        if ($pkg.PSObject.Properties.Name -contains 'scripts' -and $pkg.scripts) {
            foreach ($p in $pkg.scripts.PSObject.Properties) { $scripts[$p.Name] = $p.Value }
        }

        $runner = 'npm'
        if ((Test-Path (Join-Path $root 'pnpm-lock.yaml'))) { $runner = 'pnpm' }
        elseif ((Test-Path (Join-Path $root 'yarn.lock'))) { $runner = 'yarn' }
        elseif ((Test-Path (Join-Path $root 'bun.lockb'))) { $runner = 'bun' }

        if (-not (Test-Path (Join-Path $root 'node_modules'))) {
            Write-Host "node_modules missing: run '$runner install' first." -ForegroundColor Yellow
        }

        $steps = [ordered]@{}
        if ($scripts.ContainsKey('typecheck')) { $steps['typecheck'] = 'typecheck' }
        elseif ($scripts.ContainsKey('check-types')) { $steps['typecheck'] = 'check-types' }
        elseif (Test-Path (Join-Path $root 'tsconfig.json')) { $steps['typecheck'] = 'npx tsc --noEmit' }

        if ($scripts.ContainsKey('lint')) { $steps['lint'] = 'lint' }
        if (-not $Quick) {
            if ($scripts.ContainsKey('test')) { $steps['test'] = 'test' }
            elseif ($scripts.ContainsKey('test:unit')) { $steps['test'] = 'test:unit' }
            if ($scripts.ContainsKey('build')) { $steps['build'] = 'build' }
        }

        foreach ($name in $steps.Keys) {
            $value = $steps[$name]
            Write-Section $name
            $started = Get-Date
            if ($value.StartsWith('npx ')) {
                $output = & cmd /c "$value 2>&1"
            } else {
                $output = & cmd /c "$runner run $value 2>&1"
            }
            $code = $LASTEXITCODE
            $output | ForEach-Object { Write-Host $_ }
            $ms = [int]((Get-Date) - $started).TotalMilliseconds
            $results.Add([pscustomobject]@{ step = $name; ok = ($code -eq 0); ms = $ms })
            if ($code -ne 0) { $failed = $true }
        }
    }

    # ----------------------------------------------------------- python ----
    $hasPy = (Test-Path (Join-Path $root 'pyproject.toml')) -or (Test-Path (Join-Path $root 'requirements.txt'))
    if ($hasPy -and -not $Quick) {
        $hasTests = (Test-Path (Join-Path $root 'tests')) -or (Test-Path (Join-Path $root 'test'))
        if ($hasTests) {
            Write-Section 'pytest'
            $output = & cmd /c "python -m pytest -q 2>&1"
            $code = $LASTEXITCODE
            $output | ForEach-Object { Write-Host $_ }
            $results.Add([pscustomobject]@{ step = 'pytest'; ok = ($code -eq 0); ms = 0 })
            if ($code -ne 0) { $failed = $true }
        }
    }

    # ------------------------------------------------------------ hygiene ----
    # Not a gate, just a nudge: leftover debug lines and unowned TODOs.
    $sourceDirs = @('src', 'app', 'lib', 'components') | ForEach-Object { Join-Path $root $_ } |
        Where-Object { Test-Path -LiteralPath $_ }
    if ($sourceDirs.Count -gt 0) {
        $leftovers = Get-ChildItem -Path $sourceDirs -Recurse -Include *.ts, *.tsx, *.js, *.jsx, *.py -ErrorAction SilentlyContinue |
            Select-String -Pattern 'console\.log\(|debugger;|TODO(?!\()' -ErrorAction SilentlyContinue
        if ($leftovers) {
            Write-Section 'hygiene'
            Write-Host ("{0} leftover debug/TODO lines:" -f @($leftovers).Count) -ForegroundColor Yellow
            $leftovers | Select-Object -First 10 | ForEach-Object {
                Write-Host ("  {0}:{1}" -f $_.Path.Replace($root, '.'), $_.LineNumber)
            }
        }
    }

    # ------------------------------------------------------------ summary ----
    Write-Section 'summary'
    if ($results.Count -eq 0) {
        Write-Host 'No checks found. This project has no typecheck, lint, test or build step.' -ForegroundColor Yellow
        exit 0
    }
    foreach ($r in $results) {
        $label = if ($r.ok) { 'PASS' } else { 'FAIL' }
        $color = if ($r.ok) { 'Green' } else { 'Red' }
        Write-Host ("{0,-6} {1,-12} {2,6} ms" -f $label, $r.step, $r.ms) -ForegroundColor $color
    }
    if ($failed) {
        Write-Host 'VERDICT: FAILED - fix before continuing.' -ForegroundColor Red
        exit 1
    }
    Write-Host 'VERDICT: GREEN - safe to continue.' -ForegroundColor Green
    exit 0
}
finally {
    Pop-Location
}
