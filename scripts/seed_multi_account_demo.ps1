<#
.SYNOPSIS
    Idempotently provisions 5 real Firebase Auth demo accounts and seeds interconnected
    live Firestore demo data for MASHWAR Qatar (`mashwar-qatar-2026-ec99d`).

.DESCRIPTION
    PowerShell 5.1 wrapper around `scripts/seed_multi_account_demo.mjs`.
    - Creates or updates 5 Firebase Auth accounts (Requester, Approved Provider/Captain,
      Ladies-Only Traveler/Pending Provider, Fresh Clean-Slate Account, and Super Admin).
    - Sets `{ admin: true, role: 'superAdmin' }` custom claims on the Super Admin account.
    - Seeds interconnected live Firestore collections (`demo_ma_*`) and enforces zero docs
      for Account 4 (`fresh.demo@mashwar.qa`).
    - Supports `-VerifyOnly` for read-only verification of Auth accounts, claims, and Firestore readback.
#>
[CmdletBinding()]
param(
    [string]$ProjectId = "mashwar-qatar-2026-ec99d",
    [switch]$VerifyOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mjsPath = Join-Path $PSScriptRoot "seed_multi_account_demo.mjs"

if (-not (Test-Path -LiteralPath $mjsPath)) {
    throw "Missing Node seeder script at '$mjsPath'."
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

$nodeArgs = @(
    $mjsPath,
    "--project",
    $ProjectId
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
