param(
  [switch]$SkipAnalyze,
  [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

Write-Host "=== MASHWAR Platform DevOps Build ===" -ForegroundColor Cyan

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

Write-Host "[3/4] Building Consumer Web App -> build/web ..." -ForegroundColor Yellow
flutter build web --release --base-href /
if ($LASTEXITCODE -ne 0) { throw "Consumer web build failed with exit code $LASTEXITCODE" }

Write-Host "[4/4] Building Enterprise Admin & DevOps Portal -> build/web/admin ..." -ForegroundColor Yellow
flutter build web --release -t lib/admin_main.dart --base-href /admin/ -o build/web/admin
if ($LASTEXITCODE -ne 0) { throw "Admin web build failed with exit code $LASTEXITCODE" }

Copy-Item -Path "web/health.json" -Destination "build/web/health.json" -Force
Copy-Item -Path "vercel.json" -Destination "build/web/vercel.json" -Force

Write-Host "=== Build Complete: Consumer (/) + Admin (/admin/) + Health (/health.json) ===" -ForegroundColor Green
