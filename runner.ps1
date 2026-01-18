#!/usr/bin/env pwsh
# AVYX GitHub Actions Runner Manager
# Main script for managing self-hosted runner

param(
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$RunnerPath = "C:\actions-runner"
)

$ErrorActionPreference = "Stop"

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  AVYX GitHub Actions Runner Manager" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Install Runner" -ForegroundColor White
    Write-Host "2. Start Runner" -ForegroundColor White
    Write-Host "3. Stop Runner" -ForegroundColor White
    Write-Host "4. Check Status" -ForegroundColor White
    Write-Host "5. Enable Auto-Start (on boot)" -ForegroundColor White
    Write-Host "6. Disable Auto-Start" -ForegroundColor White
    Write-Host "7. Uninstall Runner" -ForegroundColor White
    Write-Host "8. View Logs" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor White
    Write-Host ""
}

function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Host "Error: This operation requires Administrator privileges" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return $false
    }
    return $true
}

function Install-Runner {
    Write-Host ""
    Write-Host "Installing GitHub Actions Runner..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check token
    if ([string]::IsNullOrEmpty($GitHubToken)) {
        Write-Host "GitHub Token is required" -ForegroundColor Yellow
        $GitHubToken = Read-Host "Enter GitHub Token (ghp_...)"
        if ([string]::IsNullOrEmpty($GitHubToken)) {
            Write-Host "Installation cancelled" -ForegroundColor Red
            return
        }
    }
    
    # Check if already installed
    if (Test-Path "$RunnerPath\run.cmd") {
        Write-Host "Runner is already installed at: $RunnerPath" -ForegroundColor Yellow
        $response = Read-Host "Reinstall? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            return
        }
        
        # Remove old config
        if (Test-Path "$RunnerPath\.runner") {
            Write-Host "Removing old configuration..." -ForegroundColor Yellow
            Set-Location $RunnerPath
            & ".\config.cmd" remove --token (Get-RegistrationToken)
        }
    }
    
    # Create directory
    if (-not (Test-Path $RunnerPath)) {
        New-Item -ItemType Directory -Path $RunnerPath -Force | Out-Null
    }
    
    Set-Location $RunnerPath
    
    # Download
    Write-Host "Downloading runner..." -ForegroundColor Yellow
    $runnerVersion = "2.331.0"
    $runnerUrl = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
    $runnerZip = "actions-runner-win-x64-$runnerVersion.zip"
    
    if (-not (Test-Path $runnerZip)) {
        Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -ErrorAction Stop
    }
    
    # Extract
    Write-Host "Extracting runner..." -ForegroundColor Yellow
    Expand-Archive -Path $runnerZip -DestinationPath $RunnerPath -Force
    
    # Configure
    Write-Host "Configuring runner..." -ForegroundColor Yellow
    $runnerName = "avyx-runner-$(Get-Random -Minimum 1000 -Maximum 9999)"
    $registrationToken = Get-RegistrationToken
    
    & ".\config.cmd" `
        --url "https://github.com/ibuildrun/avyx" `
        --token $registrationToken `
        --name $runnerName `
        --work "_work" `
        --labels "windows,self-hosted,avyx" `
        --unattended `
        --replace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Runner installed successfully!" -ForegroundColor Green
        Write-Host "Name: $runnerName" -ForegroundColor Cyan
        Write-Host "Path: $RunnerPath" -ForegroundColor Cyan
    } else {
        Write-Host "Installation failed" -ForegroundColor Red
    }
}

function Start-RunnerTask {
    Write-Host ""
    Write-Host "Starting runner..." -ForegroundColor Cyan
    
    if (-not (Test-Path "$RunnerPath\run.cmd")) {
        Write-Host "Runner not installed. Please install first." -ForegroundColor Red
        return
    }
    
    # Check if scheduled task exists
    $task = Get-ScheduledTask -TaskName "AVYX GitHub Actions Runner" -ErrorAction SilentlyContinue
    if ($task) {
        Start-ScheduledTask -TaskName "AVYX GitHub Actions Runner"
        Write-Host "Runner started via scheduled task" -ForegroundColor Green
    } else {
        # Start as background job
        $job = Start-Job -ScriptBlock {
            param($path)
            Set-Location $path
            & ".\run.cmd"
        } -ArgumentList $RunnerPath
        
        Write-Host "Runner started in background (Job ID: $($job.Id))" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Check status: https://github.com/ibuildrun/avyx/settings/actions/runners" -ForegroundColor Cyan
}

function Stop-RunnerTask {
    Write-Host ""
    Write-Host "Stopping runner..." -ForegroundColor Cyan
    
    # Stop scheduled task
    $task = Get-ScheduledTask -TaskName "AVYX GitHub Actions Runner" -ErrorAction SilentlyContinue
    if ($task -and $task.State -eq "Running") {
        Stop-ScheduledTask -TaskName "AVYX GitHub Actions Runner"
        Write-Host "Stopped scheduled task" -ForegroundColor Green
    }
    
    # Stop process
    $process = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Name "Runner.Listener" -Force
        Write-Host "Stopped runner process" -ForegroundColor Green
    }
    
    # Stop jobs
    $jobs = Get-Job | Where-Object { $_.Command -like "*run.cmd*" }
    if ($jobs) {
        $jobs | Stop-Job
        $jobs | Remove-Job
        Write-Host "Stopped background jobs" -ForegroundColor Green
    }
    
    if (-not $task -and -not $process -and -not $jobs) {
        Write-Host "Runner is not running" -ForegroundColor Yellow
    }
}

function Show-Status {
    Write-Host ""
    Write-Host "Runner Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Check installation
    if (Test-Path "$RunnerPath\run.cmd") {
        Write-Host "Installation: Installed at $RunnerPath" -ForegroundColor Green
    } else {
        Write-Host "Installation: Not installed" -ForegroundColor Red
        return
    }
    
    # Check scheduled task
    $task = Get-ScheduledTask -TaskName "AVYX GitHub Actions Runner" -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "Auto-Start: Enabled ($($task.State))" -ForegroundColor Green
    } else {
        Write-Host "Auto-Start: Disabled" -ForegroundColor Yellow
    }
    
    # Check process
    $process = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Process: Running (PID: $($process.Id))" -ForegroundColor Green
    } else {
        Write-Host "Process: Not running" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "GitHub: https://github.com/ibuildrun/avyx/settings/actions/runners" -ForegroundColor Cyan
}

function Enable-AutoStart {
    if (-not (Test-Admin)) { return }
    
    Write-Host ""
    Write-Host "Enabling auto-start..." -ForegroundColor Cyan
    
    if (-not (Test-Path "$RunnerPath\run.cmd")) {
        Write-Host "Runner not installed. Please install first." -ForegroundColor Red
        return
    }
    
    $taskName = "AVYX GitHub Actions Runner"
    
    # Remove existing
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Create task
    $action = New-ScheduledTaskAction `
        -Execute "cmd.exe" `
        -Argument "/c cd /d $RunnerPath && run.cmd" `
        -WorkingDirectory $RunnerPath
    
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest
    
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Force | Out-Null
    
    Write-Host "Auto-start enabled" -ForegroundColor Green
    Write-Host "Runner will start automatically on boot" -ForegroundColor Cyan
}

