<#
.SYNOPSIS
    Idempotently provisions Firebase Authentication (Email/Password provider) and
    ensures localhost / 127.0.0.1 are present in authorizedDomains for mashwar-qatar-2026-ec99d.
.DESCRIPTION
    1. Runs `firebase deploy --only auth --project <ProjectId> --non-interactive`
       (tolerating benign Node.js 24 Windows libuv teardown assertions only when
       deploy output indicates completion, while failing hard on IAM/billing errors).
    2. Uses the installed `firebase-tools` SDK (`auth`, `requireAuth`, `gcp/auth`, `apiv2`)
       to verify and, if needed, patch Identity Toolkit `signIn.email.enabled = true`
       and append `127.0.0.1` / `localhost` to `authorizedDomains` while preserving
       all existing domains.
    3. Extracts the Web API key from `lib/firebase_options.dart` (unless `-WebApiKey`
       is provided) and verifies the public Identity Toolkit endpoint
       `https://identitytoolkit.googleapis.com/v1/projects?key=<webApiKey>` returns HTTP 200
       with `127.0.0.1` in `authorizedDomains`.
#>
[CmdletBinding()]
param(
    [string]$ProjectId = "mashwar-qatar-2026-ec99d",
    [string]$WebApiKey = "",
    [string[]]$RequiredDomains = @("127.0.0.1", "localhost")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$firebaseJsonPath = Join-Path $repoRoot "firebase.json"
$firebaseOptionsPath = Join-Path $repoRoot "lib\firebase_options.dart"

if (-not (Test-Path -LiteralPath $firebaseJsonPath)) {
    throw "firebase.json not found at repository root: $repoRoot"
}

# Refresh user/machine PATH entries so global npm / firebase CLI binaries are discoverable
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($extraPath in @($userPath, $machinePath)) {
    if (-not [string]::IsNullOrWhiteSpace($extraPath)) {
        foreach ($entry in ($extraPath -split ";")) {
            $trimmed = $entry.Trim()
            if ($trimmed -ne "" -and (($env:Path -split ";") -notcontains $trimmed)) {
                $env:Path = "$env:Path;$trimmed"
            }
        }
    }
}

$npmGlobalBin = Join-Path $env:APPDATA "npm"
if ((Test-Path -LiteralPath $npmGlobalBin) -and (($env:Path -split ";") -notcontains $npmGlobalBin)) {
    $env:Path = "$npmGlobalBin;$env:Path"
}

function Resolve-FirebaseCli {
    $cmd = Get-Command firebase.cmd -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace($cmd.Source)) {
        return $cmd.Source
    }
    $cmd = Get-Command firebase -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace($cmd.Source)) {
        return $cmd.Source
    }
    $npmPrefix = (npm prefix -g 2>$null)
    if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
        $candidate = Join-Path $npmPrefix.Trim() "firebase.cmd"
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    return $null
}

function Resolve-FirebaseToolsLibDir {
    $candidates = @(
        (Join-Path $env:APPDATA "npm\node_modules\firebase-tools\lib")
    )
    $npmPrefix = (npm prefix -g 2>$null)
    if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
        $candidates += (Join-Path $npmPrefix.Trim() "node_modules\firebase-tools\lib")
    }
    foreach ($dir in $candidates) {
        if ((Test-Path -LiteralPath (Join-Path $dir "auth.js")) -and
            (Test-Path -LiteralPath (Join-Path $dir "requireAuth.js")) -and
            (Test-Path -LiteralPath (Join-Path $dir "gcp\auth.js")) -and
            (Test-Path -LiteralPath (Join-Path $dir "apiv2.js"))) {
            return (Resolve-Path $dir).Path
        }
    }
    throw "Could not locate firebase-tools/lib modules (auth, requireAuth, gcp/auth, apiv2). Install firebase-tools globally (`npm i -g firebase-tools`)."
}

