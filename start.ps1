#!/usr/bin/env pwsh
# AVYX Deploy Runner - Quick Start Script

$ErrorActionPreference = "Stop"

Write-Host "AVYX Deploy Runner Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Check if .env.runner exists
if (-not (Test-Path ".env.runner")) {
    Write-Host ""
    Write-Host ".env.runner not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Creating .env.runner from example..." -ForegroundColor Yellow
    Copy-Item ".env.runner.example" ".env.runner"
    
    Write-Host ""
    Write-Host "Please edit .env.runner and add your GitHub token:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   1. Go to: https://github.com/settings/tokens/new" -ForegroundColor White
    Write-Host "   2. Select: repo, workflow" -ForegroundColor White
    Write-Host "   3. Generate token" -ForegroundColor White
    Write-Host "   4. Edit .env.runner and paste your token" -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host "Open .env.runner now? (Y/n)"
    if ($response -ne "n" -and $response -ne "N") {
        notepad ".env.runner"
    }
    
    Write-Host ""
    Write-Host "After adding your token, run this script again." -ForegroundColor Yellow
    exit 0
}

# Check if GITHUB_TOKEN is set
$envContent = Get-Content ".env.runner" -Raw
if ($envContent -match "GITHUB_TOKEN=ghp_your_token_here" -or $envContent -notmatch "GITHUB_TOKEN=ghp_") {
    Write-Host ""
    Write-Host "GitHub token not configured!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please edit .env.runner and add your GitHub token." -ForegroundColor Yellow
    
    $response = Read-Host "Open .env.runner now? (Y/n)"
    if ($response -ne "n" -and $response -ne "N") {
        notepad ".env.runner"
    }
    
    exit 0
}

Write-Host "Configuration found" -ForegroundColor Green
Write-Host ""

# Check if container is already running
$containerRunning = docker ps --filter "name=universal-runner" --format "{{.Names}}" 2>$null
if ($containerRunning -eq "universal-runner") {
    Write-Host "Runner is already running" -ForegroundColor Blue
    Write-Host ""
    
    $response = Read-Host "Restart runner? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host ""
        Write-Host "Restarting runner..." -ForegroundColor Yellow
        docker-compose restart
        Write-Host "Runner restarted" -ForegroundColor Green
    }
} else {
    Write-Host "Starting runner..." -ForegroundColor Yellow
    docker-compose up -d --build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Runner started successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to start runner" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Runner Status" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Wait a bit for container to start
Start-Sleep -Seconds 2

# Show logs
Write-Host "Recent logs:" -ForegroundColor Yellow
docker logs --tail 20 universal-runner

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Check runner status: https://github.com/ibuildrun/avyx/settings/actions/runners" -ForegroundColor White
Write-Host "  2. Push to main branch to trigger deploy" -ForegroundColor White
Write-Host "  3. View logs: docker logs -f universal-runner" -ForegroundColor White
Write-Host ""
Write-Host "Production URL: https://avyx.ibuildrun.ru" -ForegroundColor Cyan
Write-Host ""
