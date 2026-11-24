$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$functionsDir = Join-Path $repoRoot 'functions'

if (-not (Test-Path (Join-Path $repoRoot 'firebase.json'))) {
    Write-Error "firebase.json not found at repository root: $repoRoot"
    exit 1
}

if (-not (Test-Path (Join-Path $functionsDir 'package.json'))) {
    Write-Error "functions/package.json not found at: $functionsDir"
    exit 1
}

# Refresh user/machine PATH entries so newly installed user-space tools are discoverable
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
foreach ($extraPath in @($userPath, $machinePath)) {
    if (-not [string]::IsNullOrWhiteSpace($extraPath)) {
        foreach ($entry in ($extraPath -split ';')) {
            $trimmed = $entry.Trim()
            if ($trimmed -ne '' -and (($env:Path -split ';') -notcontains $trimmed)) {
                $env:Path = "$env:Path;$trimmed"
            }
        }
    }
}

# Discover OpenJDK 21 / JAVA_HOME (prioritize user-space OpenJDK 21)
$candidateJavaHomes = @(
    "$env:LOCALAPPDATA\Programs\OpenJDK21",
    $env:JAVA_HOME,
    [Environment]::GetEnvironmentVariable('JAVA_HOME', 'User'),
    [Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$resolvedJavaHome = $null
foreach ($candidate in $candidateJavaHomes) {
    if (Test-Path (Join-Path $candidate 'bin\java.exe')) {
        $resolvedJavaHome = (Resolve-Path $candidate).Path
        break
    }
}

if (-not $resolvedJavaHome) {
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaBinDir = Split-Path -Parent $javaCmd.Source
        $resolvedJavaHome = Split-Path -Parent $javaBinDir
    }
}

if (-not $resolvedJavaHome -or -not (Test-Path (Join-Path $resolvedJavaHome 'bin\java.exe'))) {
    Write-Error "Java runtime (OpenJDK 21+) not found. Expected JAVA_HOME or $env:LOCALAPPDATA\Programs\OpenJDK21\bin\java.exe."
    exit 1
}

$javaBin = Join-Path $resolvedJavaHome 'bin'
$env:JAVA_HOME = $resolvedJavaHome
$env:Path = "$javaBin;$env:Path"

Write-Host "Using JAVA_HOME=$env:JAVA_HOME"
& (Join-Path $javaBin 'java.exe') -version
if ($LASTEXITCODE -ne 0) {
    Write-Error "java -version failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Discover Firebase CLI (global firebase binary or npx firebase-tools fallback)
$npmGlobalBin = Join-Path $env:APPDATA 'npm'
if ((Test-Path $npmGlobalBin) -and (($env:Path -split ';') -notcontains $npmGlobalBin)) {
    $env:Path = "$npmGlobalBin;$env:Path"
}

$firebaseCmd = Get-Command firebase.cmd -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    $firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
}

if ($firebaseCmd) {
    Write-Host "Using Firebase CLI: $($firebaseCmd.Source)"
    & $firebaseCmd.Source --version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "firebase --version failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Host "Global firebase binary not found; falling back to npx firebase-tools"
}

Push-Location $functionsDir
try {
    if (-not (Test-Path (Join-Path $functionsDir 'node_modules\@firebase\rules-unit-testing'))) {
        Write-Host "Installing functions dependencies via npm ci..."
        & npm ci
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }

    $testCmd = 'node --test test/emulator_rules.test.mjs'
    if ($firebaseCmd) {
        & $firebaseCmd.Source emulators:exec --only firestore,storage --project demo-mashwar-qatar $testCmd
    } else {
        & npx --yes firebase-tools emulators:exec --only firestore,storage --project demo-mashwar-qatar $testCmd
    }
    $exitCode = $LASTEXITCODE
} finally {
    Get-ChildItem -Path $functionsDir -Filter '*-debug*.log' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $repoRoot -Filter '*-debug*.log' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Pop-Location
}

exit $exitCode
