#!/usr/bin/env pwsh
# Start GitHub Actions Runner for AVYX in background

param(
    [string]$RunnerPath = "C:\actions-runner"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AVYX GitHub Actions Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if runner exists
if (-not (Test-Path "$RunnerPath\run.cmd")) {
    Write-Host "Error: Runner not found at $RunnerPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install runner first:" -ForegroundColor Yellow
    Write-Host "  .\setup-runner.ps1 -Action install" -ForegroundColor White
    exit 1
}

# Check if already running
$runnerProcess = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
if ($runnerProcess) {
    Write-Host "Runner is already running (PID: $($runnerProcess.Id))" -ForegroundColor Green
    Write-Host ""
    Write-Host "To stop: Stop-Process -Name 'Runner.Listener'" -ForegroundColor Yellow
    exit 0
}

# Start runner in background
Write-Host "Starting runner in background..." -ForegroundColor Yellow
$job = Start-Job -ScriptBlock {
    param($path)
    Set-Location $path
    & ".\run.cmd"
} -ArgumentList $RunnerPath

Write-Host "Runner started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Job ID: $($job.Id)" -ForegroundColor Cyan
Write-Host "Runner Path: $RunnerPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor Yellow
Write-Host "  Check status: Get-Job -Id $($job.Id)" -ForegroundColor White
Write-Host "  View output:  Receive-Job -Id $($job.Id) -Keep" -ForegroundColor White
Write-Host "  Stop runner:  Stop-Job -Id $($job.Id); Remove-Job -Id $($job.Id)" -ForegroundColor White
Write-Host ""
Write-Host "Check on GitHub: https://github.com/ibuildrun/avyx/settings/actions/runners" -ForegroundColor Cyan
Write-Host ""