function Disable-AutoStart {
    if (-not (Test-Admin)) { return }
    
    Write-Host ""
    Write-Host "Disabling auto-start..." -ForegroundColor Cyan
    
    $task = Get-ScheduledTask -TaskName "AVYX GitHub Actions Runner" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "AVYX GitHub Actions Runner" -Confirm:$false
        Write-Host "Auto-start disabled" -ForegroundColor Green
    } else {
        Write-Host "Auto-start is not enabled" -ForegroundColor Yellow
    }
}

function Uninstall-Runner {
    if (-not (Test-Admin)) { return }
    
    Write-Host ""
    Write-Host "Uninstalling runner..." -ForegroundColor Cyan
    
    $response = Read-Host "Are you sure? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        return
    }
    
    # Stop runner
    Stop-RunnerTask
    
    # Disable auto-start
    Disable-AutoStart
    
    # Remove config
    if (Test-Path "$RunnerPath\.runner") {
        Write-Host "Removing configuration..." -ForegroundColor Yellow
        Set-Location $RunnerPath
        & ".\config.cmd" remove --token (Get-RegistrationToken)
    }
    
    # Remove directory
    if (Test-Path $RunnerPath) {
        Write-Host "Removing files..." -ForegroundColor Yellow
        Remove-Item -Path $RunnerPath -Recurse -Force
    }
    
    Write-Host "Runner uninstalled" -ForegroundColor Green
}

function Show-Logs {
    Write-Host ""
    if (-not (Test-Path "$RunnerPath\_diag")) {
        Write-Host "No logs found" -ForegroundColor Yellow
        return
    }
    
    $latestLog = Get-ChildItem "$RunnerPath\_diag" -Filter "Worker_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestLog) {
        Write-Host "Latest log: $($latestLog.Name)" -ForegroundColor Cyan
        Write-Host ""
        Get-Content $latestLog.FullName -Tail 50
    } else {
        Write-Host "No logs found" -ForegroundColor Yellow
    }
}

function Get-RegistrationToken {
    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/ibuildrun/avyx/actions/runners/registration-token" `
            -Method POST `
            -Headers @{ Authorization = "token $GitHubToken" } `
            -ErrorAction Stop
        return $response.token
    } catch {
        Write-Host "Error getting registration token: $_" -ForegroundColor Red
        return $null
    }
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" { Install-Runner }
        "2" { Start-RunnerTask }
        "3" { Stop-RunnerTask }
        "4" { Show-Status }
        "5" { Enable-AutoStart }
        "6" { Disable-AutoStart }
        "7" { Uninstall-Runner }
        "8" { Show-Logs }
        "0" { break }
        default { Write-Host "Invalid option" -ForegroundColor Red }
    }
    
    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
} while ($choice -ne "0")

Write-Host ""
Write-Host "Goodbye!" -ForegroundColor Cyan