function Resolve-WebApiKey {
    param(
        [string]$ExplicitKey,
        [string]$OptionsPath
    )
    if (-not [string]::IsNullOrWhiteSpace($ExplicitKey)) {
        return $ExplicitKey.Trim()
    }
    if (-not (Test-Path -LiteralPath $OptionsPath)) {
        throw "lib/firebase_options.dart not found at '$OptionsPath' and -WebApiKey was not supplied."
    }
    $raw = Get-Content -LiteralPath $OptionsPath -Raw
    $webBlockMatch = [regex]::Match(
        $raw,
        "static\s+const\s+FirebaseOptions\s+web\s*=\s*FirebaseOptions\(([\s\S]*?)\);"
    )
    if (-not $webBlockMatch.Success) {
        throw "Could not find `static const FirebaseOptions web` block in '$OptionsPath'."
    }
    $webBlock = $webBlockMatch.Groups[1].Value
    $defaultValMatch = [regex]::Match(
        $webBlock,
        "apiKey:\s*String\.fromEnvironment\([^)]*defaultValue:\s*'([^']+)'"
    )
    if ($defaultValMatch.Success) {
        return $defaultValMatch.Groups[1].Value.Trim()
    }
    $directMatch = [regex]::Match($webBlock, "apiKey:\s*'([^']+)'")
    if ($directMatch.Success) {
        return $directMatch.Groups[1].Value.Trim()
    }
    throw "Could not extract Web API key from '$OptionsPath'."
}

$firebaseCli = Resolve-FirebaseCli
$firebaseToolsLib = Resolve-FirebaseToolsLibDir
$resolvedWebApiKey = Resolve-WebApiKey -ExplicitKey $WebApiKey -OptionsPath $firebaseOptionsPath

Write-Host "Provisioning Firebase Authentication for project '$ProjectId'..." -ForegroundColor Cyan

# Step 1: firebase deploy --only auth
$deployArgs = @("deploy", "--only", "auth", "--project", $ProjectId, "--non-interactive")
$deployLines = New-Object System.Collections.Generic.List[string]
$deployExitCode = 0

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
        ($deployJoined -match "Deploy complete!|Auth providers enabled") -and
        ($deployJoined -notmatch "PERMISSION_DENIED|BILLING_NOT_ENABLED|billing account|Error:\s")
    if ($hasBenignLibuvExit) {
        Write-Warning "firebase deploy exited with code $deployExitCode due to Node.js 24 Windows libuv handle-closing assertion after auth deploy output; validating live API state next."
    } else {
        throw "firebase deploy --only auth failed with exit code $deployExitCode.`n$deployJoined"
    }
}

# Step 2: Verify/patch Identity Toolkit config & authorizedDomains via firebase-tools Node modules
$nodeScript = @'
const path = require("path");
const libDir = process.env.MASHWAR_FT_LIB;
const projectId = process.env.MASHWAR_FIREBASE_PROJECT;
const requiredDomains = JSON.parse(process.env.MASHWAR_REQUIRED_DOMAINS_JSON);

const auth = require(path.join(libDir, "auth"));
const { requireAuth } = require(path.join(libDir, "requireAuth"));
const gcpAuth = require(path.join(libDir, "gcp", "auth"));
const apiv2 = require(path.join(libDir, "apiv2"));
const api = require(path.join(libDir, "api"));

