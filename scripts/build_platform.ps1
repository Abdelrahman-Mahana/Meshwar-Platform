param(
  [string]$AppEnv = "production",
  [string]$GoogleMapsApiKey = "",
  [switch]$SkipAnalyze,
  [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

Write-Host "=== MASHWAR Platform DevOps Build (APP_ENV=$AppEnv, USE_FIREBASE=true) ===" -ForegroundColor Cyan

if (-not $SkipAnalyze) {
  Write-Host "[1/4] Running flutter analyze..." -ForegroundColor Yellow
  flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed with exit code $LASTEXITCODE" }
}

if (-not $SkipTests) {
  Write-Host "[2/4] Running flutter test..." -ForegroundColor Yellow
  flutter test
  if ($LASTEXITCODE -ne 0) { throw "flutter test failed with exit code $LASTEXITCODE" }
}

$dartDefines = @(
  "--dart-define=APP_ENV=$AppEnv",
  "--dart-define=USE_FIREBASE=true"
)
if (-not [string]::IsNullOrWhiteSpace($GoogleMapsApiKey)) {
  $dartDefines += "--dart-define=GOOGLE_MAPS_API_KEY=$GoogleMapsApiKey"
  Write-Host "Google Maps API key provided via -GoogleMapsApiKey." -ForegroundColor DarkGray
}

Write-Host "[3/4] Building Consumer Web App -> build/web ..." -ForegroundColor Yellow
$consumerArgs = @("build", "web", "--release", "--base-href", "/") + $dartDefines
& flutter @consumerArgs
if ($LASTEXITCODE -ne 0) { throw "Consumer web build failed with exit code $LASTEXITCODE" }

Write-Host "[4/4] Building Enterprise Admin & DevOps Portal -> build/web/admin ..." -ForegroundColor Yellow
$adminArgs = @("build", "web", "--release", "-t", "lib/admin_main.dart", "--base-href", "/admin/", "-o", "build/web/admin") + $dartDefines
& flutter @adminArgs
if ($LASTEXITCODE -ne 0) { throw "Admin web build failed with exit code $LASTEXITCODE" }

Copy-Item -Path "web/health.json" -Destination "build/web/health.json" -Force
Copy-Item -Path "vercel.json" -Destination "build/web/vercel.json" -Force

Write-Host "=== Build Complete: Consumer (/) + Admin (/admin/) + Health (/health.json) ===" -ForegroundColor Green
