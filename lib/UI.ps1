# User Interface Module

function Show-MainMenu {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Clear-Host
    
    # Get platform display name and emoji
    $platformName = $Config.GetPlatformDisplayName()
    $platformEmoji = if ($Config.Platform -eq "gitlab") { "Fox" } else { "Octopus" }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $platformEmoji $platformName $(L 'menu_title')" -ForegroundColor Cyan
    Write-Host "  $(L 'menu_subtitle')" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show platform and instance URL
    Write-Host "$(L 'menu_platform'): $platformName" -ForegroundColor Cyan
    if ($Config.Platform -eq "gitlab" -and $Config.InstanceUrl) {
        Write-Host "$(L 'menu_instance'): $($Config.InstanceUrl)" -ForegroundColor Cyan
    }
    Write-Host ""
    
    if ($Config.Repository) {
        $targetLabel = if ($Config.Platform -eq "gitlab") { 
            if ($Config.TargetType -eq "group") { L "menu_group" } else { L "menu_project" }
        } else { L "menu_repository" }
        Write-Host "${targetLabel}: $($Config.Repository)" -ForegroundColor Green
    } else {
        Write-Host "$(L 'menu_target'): $(L 'menu_not_configured')" -ForegroundColor Yellow
    }
    
    $tokenStatus = if ($Config.GitHubToken) { L "menu_configured" } else { L "menu_not_set" }
    Write-Host "$(L 'menu_token'): $tokenStatus" -ForegroundColor $(if ($Config.GitHubToken) { "Green" } else { "Yellow" })
    
    # Show Telegram status
    $telegramConfig = $Config.GetTelegramConfig()
    if ($telegramConfig.Enabled) {
        Write-Host "$(L 'menu_telegram'): $(L 'menu_enabled') ($($telegramConfig.ChatIds.Count) $(L 'menu_users'))" -ForegroundColor Green
    } else {
        Write-Host "$(L 'menu_telegram'): $(L 'menu_disabled')" -ForegroundColor Gray
    }
    
    # Show Docker runners count
    $dockerRunners = $Config.GetDockerRunners()
    if ($dockerRunners.Count -gt 0) {
        Write-Host "$(L 'menu_docker_runners'): $($dockerRunners.Count) $(L 'menu_containers')" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host (L "menu_configuration") -ForegroundColor Cyan
    Write-Host "  1. $(L 'menu_configure_token' $platformName)" -ForegroundColor White
    
    if ($Config.Platform -eq "gitlab") {
        Write-Host "  2. $(L 'menu_select_project_group')" -ForegroundColor White
        if ($Config.Platform -eq "gitlab") {
            Write-Host "  3. $(L 'menu_configure_instance_url')" -ForegroundColor White
        }
    } else {
        Write-Host "  2. $(L 'menu_select_repository')" -ForegroundColor White
        Write-Host "  3. $(L 'menu_configure_secrets')" -ForegroundColor Yellow
    }
    
    Write-Host "  4. $(L 'menu_switch_platform')" -ForegroundColor Magenta
    Write-Host ""
    Write-Host (L "menu_runner_management") -ForegroundColor Cyan
    Write-Host "  5. $(L 'menu_install_runner')" -ForegroundColor White
    Write-Host "  6. $(L 'menu_start_runner')" -ForegroundColor White
    Write-Host "  7. $(L 'menu_stop_runner')" -ForegroundColor White
    Write-Host "  8. $(L 'menu_check_status')" -ForegroundColor White
    Write-Host "  9. $(L 'menu_view_logs')" -ForegroundColor White
    if ($Config.Platform -eq "gitlab") {
        Write-Host "  10. $(L 'menu_view_active_runners')" -ForegroundColor White
    }
    Write-Host ""
    Write-Host (L "menu_autostart") -ForegroundColor Cyan
    Write-Host "  11. $(L 'menu_enable_autostart')" -ForegroundColor White
    Write-Host "  12. $(L 'menu_disable_autostart')" -ForegroundColor White
    Write-Host ""
    Write-Host (L "menu_advanced") -ForegroundColor Cyan
    Write-Host "  13. $(L 'menu_uninstall_runner')" -ForegroundColor White
    Write-Host "  14. $(L 'menu_clear_config')" -ForegroundColor White
    Write-Host ""
    Write-Host (L "menu_infrastructure") -ForegroundColor Magenta
    Write-Host "  15. $(L 'menu_telegram_notifications')" -ForegroundColor White
    Write-Host "  16. $(L 'menu_docker_management')" -ForegroundColor White
    Write-Host ""
    Write-Host "  0. $(L 'menu_exit')" -ForegroundColor White
    Write-Host ""
}

function Show-TokenConfigurationHelp {
    param(
        [string]$Platform = "github"
    )
    
    Write-Host ""
    if ($Platform -eq "gitlab") {
        Write-Host (L "token_config_title" "GitLab") -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (L "token_config_help_github") -ForegroundColor Yellow
        Write-Host "  - $(L 'token_config_perm_api')" -ForegroundColor White
        Write-Host ""
        Write-Host (L "token_config_create_gitlab") -ForegroundColor Cyan
        Write-Host (L "token_config_create_gitlab_self") -ForegroundColor Cyan
    } else {
        Write-Host (L "token_config_title" "GitHub") -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (L "token_config_help_github") -ForegroundColor Yellow
        Write-Host "  - $(L 'token_config_perm_repo')" -ForegroundColor White
        Write-Host "  - $(L 'token_config_perm_workflow')" -ForegroundColor White
        Write-Host ""
        Write-Host (L "token_config_create_github") -ForegroundColor Cyan
    }
    Write-Host ""
}

function Show-TokenStorageOptions {
    Write-Host ""
    Write-Host (L "token_storage_question") -ForegroundColor Cyan
    Write-Host "  1. $(L 'token_storage_env')" -ForegroundColor White
    Write-Host "  2. $(L 'token_storage_file')" -ForegroundColor White
    Write-Host "  3. $(L 'token_storage_session')" -ForegroundColor White
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
    $repoDisplay = if ($Config.Repository) { $Config.Repository } else { L "menu_not_configured" }
    Write-Host "$(L 'menu_repository'): $repoDisplay" -ForegroundColor $(if ($Config.Repository) { "Green" } else { "Yellow" })
    Write-Host "$(L 'menu_token'): $(if ($Config.GitHubToken) { L 'menu_configured' } else { L 'menu_not_set' })" -ForegroundColor $(if ($Config.GitHubToken) { "Green" } else { "Yellow" })
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
        Write-Host "Auto-Start: $(L 'menu_enabled') ($($task.State))" -ForegroundColor Green
    } else {
        Write-Host "Auto-Start: $(L 'menu_disabled')" -ForegroundColor Yellow
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


function Show-PlatformSelection {
    Write-Host ""
    Write-Host (L "platform_selection_title") -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host (L "platform_select_prompt") -ForegroundColor Yellow
    Write-Host "  1. $(L 'platform_github')" -ForegroundColor White
    Write-Host "  2. $(L 'platform_gitlab')" -ForegroundColor White
    Write-Host ""
}

function Show-TargetTypeSelection {
    Write-Host ""
    Write-Host (L "target_type_title") -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host (L "target_type_prompt") -ForegroundColor Yellow
    Write-Host "  1. $(L 'target_type_project')" -ForegroundColor White
    Write-Host "  2. $(L 'target_type_group')" -ForegroundColor White
    Write-Host ""
}
