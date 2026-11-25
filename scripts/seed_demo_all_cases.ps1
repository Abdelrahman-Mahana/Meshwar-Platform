<#
.SYNOPSIS
    Deploys (optional) Firestore rules/indexes and seeds or verifies the complete
    MASHWAR Qatar Worksite Supply MVP All-Cases demo dataset on Firebase.

.DESCRIPTION
    PowerShell 5.1 wrapper around `scripts/seed_demo_all_cases.mjs` targeting
    `mashwar-qatar-2026-ec99d` (Spark-plan safe).
    - Supports `-DeployRulesAndIndexes` to deploy `firestore:rules,firestore:indexes`
      while handling the benign Windows Node 24 libuv teardown assertion via REST
      release verification.
    - Supports `-VerifyOnly` for zero-mutation readback verification of rules,
      `{ admin: true, role: 'superAdmin' }` custom claims, all 14 demo collections,
      and salted SHA-256 handover codes.
#>
[CmdletBinding()]
param(
    [string]$ProjectId = "mashwar-qatar-2026-ec99d",
    [string]$OwnerUid = "QB0hyc4BVZTkr91EC9KUd2EFbCw1",
    [switch]$DeployRulesAndIndexes,
    [switch]$VerifyOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mjsPath = Join-Path $PSScriptRoot "seed_demo_all_cases.mjs"

if (-not (Test-Path -LiteralPath $mjsPath)) {
    throw "Missing Node seeder script at '$mjsPath'."
}

function Resolve-FirebaseCli {
    $candidates = @()
    if ($env:APPDATA) {
        $candidates += (Join-Path $env:APPDATA "npm\firebase.cmd")
    }
    $cmd = Get-Command "firebase.cmd" -ErrorAction SilentlyContinue
    if ($cmd) { $candidates += $cmd.Source }
    $cmd2 = Get-Command "firebase" -ErrorAction SilentlyContinue
    if ($cmd2) { $candidates += $cmd2.Source }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) {
            return $c
        }
    }
    return $null
}

function Resolve-FirebaseToolsLibDir {
    $candidates = @()
    if ($env:APPDATA) {
        $candidates += (Join-Path $env:APPDATA "npm\node_modules\firebase-tools\lib")
    }
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA "npm\node_modules\firebase-tools\lib")
    }
    $npmCmd = Get-Command "npm.cmd" -ErrorAction SilentlyContinue
    if ($npmCmd) {
        $globalRoot = (& $npmCmd root -g 2>$null | Out-String).Trim()
        if ($globalRoot) {
            $candidates += (Join-Path $globalRoot "firebase-tools\lib")
        }
    }
    foreach ($dir in $candidates) {
        if ($dir -and
            (Test-Path -LiteralPath (Join-Path $dir "auth.js")) -and
            (Test-Path -LiteralPath (Join-Path $dir "requireAuth.js")) -and
            (Test-Path -LiteralPath (Join-Path $dir "apiv2.js"))) {
            return (Resolve-Path $dir).Path
        }
    }
    throw "Could not locate firebase-tools/lib modules (auth, requireAuth, apiv2). Install firebase-tools globally (`npm i -g firebase-tools`)."
}

$firebaseToolsLib = Resolve-FirebaseToolsLibDir

if ($DeployRulesAndIndexes -and (-not $VerifyOnly)) {
    $firebaseCli = Resolve-FirebaseCli
    $deployArgs = @(
        "deploy",
        "--only",
        "firestore:rules,firestore:indexes",
        "--project",
        $ProjectId,
        "--non-interactive"
    )
    $deployLines = New-Object System.Collections.Generic.List[string]
    $deployExitCode = 0

    Write-Host "Deploying firestore:rules,firestore:indexes to '$ProjectId'..." -ForegroundColor Cyan
    Push-Location $repoRoot
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            if ($null -ne $firebaseCli) {
                & $firebaseCli @deployArgs 2>&1 | ForEach-Object {
                    $line = $_.ToString()
                    $deployLines.Add($line)
                    Write-Host $line
                }
                $deployExitCode = $LASTEXITCODE
            } else {
                & npx --yes firebase-tools@latest @deployArgs 2>&1 | ForEach-Object {
                    $line = $_.ToString()
                    $deployLines.Add($line)
                    Write-Host $line
                }
                $deployExitCode = $LASTEXITCODE
            }
        } finally {
            $ErrorActionPreference = $prevEap
        }
    } finally {
        Get-ChildItem -Path $repoRoot -Filter "*-debug*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Pop-Location
    }

    $deployJoined = ($deployLines -join "`n")
    if ($deployExitCode -ne 0) {
        $hasBenignLibuvExit = ($deployJoined -match "UV_HANDLE_CLOSING") -and
            ($deployJoined -match "Deploy complete!|released rules firestore\.rules") -and
            ($deployJoined -notmatch "PERMISSION_DENIED|Error:\s")
        if ($hasBenignLibuvExit) {
            Write-Warning "firebase deploy exited with code $deployExitCode due to Node.js 24 Windows libuv handle-closing assertion after deploy completion; verifying active release via Firebase Rules REST API next."
        } else {
            throw "firebase deploy --only firestore:rules,firestore:indexes failed with exit code $deployExitCode.`n$deployJoined"
        }
    }
}

$nodeArgs = @(
    $mjsPath,
    "--project",
    $ProjectId,
    "--owner-uid",
    $OwnerUid
)
if ($VerifyOnly) {
    $nodeArgs += "--verify-only"
}

$prevFtLib = $env:MASHWAR_FT_LIB
$prevProject = $env:MASHWAR_FIREBASE_PROJECT
$nodeExitCode = 0

Push-Location $repoRoot
try {
    $env:MASHWAR_FT_LIB = $firebaseToolsLib
    $env:MASHWAR_FIREBASE_PROJECT = $ProjectId

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & node @nodeArgs 2>&1 | ForEach-Object {
            Write-Host $_.ToString()
        }
        $nodeExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }
} finally {
    $env:MASHWAR_FT_LIB = $prevFtLib
    $env:MASHWAR_FIREBASE_PROJECT = $prevProject
    Get-ChildItem -Path $repoRoot -Filter "*-debug*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Pop-Location
}

if ($nodeExitCode -ne 0) {
    exit $nodeExitCode
}
exit 0
