#!/usr/bin/env pwsh
# Install GitHub Actions Runner for AVYX as Windows Service

param(
    [string]$InstallPath = "C:\actions-runner",
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AVYX GitHub Actions Runner Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Validate token
if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host "Error: GITHUB_TOKEN environment variable is required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set it with:" -ForegroundColor Yellow
    Write-Host '  $env:GITHUB_TOKEN = "ghp_..."' -ForegroundColor White
    exit 1
}

# Create installation directory
Write-Host "Creating installation directory: $InstallPath" -ForegroundColor Yellow
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

Set-Location $InstallPath

# Download runner
Write-Host "Downloading GitHub Actions Runner..." -ForegroundColor Yellow
$runnerVersion = "2.331.0"
$runnerUrl = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
$runnerZip = "actions-runner-win-x64-$runnerVersion.zip"

if (Test-Path $runnerZip) {
    Write-Host "Runner package already exists, skipping download" -ForegroundColor Green
} else {
    Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -ErrorAction Stop
    Write-Host "Downloaded successfully" -ForegroundColor Green
}

# Extract runner
Write-Host "Extracting runner..." -ForegroundColor Yellow
Expand-Archive -Path $runnerZip -DestinationPath $InstallPath -Force
Write-Host "Extracted successfully" -ForegroundColor Green
Write-Host ""

# Configure runner
Write-Host "Configuring runner..." -ForegroundColor Yellow
$runnerName = "avyx-runner-$(Get-Random -Minimum 1000 -Maximum 9999)"

& ".\config.cmd" `
    --url "https://github.com/ibuildrun/avyx" `
    --token (Invoke-RestMethod `
        -Uri "https://api.github.com/repos/ibuildrun/avyx/actions/runners/registration-token" `
        -Method POST `
        -Headers @{ Authorization = "token $GitHubToken" } `
        -ErrorAction Stop).token `
    --name $runnerName `
    --work "_work" `
    --labels "windows,self-hosted,avyx" `
    --unattended `
    --replace

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to configure runner" -ForegroundColor Red
    exit 1
}

Write-Host "Runner configured successfully" -ForegroundColor Green
Write-Host ""

# Install as service
Write-Host "Installing runner as Windows Service..." -ForegroundColor Yellow
& ".\svc.cmd" install

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install service" -ForegroundColor Red
    exit 1
}

Write-Host "Service installed successfully" -ForegroundColor Green
Write-Host ""

# Start service
Write-Host "Starting runner service..." -ForegroundColor Yellow
& ".\svc.cmd" start

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start service" -ForegroundColor Red
    exit 1
}

Write-Host "Service started successfully" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Runner Details:" -ForegroundColor Cyan
Write-Host "  Name: $runnerName" -ForegroundColor White
Write-Host "  Path: $InstallPath" -ForegroundColor White
Write-Host "  Repository: https://github.com/ibuildrun/avyx" -ForegroundColor White
Write-Host ""
Write-Host "Service Management:" -ForegroundColor Cyan
Write-Host "  Start:   & '$InstallPath\svc.cmd' start" -ForegroundColor White
Write-Host "  Stop:    & '$InstallPath\svc.cmd' stop" -ForegroundColor White
Write-Host "  Status:  Get-Service -Name 'GitHub Actions Runner' | Select-Object Status" -ForegroundColor White
Write-Host ""
Write-Host "Check runner status: https://github.com/ibuildrun/avyx/settings/actions/runners" -ForegroundColor Cyan
Write-Host ""
