# User Interface Module

function Show-Banner {
    $title = L "banner_title"
    $subtitle = L "banner_subtitle"
    $powered = L "banner_powered"
    
    # Calculate padding for centering
    $boxWidth = 59
    $titlePadding = [Math]::Max(0, [Math]::Floor(($boxWidth - $title.Length) / 2))
    $titlePaddingRight = [Math]::Max(0, $boxWidth - $title.Length - $titlePadding)
    
    $subtitlePadding = [Math]::Max(0, [Math]::Floor(($boxWidth - $subtitle.Length) / 2))
    $subtitlePaddingRight = [Math]::Max(0, $boxWidth - $subtitle.Length - $subtitlePadding)
    
    $poweredText = "$powered ibuildrun"
    $poweredPadding = [Math]::Max(0, [Math]::Floor(($boxWidth - $poweredText.Length) / 2))
    $poweredPaddingRight = [Math]::Max(0, $boxWidth - $poweredText.Length - $poweredPadding)
    
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    
    # Title line
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $titlePadding) -NoNewline
    Write-Host $title -NoNewline -ForegroundColor White
    Write-Host (" " * $titlePaddingRight) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    # Subtitle line
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $subtitlePadding) -NoNewline
    Write-Host $subtitle -NoNewline -ForegroundColor Gray
    Write-Host (" " * $subtitlePaddingRight) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    
    # Powered by line
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $poweredPadding) -NoNewline
    Write-Host $powered -NoNewline -ForegroundColor DarkGray
    Write-Host " " -NoNewline
    Write-Host "ibuildrun" -NoNewline -ForegroundColor Magenta
    Write-Host (" " * $poweredPaddingRight) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Clear-Host
    Show-Banner
    
    # Get platform display name and emoji
    $platformName = $Config.GetPlatformDisplayName()
    $platformEmoji = if ($Config.Platform -eq "gitlab") { "🦊" } else { "🐙" }
    
    Write-Host "  $platformName $(L 'status_platform'): " -NoNewline -ForegroundColor Cyan
    Write-Host "$platformName" -ForegroundColor White
    
    if ($Config.Platform -eq "gitlab" -and $Config.InstanceUrl) {
        Write-Host "  $(L 'status_instance'): " -NoNewline -ForegroundColor Cyan
        Write-Host "$($Config.InstanceUrl)" -ForegroundColor White
    }
    
    if ($Config.Repository) {
        $targetLabel = if ($Config.Platform -eq "gitlab") { 
            if ($Config.TargetType -eq "group") { L "menu_group" } else { L "menu_project" }
        } else { L "status_repository" }
        Write-Host "  ${targetLabel}: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($Config.Repository)" -ForegroundColor Green
    } else {
        Write-Host "  $(L 'menu_target'): " -NoNewline -ForegroundColor Cyan
        Write-Host (L "status_not_configured") -ForegroundColor Yellow
    }
    
    $tokenStatus = if ($Config.GitHubToken) { L "status_configured" } else { L "menu_not_set" }
    $tokenColor = if ($Config.GitHubToken) { "Green" } else { "Yellow" }
    Write-Host "  $(L 'status_token'): " -NoNewline -ForegroundColor Cyan
    Write-Host "$tokenStatus" -ForegroundColor $tokenColor
    
    # Show Telegram status
    $telegramConfig = $Config.GetTelegramConfig()
    if ($telegramConfig.Enabled) {
        Write-Host "  $(L 'status_telegram'): " -NoNewline -ForegroundColor Cyan
        $userCount = $telegramConfig.ChatIds.Count
        Write-Host "$(L 'status_enabled') ($userCount)" -ForegroundColor Green
    } else {
        Write-Host "  $(L 'status_telegram'): " -NoNewline -ForegroundColor Cyan
        Write-Host (L "status_disabled") -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Show Docker runners count (real running containers with "runner" in name)
    try {
        $allContainers = docker ps --format "{{.Names}}" 2>$null
        if ($LASTEXITCODE -eq 0 -and $allContainers) {
            $runnerContainers = $allContainers | Where-Object { $_ -match "runner" }
            $containerCount = ($runnerContainers | Measure-Object).Count
            if ($containerCount -gt 0) {
                Write-Host "  $(L 'status_docker') Runners (Containers): " -NoNewline -ForegroundColor Magenta
                Write-Host "$containerCount $(L 'status_running')" -ForegroundColor Green
            }
        }
    } catch {
        # Docker not available, skip
    }
    
    # Show local runners count and active runner
    $localRunners = $Config.GetLocalRunners()
    if ($localRunners.Count -gt 0) {
        Write-Host "  $(L 'status_local_runners') (Windows): " -NoNewline -ForegroundColor Cyan
        Write-Host "$($localRunners.Count) $(L 'status_runners_configured')" -ForegroundColor Green
        
        $activeRunner = $Config.GetActiveRunner()
        if ($activeRunner) {
            Write-Host "    └─ $(L 'status_active_runner'): " -NoNewline -ForegroundColor Cyan
            Write-Host "$($activeRunner.Name)" -ForegroundColor Yellow
            Write-Host "       $(L 'status_path'): " -NoNewline -ForegroundColor Cyan
            Write-Host "$($activeRunner.Path)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  $(L 'menu_configuration')" -ForegroundColor Cyan
    Write-Host "    1. $(L 'menu_configure_token' $platformName)" -ForegroundColor White
    
    if ($Config.Platform -eq "gitlab") {
        Write-Host "    2. $(L 'menu_select_project_group')" -ForegroundColor White
        Write-Host "    3. $(L 'menu_configure_instance')" -ForegroundColor White
    } else {
        Write-Host "    2. $(L 'menu_select_repository')" -ForegroundColor White
        Write-Host "    3. $(L 'menu_configure_secrets')" -ForegroundColor Yellow
    }
    
    Write-Host "    4. $(L 'menu_switch_platform')" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  $(L 'menu_runner_management')" -ForegroundColor Cyan
    Write-Host "    5. $(L 'menu_install_runner')" -ForegroundColor White
    Write-Host "    6. $(L 'menu_start_runner')" -ForegroundColor White
    Write-Host "    7. $(L 'menu_stop_runner')" -ForegroundColor White
    Write-Host "    8. $(L 'menu_check_status')" -ForegroundColor White
    Write-Host "    9. $(L 'menu_view_logs')" -ForegroundColor White
    if ($Config.Platform -eq "gitlab") {
        Write-Host "    10. $(L 'menu_view_active_runners')" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  $(L 'menu_autostart')" -ForegroundColor Cyan
    Write-Host "    11. $(L 'menu_enable_autostart')" -ForegroundColor White
    Write-Host "    12. $(L 'menu_disable_autostart')" -ForegroundColor White
    Write-Host ""
    Write-Host "  $(L 'menu_advanced')" -ForegroundColor Cyan
    Write-Host "    13. $(L 'menu_uninstall_runner')" -ForegroundColor White
    Write-Host "    14. $(L 'menu_clear_config')" -ForegroundColor White
    Write-Host ""
    Write-Host "  $(L 'menu_infrastructure')" -ForegroundColor Magenta
    Write-Host "    15. $(L 'menu_telegram')" -ForegroundColor White
    Write-Host "    16. $(L 'menu_docker')" -ForegroundColor White
    Write-Host "    17. $(L 'menu_multirunner')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    18. $(L 'menu_help')" -ForegroundColor Yellow
    Write-Host "    19. $(L 'menu_language')" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    0. $(L 'menu_exit')" -ForegroundColor White
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
    $repoDisplay = if ($Config.Repository) { $Config.Repository } else { "Not configured" }
    Write-Host "Repository: $repoDisplay" -ForegroundColor $(if ($Config.Repository) { "Green" } else { "Yellow" })
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


function Show-HelpGuide {
    Clear-Host
    Show-Banner
    
    Write-Host "  $(L 'help_title')" -ForegroundColor Cyan
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  $(L 'help_first_setup')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    1. $(L 'help_step1')" -ForegroundColor White
    Write-Host "       • $(L 'help_step1_detail1')" -ForegroundColor Gray
    Write-Host "       • $(L 'help_step1_detail2')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    2. $(L 'help_step2')" -ForegroundColor White
    Write-Host "       • $(L 'help_step2_detail')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    3. $(L 'help_step3')" -ForegroundColor White
    Write-Host "       • $(L 'help_step3_detail')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    4. $(L 'help_step4')" -ForegroundColor White
    Write-Host "       • $(L 'help_step4_detail')" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  $(L 'help_docker')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    $(L 'help_docker_menu')" -ForegroundColor White
    Write-Host ""
    Write-Host "    • $(L 'help_docker_build')" -ForegroundColor Gray
    Write-Host "      $(L 'help_docker_build_detail')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • $(L 'help_docker_start')" -ForegroundColor Gray
    Write-Host "      $(L 'help_docker_start_detail')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • $(L 'help_docker_rebuild')" -ForegroundColor Green
    Write-Host "      $(L 'help_docker_rebuild_detail1')" -ForegroundColor DarkGray
    Write-Host "      $(L 'help_docker_rebuild_detail2')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • $(L 'help_docker_restart')" -ForegroundColor Gray
    Write-Host "      $(L 'help_docker_restart_detail')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • $(L 'help_docker_health')" -ForegroundColor Gray
    Write-Host "      $(L 'help_docker_health_detail')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • $(L 'help_docker_cleanup')" -ForegroundColor Gray
    Write-Host "      $(L 'help_docker_cleanup_detail')" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  $(L 'help_tips')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    • $(L 'help_tip_search')" -ForegroundColor White
    Write-Host "      $(L 'help_tip_search_detail')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • $(L 'help_tip_autostart')" -ForegroundColor White
    Write-Host "      $(L 'help_tip_autostart_detail')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • $(L 'help_tip_telegram')" -ForegroundColor White
    Write-Host "      $(L 'help_tip_telegram_detail')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • $(L 'help_tip_multiple')" -ForegroundColor White
    Write-Host "      $(L 'help_tip_multiple_detail')" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  $(L 'help_troubleshooting')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    $(L 'help_trouble_stuck')" -ForegroundColor White
    Write-Host "      $(L 'help_trouble_stuck_fix')" -ForegroundColor Green
    Write-Host ""
    Write-Host "    $(L 'help_trouble_queuing')" -ForegroundColor White
    Write-Host "      $(L 'help_trouble_queuing_fix1')" -ForegroundColor Green
    Write-Host "      $(L 'help_trouble_queuing_fix2')" -ForegroundColor Green
    Write-Host ""
    Write-Host "    $(L 'help_trouble_accumulating')" -ForegroundColor White
    Write-Host "      $(L 'help_trouble_accumulating_fix')" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  $(L 'help_documentation')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    GitHub: https://github.com/ibuildrun/runner-manager" -ForegroundColor Cyan
    Write-Host "    Issues: https://github.com/ibuildrun/runner-manager/issues" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  $(L 'help_press_enter')"
}