(async () => {
  const acct = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
  if (!acct) {
    throw new Error("No authenticated Firebase CLI account found. Run `firebase login` first.");
  }
  const opts = { project: projectId };
  auth.setActiveAccount(opts, acct);
  await requireAuth(opts);

  const client = new apiv2.Client({ urlPrefix: api.identityOrigin(), auth: true });
  const getRes = await client.get(`/admin/v2/projects/${projectId}/config`, {
    headers: { "x-goog-user-project": projectId },
  });
  let configBody = getRes.body || {};
  console.log("Identity Toolkit signIn.email (before):", JSON.stringify(configBody.signIn?.email ?? null));

  if (configBody.signIn?.email?.enabled !== true || configBody.signIn?.email?.passwordRequired !== true) {
    console.log("Patching Identity Toolkit config to enable Email/Password sign-in...");
    const patchRes = await client.patch(
      `/admin/v2/projects/${projectId}/config`,
      { signIn: { email: { enabled: true, passwordRequired: true } } },
      {
        queryParams: { updateMask: "signIn.email" },
        headers: { "x-goog-user-project": projectId },
      }
    );
    configBody = patchRes.body || {};
  }

  if (configBody.signIn?.email?.enabled !== true) {
    throw new Error(`Expected signIn.email.enabled === true, got: ${JSON.stringify(configBody.signIn)}`);
  }

  const existingDomains = (await gcpAuth.getAuthDomains(projectId)) || [];
  const mergedDomains = [...existingDomains];
  for (const domain of requiredDomains) {
    if (!mergedDomains.includes(domain)) {
      mergedDomains.push(domain);
    }
  }

  let finalDomains = existingDomains;
  if (mergedDomains.length !== existingDomains.length) {
    console.log("Updating authorizedDomains to include:", requiredDomains.join(", "));
    finalDomains = (await gcpAuth.updateAuthDomains(projectId, mergedDomains)) || [];
  } else {
    console.log("authorizedDomains already includes all required domains.");
  }

  for (const domain of requiredDomains) {
    if (!finalDomains.includes(domain)) {
      throw new Error(`authorizedDomains missing '${domain}': ${JSON.stringify(finalDomains)}`);
    }
  }

  console.log("Identity Toolkit signIn.email (verified):", JSON.stringify(configBody.signIn.email));
  console.log("authorizedDomains (admin API):", JSON.stringify(finalDomains));
})().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exit(1);
});
'@

$prevFtLib = $env:MASHWAR_FT_LIB
$prevProject = $env:MASHWAR_FIREBASE_PROJECT
$prevDomains = $env:MASHWAR_REQUIRED_DOMAINS_JSON
try {
    $env:MASHWAR_FT_LIB = $firebaseToolsLib
    $env:MASHWAR_FIREBASE_PROJECT = $ProjectId
    $env:MASHWAR_REQUIRED_DOMAINS_JSON = (ConvertTo-Json -InputObject @($RequiredDomains) -Compress)

    $tempNodeFile = Join-Path ([System.IO.Path]::GetTempPath()) ("mashwar-provision-auth-" + [Guid]::NewGuid().ToString("N") + ".cjs")
    [System.IO.File]::WriteAllText($tempNodeFile, $nodeScript, [System.Text.UTF8Encoding]::new($false))

    Push-Location $repoRoot
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $nodeLines = New-Object System.Collections.Generic.List[string]
        try {
            & node $tempNodeFile 2>&1 | ForEach-Object {
                $line = $_.ToString()
                $nodeLines.Add($line)
                Write-Host $line
            }
            $nodeExit = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $prevEap
        }
        if ($nodeExit -ne 0) {
            throw "Node Identity Toolkit verification/patch failed with exit code $nodeExit.`n$($nodeLines -join "`n")"
        }
    } finally {
        Pop-Location
        Remove-Item -LiteralPath $tempNodeFile -Force -ErrorAction SilentlyContinue
    }
} finally {
    $env:MASHWAR_FT_LIB = $prevFtLib
    $env:MASHWAR_FIREBASE_PROJECT = $prevProject
    $env:MASHWAR_REQUIRED_DOMAINS_JSON = $prevDomains
}

# Step 3: Verify public Identity Toolkit client endpoint returns HTTP 200 and includes 127.0.0.1
$publicEndpoint = "https://identitytoolkit.googleapis.com/v1/projects?key=$resolvedWebApiKey"
$response = Invoke-WebRequest -Uri $publicEndpoint -Method Get -UseBasicParsing
if ($response.StatusCode -ne 200) {
    throw "Public Identity Toolkit endpoint returned HTTP $($response.StatusCode) (expected 200)."
}
$publicJson = $response.Content | ConvertFrom-Json
$publicDomains = @($publicJson.authorizedDomains)
foreach ($domain in $RequiredDomains) {
    if ($publicDomains -notcontains $domain) {
        throw "Public Identity Toolkit authorizedDomains missing '$domain'. Found: $($publicDomains -join ', ')"
    }
}

Write-Host "Public Identity Toolkit HTTP $($response.StatusCode) verified. authorizedDomains: $($publicDomains -join ', ')" -ForegroundColor Green
exit 0
