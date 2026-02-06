# Auto-Start Management Module

. "$PSScriptRoot\Config.ps1"

function Enable-RunnerAutoStart {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    if (-not (Test-AdminPrivileges)) { return }
    
    Write-Host ""
    Write-Host "Enabling auto-start..." -ForegroundColor Cyan
    
    if (-not (Test-Path "$RunnerPath\run.cmd")) {
        Write-Host "Runner not installed. Please install first." -ForegroundColor Red
        return
    }
    
    $taskName = Get-ScheduledTaskName -Repository $Config.Repository
    
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

function Disable-RunnerAutoStart {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    if (-not (Test-AdminPrivileges)) { return }
    
    Write-Host ""
    Write-Host "Disabling auto-start..." -ForegroundColor Cyan
    
    $taskName = Get-ScheduledTaskName -Repository $Config.Repository
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Auto-start disabled" -ForegroundColor Green
    } else {
        Write-Host "Auto-start is not enabled" -ForegroundColor Yellow
    }
}
