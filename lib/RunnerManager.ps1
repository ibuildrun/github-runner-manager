# Runner Process Management Module

function Start-GitHubRunner {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Starting runner..." -ForegroundColor Cyan
    
    if (-not (Test-Path "$RunnerPath\run.cmd")) {
        Write-Host "Runner not installed. Please install first." -ForegroundColor Red
        return
    }
    
    # Check if scheduled task exists
    $taskName = Get-ScheduledTaskName -Repository $Config.Repository
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Start-ScheduledTask -TaskName $taskName
        Write-Host "Scheduled task triggered, waiting for runner process..." -ForegroundColor Yellow
    } else {
        # Start as background job
        $job = Start-Job -ScriptBlock {
            param($path)
            Set-Location $path
            & ".\run.cmd"
        } -ArgumentList $RunnerPath
        
        Write-Host "Background job started (Job ID: $($job.Id)), waiting for runner process..." -ForegroundColor Yellow
    }
    
    # Wait and verify the runner process is actually running for THIS path
    $maxWait = 15
    $waited = 0
    $processFound = $false
    $foundProc = $null
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waited++
        $procs = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($p in $procs) {
                try {
                    if ($p.Path -and $p.Path.StartsWith($RunnerPath, [StringComparison]::OrdinalIgnoreCase)) {
                        $processFound = $true
                        $foundProc = $p
                        break
                    }
                } catch { continue }
            }
            if ($processFound) { break }
        }
    }
    
    Write-Host ""
    if ($processFound) {
        Write-Host "Runner is running (PID: $($foundProc.Id))" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Runner process not detected after ${maxWait}s" -ForegroundColor Red
        Write-Host "The runner may have failed to start. Check logs:" -ForegroundColor Yellow
        
        # Show last few lines from runner diag log
        $diagPath = "$RunnerPath\_diag"
        if (Test-Path $diagPath) {
            $latestLog = Get-ChildItem $diagPath -Filter "Runner_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestLog) {
                Write-Host ""
                Write-Host "Last lines from $($latestLog.Name):" -ForegroundColor Cyan
                Get-Content $latestLog.FullName -Tail 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            }
        }
        
        # Check if scheduled task ended with error
        if ($task) {
            $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
            if ($taskInfo -and $taskInfo.LastTaskResult -ne 0) {
                Write-Host ""
                Write-Host "Scheduled task last result code: $($taskInfo.LastTaskResult)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "Check status: https://github.com/$($Config.Repository)/settings/actions/runners" -ForegroundColor Cyan
}

function Stop-GitHubRunner {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Stopping runner at: $RunnerPath" -ForegroundColor Cyan
    
    $stopped = $false
    
    # Stop scheduled task
    $taskName = Get-ScheduledTaskName -Repository $Config.Repository
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task -and $task.State -eq "Running") {
        Stop-ScheduledTask -TaskName $taskName
        Write-Host "Stopped scheduled task" -ForegroundColor Green
        $stopped = $true
    }
    
    # Stop only the process belonging to this runner path
    $processes = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                $procPath = $proc.Path
                if ($procPath -and $procPath.StartsWith($RunnerPath, [StringComparison]::OrdinalIgnoreCase)) {
                    Stop-Process -Id $proc.Id -Force
                    Write-Host "Stopped runner process (PID: $($proc.Id))" -ForegroundColor Green
                    $stopped = $true
                }
            } catch {
                # Process may have already exited
                continue
            }
        }
    }
    
    # Stop jobs related to this runner path
    $jobs = Get-Job | Where-Object { $_.Command -like "*run.cmd*" }
    if ($jobs) {
        $jobs | Stop-Job
        $jobs | Remove-Job
        Write-Host "Stopped background jobs" -ForegroundColor Green
        $stopped = $true
    }
    
    if (-not $stopped) {
        Write-Host "Runner is not running" -ForegroundColor Yellow
    }
}

function Show-RunnerLogs {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    if (-not (Test-Path "$RunnerPath\_diag")) {
        Write-Host "No logs found" -ForegroundColor Yellow
        return
    }
    
    $latestLog = Get-ChildItem "$RunnerPath\_diag" -Filter "Worker_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestLog) {
        Write-Host "Latest log: $($latestLog.Name)" -ForegroundColor Cyan
        Write-Host "Last modified: $($latestLog.LastWriteTime)" -ForegroundColor Gray
        Write-Host ""
        Get-Content $latestLog.FullName -Tail 50
    } else {
        Write-Host "No logs found" -ForegroundColor Yellow
    }
}
