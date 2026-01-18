#!/usr/bin/env pwsh
# Start Docker Desktop and Runner

Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan
Start-Process "C:\Program Files\Docker\Docker\Docker.exe"

Write-Host "Waiting for Docker to start (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "Starting runner setup..." -ForegroundColor Cyan
.\start.ps1
