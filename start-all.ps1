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
    Write-Host "Docker Desktop not found in standard locations" -ForegroundColor Yellow
    Write-Host "Please start Docker Desktop manually and press Enter..." -ForegroundColor Yellow
    Read-Host
}

Write-Host "Waiting for Docker to start (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "Starting runner setup..." -ForegroundColor Cyan
.\start.ps1
