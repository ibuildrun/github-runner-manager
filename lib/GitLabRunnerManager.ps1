# GitLab Runner Lifecycle Management Module

function Start-GitLabRunner {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Starting GitLab Runner..." -ForegroundColor Yellow
    
    $binaryPath = Join-Path $RunnerPath "gitlab-runner.exe"
    
    if (-not (Test-Path $binaryPath)) {
        Write-Host "GitLab Runner not installed at: $RunnerPath" -ForegroundColor Red
        Write-Host "Please install runner first (option 5)" -ForegroundColor Yellow
        return
    }
    
    # Check if already running for this path
    $alreadyRunning = Test-GitLabRunnerProcess -RunnerPath $RunnerPath
    if ($alreadyRunning) {
        Write-Host "Runner is already running at: $RunnerPath" -ForegroundColor Yellow
        return
    }
    
    # Start runner
    try {
        Start-Process -FilePath $binaryPath `
            -ArgumentList "run" `
            -WorkingDirectory $RunnerPath `
            -WindowStyle Hidden
        
        Start-Sleep -Seconds 2
        
        $proc = Find-GitLabRunnerProcess -RunnerPath $RunnerPath
        if ($proc) {
            Write-Host "Runner started successfully (PID: $($proc.Id))" -ForegroundColor Green
        } else {
            Write-Host "Runner failed to start" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error starting runner: $_" -ForegroundColor Red
    }
}

function Stop-GitLabRunner {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Stopping GitLab Runner at: $RunnerPath" -ForegroundColor Yellow
    
    $proc = Find-GitLabRunnerProcess -RunnerPath $RunnerPath
    
    if (-not $proc) {
        Write-Host "Runner is not running at: $RunnerPath" -ForegroundColor Yellow
        return
    }
    
    try {
        Stop-Process -Id $proc.Id -Force
        Start-Sleep -Seconds 2
        
        $proc = Find-GitLabRunnerProcess -RunnerPath $RunnerPath
        if (-not $proc) {
            Write-Host "Runner stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "Runner failed to stop" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error stopping runner: $_" -ForegroundColor Red
    }
}

function Test-GitLabRunnerProcess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    $proc = Find-GitLabRunnerProcess -RunnerPath $RunnerPath
    return ($null -ne $proc)
}

function Find-GitLabRunnerProcess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    $processes = Get-Process -Name "gitlab-runner" -ErrorAction SilentlyContinue
    if (-not $processes) {
        return $null
    }
    
    foreach ($proc in $processes) {
        try {
            $procPath = $proc.Path
            if ($procPath -and $procPath.StartsWith($RunnerPath, [StringComparison]::OrdinalIgnoreCase)) {
                return $proc
            }
        } catch {
            continue
        }
    }
    
    return $null
}

function Get-GitLabRunnerStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "GitLab Runner Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $binaryPath = Join-Path $RunnerPath "gitlab-runner.exe"
    
    # Check installation
    if (Test-Path $binaryPath) {
        Write-Host "Installation: Installed at $RunnerPath" -ForegroundColor Green
        
        # Get version
        try {
            $version = & $binaryPath --version 2>&1 | Select-Object -First 1
            Write-Host "Version: $version" -ForegroundColor Cyan
        } catch {
            Write-Host "Version: Unknown" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Installation: Not installed" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    
    # Check process for this specific path
    $proc = Find-GitLabRunnerProcess -RunnerPath $RunnerPath
    if ($proc) {
        Write-Host "Process: Running (PID: $($proc.Id))" -ForegroundColor Green
        Write-Host "Memory: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Cyan
        
        $uptime = (Get-Date) - $proc.StartTime
        Write-Host "Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Cyan
    } else {
        Write-Host "Process: Not running" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Check config
    $configPath = Join-Path $RunnerPath "config.toml"
    if (Test-Path $configPath) {
        Write-Host "Configuration: $configPath" -ForegroundColor Green
        
        # Try to get runner info
        try {
            $config = Get-Content $configPath -Raw
            if ($config -match 'name = "([^"]+)"') {
                Write-Host "Runner Name: $($matches[1])" -ForegroundColor Cyan
            }
            if ($config -match 'executor = "([^"]+)"') {
                Write-Host "Executor: $($matches[1])" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "Could not read configuration" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Configuration: Not found (runner not registered)" -ForegroundColor Yellow
    }
}

function Show-GitLabRunnerLogs {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath,
        [int]$Lines = 50
    )
    
    Write-Host ""
    Write-Host "GitLab Runner Logs (last $Lines lines)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $logPath = Join-Path $RunnerPath "gitlab-runner.log"
    
    if (-not (Test-Path $logPath)) {
        # Try alternative log location
        $logPath = "$env:USERPROFILE\.gitlab-runner\gitlab-runner.log"
    }
    
    if (Test-Path $logPath) {
        $logs = Get-Content $logPath -Tail $Lines -ErrorAction SilentlyContinue
        if ($logs) {
            $logs | ForEach-Object {
                if ($_ -match "ERROR") {
                    Write-Host $_ -ForegroundColor Red
                } elseif ($_ -match "WARN") {
                    Write-Host $_ -ForegroundColor Yellow
                } elseif ($_ -match "INFO") {
                    Write-Host $_ -ForegroundColor Cyan
                } else {
                    Write-Host $_ -ForegroundColor White
                }
            }
        } else {
            Write-Host "Log file is empty" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Log file not found" -ForegroundColor Yellow
        Write-Host "Expected location: $logPath" -ForegroundColor Gray
    }
}
