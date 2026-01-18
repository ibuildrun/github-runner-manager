#!/usr/bin/env pwsh
# Install AVYX Runner as Windows Scheduled Task (auto-start on boot)

param(
    [string]$RunnerPath = "C:\actions-runner"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AVYX Runner Auto-Start Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

# Check if runner exists
if (-not (Test-Path "$RunnerPath\run.cmd")) {
    Write-Host "Error: Runner not found at $RunnerPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install runner first:" -ForegroundColor Yellow
    Write-Host "  .\setup-runner.ps1 -Action install" -ForegroundColor White
    exit 1
}

# Create scheduled task
$taskName = "AVYX GitHub Actions Runner"
$taskDescription = "Auto-start GitHub Actions Runner for AVYX repository"

# Remove existing task if exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Removing existing task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create action
$action = New-ScheduledTaskAction `
    -Execute "cmd.exe" `
    -Argument "/c cd /d $RunnerPath && run.cmd" `
    -WorkingDirectory $RunnerPath

# Create trigger (at startup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Create settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

# Create principal (run as current user)
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

# Register task
Write-Host "Creating scheduled task..." -ForegroundColor Yellow
Register-ScheduledTask `
    -TaskName $taskName `
    -Description $taskDescription `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Force | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Auto-Start Installed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Task Name: $taskName" -ForegroundColor Cyan
Write-Host "Trigger: At system startup" -ForegroundColor Cyan
Write-Host "User: $env:USERNAME" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor Yellow
Write-Host "  Start now:    Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host "  Stop:         Stop-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host "  View status:  Get-ScheduledTask -TaskName '$taskName' | Get-ScheduledTaskInfo" -ForegroundColor White
Write-Host "  Uninstall:    Unregister-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host ""
Write-Host "Runner will start automatically on next reboot" -ForegroundColor Green
Write-Host ""
