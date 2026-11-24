<#
.SYNOPSIS
    Downloads gitignored native Firebase client configuration files for local
    Android (`android/app/google-services.json`) and iOS (`ios/Runner/GoogleService-Info.plist`) builds.
.DESCRIPTION
    Uses `firebase apps:sdkconfig` against `mashwar-qatar-2026-ec99d` to fetch real
    native client configurations without committing them to Git. Handles Node.js 24
    Windows libuv teardown assertions gracefully by verifying written file integrity.
#>
[CmdletBinding()]
param(
    [string]$ProjectId = "mashwar-qatar-2026-ec99d",
    [string]$AndroidAppId = "1:820084343406:android:a9e464e38a988eddd35c7f",
    [string]$IosAppId = "1:820084343406:ios:5073f983643cc020d35c7f",
    [string]$AndroidOut = "",
    [string]$IosOut = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($AndroidOut)) {
    $AndroidOut = Join-Path $repoRoot "android\app\google-services.json"
}
if ([string]::IsNullOrWhiteSpace($IosOut)) {
    $IosOut = Join-Path $repoRoot "ios\Runner\GoogleService-Info.plist"
}

function Invoke-FirebaseSdkConfig {
    param(
        [string[]]$Arguments,
        [string]$ExpectedOutputFile
    )

    if (Test-Path -LiteralPath $ExpectedOutputFile) {
        Remove-Item -LiteralPath $ExpectedOutputFile -Force
    }

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
        if ($null -ne $firebaseCmd -and -not [string]::IsNullOrWhiteSpace($firebaseCmd.Source)) {
            & $firebaseCmd.Source @Arguments
            $exitCode = $LASTEXITCODE
        } else {
            $npmPrefix = (npm prefix -g 2>$null)
            $globalFirebase = if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
                Join-Path $npmPrefix.Trim() "firebase.cmd"
            } else {
                ""
            }
            if (-not [string]::IsNullOrWhiteSpace($globalFirebase) -and (Test-Path -LiteralPath $globalFirebase)) {
                & $globalFirebase @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                & npx --yes firebase-tools@latest @Arguments
                $exitCode = $LASTEXITCODE
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }

    # Note: Node.js 24 on Windows may emit a benign libuv UV_HANDLE_CLOSING assertion
    # on process exit *after* writing the SDK config file cleanly. Validate file content.
    if (-not (Test-Path -LiteralPath $ExpectedOutputFile) -or ((Get-Item -LiteralPath $ExpectedOutputFile).Length -eq 0)) {
        throw "firebase apps:sdkconfig failed (exit code $exitCode) and did not produce '$ExpectedOutputFile'."
    }
}

foreach ($targetPath in @($AndroidOut, $IosOut)) {
    $parentDir = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
}

Write-Host "Fetching Android config ($AndroidAppId) -> $AndroidOut ..." -ForegroundColor Cyan
Invoke-FirebaseSdkConfig -ExpectedOutputFile $AndroidOut -Arguments @(
    "apps:sdkconfig",
    "ANDROID",
    $AndroidAppId,
    "--project",
    $ProjectId,
    "--out",
    $AndroidOut,
    "--non-interactive"
)

$androidJson = Get-Content -LiteralPath $AndroidOut -Raw | ConvertFrom-Json
if ($androidJson.project_info.project_id -ne $ProjectId) {
    throw "Downloaded Android google-services.json project_id mismatch: $($androidJson.project_info.project_id)"
}

Write-Host "Fetching iOS config ($IosAppId) -> $IosOut ..." -ForegroundColor Cyan
Invoke-FirebaseSdkConfig -ExpectedOutputFile $IosOut -Arguments @(
    "apps:sdkconfig",
    "IOS",
    $IosAppId,
    "--project",
    $ProjectId,
    "--out",
    $IosOut,
    "--non-interactive"
)

$iosRaw = Get-Content -LiteralPath $IosOut -Raw
if ($iosRaw -notmatch [regex]::Escape($ProjectId) -or $iosRaw -notmatch [regex]::Escape($IosAppId)) {
    throw "Downloaded iOS GoogleService-Info.plist failed validation for $ProjectId / $IosAppId."
}

Write-Host "Successfully fetched and verified local Firebase native client configs (gitignored)." -ForegroundColor Green
Write-Host "Reminder: Never force-add or commit google-services.json or GoogleService-Info.plist to Git." -ForegroundColor Yellow
