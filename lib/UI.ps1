# User Interface Module

function Show-MainMenu {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  GitHub Actions Runner Manager" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Config.Repository) {
        Write-Host "Repository: $($Config.Repository)" -ForegroundColor Green
    } else {
        Write-Host "Repository: Not configured" -ForegroundColor Yellow
    }
    
    $tokenStatus = if ($Config.GitHubToken) { "Configured" } else { "Not set" }
    Write-Host "Token: $tokenStatus" -ForegroundColor $(if ($Config.GitHubToken) { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "Configuration" -ForegroundColor Cyan
    Write-Host "  1. Configure GitHub Token" -ForegroundColor White
    Write-Host "  2. Select Repository" -ForegroundColor White
    Write-Host ""
    Write-Host "Runner Management" -ForegroundColor Cyan
    Write-Host "  3. Install Runner" -ForegroundColor White
    Write-Host "  4. Start Runner" -ForegroundColor White
    Write-Host "  5. Stop Runner" -ForegroundColor White
    Write-Host "  6. Check Status" -ForegroundColor White
    Write-Host "  7. View Logs" -ForegroundColor White
    Write-Host ""
    Write-Host "Auto-Start" -ForegroundColor Cyan
    Write-Host "  8. Enable Auto-Start (on boot)" -ForegroundColor White
    Write-Host "  9. Disable Auto-Start" -ForegroundColor White
    Write-Host ""
    Write-Host "Advanced" -ForegroundColor Cyan
    Write-Host "  10. Uninstall Runner" -ForegroundColor White
    Write-Host "  11. Clear Configuration" -ForegroundColor White
    Write-Host ""
    Write-Host "  0. Exit" -ForegroundColor White
    Write-Host ""
}

function Show-TokenConfigurationHelp {
    Write-Host ""
    Write-Host "GitHub Token Configuration" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You need a Personal Access Token with permissions:" -ForegroundColor Yellow
    Write-Host "  - repo (Full control of private repositories)" -ForegroundColor White
    Write-Host "  - workflow (Update GitHub Action workflows)" -ForegroundColor White
    Write-Host ""
    Write-Host "Create token: https://github.com/settings/tokens/new" -ForegroundColor Cyan
    Write-Host ""
}

function Show-TokenStorageOptions {
    Write-Host ""
    Write-Host "Where to store the token?" -ForegroundColor Cyan
    Write-Host "  1. Windows Environment Variable (User-level, persistent)" -ForegroundColor White
    Write-Host "  2. Configuration File (Local, base64 encoded)" -ForegroundColor White
    Write-Host "  3. Session Only (Not saved, re-enter each time)" -ForegroundColor White
    Write-Host ""
}

function Show-RepositoryList {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Repositories
    )
    
    Write-Host ""
    Write-Host "Found $($Repositories.Count) repositories:" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 0; $i -lt $Repositories.Count; $i++) {
        $repo = $Repositories[$i]
        $visibility = if ($repo.private) { "🔒" } else { "🌐" }
        Write-Host "$($i + 1). $visibility $($repo.full_name)" -ForegroundColor White
        if ($repo.description) {
            Write-Host "   $($repo.description)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

function Show-Status {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Runner Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Configuration
    Write-Host "Repository: $($Config.Repository ?? 'Not configured')" -ForegroundColor $(if ($Config.Repository) { "Green" } else { "Yellow" })
    Write-Host "Token: $(if ($Config.GitHubToken) { 'Configured' } else { 'Not set' })" -ForegroundColor $(if ($Config.GitHubToken) { "Green" } else { "Yellow" })
    Write-Host ""
    
    # Check installation
    if (Test-Path "$RunnerPath\run.cmd") {
        Write-Host "Installation: Installed at $RunnerPath" -ForegroundColor Green
    } else {
        Write-Host "Installation: Not installed" -ForegroundColor Red
        return
    }
    
    # Check scheduled task
    $taskName = Get-ScheduledTaskName -Repository $Config.Repository
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
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
    
    if ($Config.Repository) {
        Write-Host ""
        Write-Host "GitHub: https://github.com/$($Config.Repository)/settings/actions/runners" -ForegroundColor Cyan
    }
}

function Get-ScheduledTaskName {
    param(
        [string]$Repository
    )
    
    if ($Repository) {
        return "GitHub Runner - $($Repository.Replace('/', '-'))"
    }
    return "GitHub Actions Runner"
}

Export-ModuleMember -Function Show-MainMenu, Show-TokenConfigurationHelp, Show-TokenStorageOptions, Show-RepositoryList, Show-Status, Get-ScheduledTaskName
