#!/usr/bin/env pwsh
# GitHub Actions Runner Entrypoint for AVYX

param(
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$RunnerName = $env:RUNNER_NAME,
    [string]$WorkDir = $env:RUNNER_WORKDIR
)

# Validate inputs
if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host "Error: GITHUB_TOKEN environment variable is required" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($RunnerName)) {
    $RunnerName = "avyx-runner-$(Get-Random -Minimum 1000 -Maximum 9999)"
}

if ([string]::IsNullOrEmpty($WorkDir)) {
    $WorkDir = "_work"
}

Write-Host "=== GitHub Actions Runner for AVYX ===" -ForegroundColor Cyan
Write-Host "Runner Name: $RunnerName" -ForegroundColor Green
Write-Host "Work Directory: $WorkDir" -ForegroundColor Green
Write-Host ""

# Get registration token
Write-Host "Getting registration token..." -ForegroundColor Yellow
$tokenResponse = Invoke-RestMethod `
    -Uri "https://api.github.com/repos/ibuildrun/avyx/actions/runners/registration-token" `
    -Method POST `
    -Headers @{ Authorization = "token $GitHubToken" } `
    -ErrorAction Stop

$registrationToken = $tokenResponse.token

if ([string]::IsNullOrEmpty($registrationToken)) {
    Write-Host "Error: Failed to get registration token" -ForegroundColor Red
    exit 1
}

Write-Host "Registration token obtained" -ForegroundColor Green
Write-Host ""

# Configure runner
Write-Host "Configuring runner..." -ForegroundColor Yellow
& ".\config.cmd" `
    --url "https://github.com/ibuildrun/avyx" `
    --token $registrationToken `
    --name $RunnerName `
    --work $WorkDir `
    --labels "windows,self-hosted,avyx" `
    --unattended `
    --replace

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to configure runner" -ForegroundColor Red
    exit 1
}

Write-Host "Runner configured successfully" -ForegroundColor Green
Write-Host ""

# Run the runner
Write-Host "Starting runner..." -ForegroundColor Cyan
Write-Host "Runner is ready to accept jobs!" -ForegroundColor Green
Write-Host ""

& ".\run.cmd"
