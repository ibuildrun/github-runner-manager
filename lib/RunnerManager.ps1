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
    Write-Host "Stopping runner..." -ForegroundColor Cyan
    
    # Stop scheduled task
    $taskName = Get-ScheduledTaskName -Repository $Config.Repository
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task -and $task.State -eq "Running") {
        Stop-ScheduledTask -TaskName $taskName
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
