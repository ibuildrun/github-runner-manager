#!/usr/bin/env pwsh
# Start Docker Desktop and Runner

Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan

# Try common Docker installation paths
$dockerPaths = @(
    "C:\Program Files\Docker\Docker\Docker.exe",
    "C:\Program Files (x86)\Docker\Docker\Docker.exe",
    "$env:ProgramFiles\Docker\Docker\Docker.exe"
)

$dockerFound = $false
foreach ($path in $dockerPaths) {
    if (Test-Path $path) {
        Write-Host "Found Docker at: $path" -ForegroundColor Green
        Start-Process $path
        $dockerFound = $true
        break
    }
}

if (-not $dockerFound) {
    Write-Host "Please start Docker Desktop manually..." -ForegroundColor Cyan
    Read-Host "Press Enter when Docker is running"
}

Write-Host ""
Write-Host "Waiting for Docker to be ready..." -ForegroundColor Yellow
for ($i = 1; $i -le 30; $i++) {
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 1
}
Write-Host ""

Write-Host "Starting runner setup..." -ForegroundColor Cyan
.\start.ps1
