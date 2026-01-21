# User Interface Module

function Show-Banner {
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    Write-Host "  ║     " -NoNewline -ForegroundColor Cyan
    Write-Host "OCTOPUS RUNNER MANAGER" -NoNewline -ForegroundColor White
    Write-Host "                          ║" -ForegroundColor Cyan
    Write-Host "  ║   " -NoNewline -ForegroundColor Cyan
    Write-Host "Advanced CI/CD Infrastructure Suite" -NoNewline -ForegroundColor Gray
    Write-Host "                  ║" -ForegroundColor Cyan
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    Write-Host "  ║   " -NoNewline -ForegroundColor Cyan
    Write-Host "Powered by " -NoNewline -ForegroundColor DarkGray
    Write-Host "ibuildrun" -NoNewline -ForegroundColor Magenta
    Write-Host "                                    ║" -ForegroundColor Cyan
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
    
    Write-Host "  $platformName Platform: " -NoNewline -ForegroundColor Cyan
    Write-Host "$platformName" -ForegroundColor White
    
    if ($Config.Platform -eq "gitlab" -and $Config.InstanceUrl) {
        Write-Host "  Instance: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($Config.InstanceUrl)" -ForegroundColor White
    }
    
    if ($Config.Repository) {
        $targetLabel = if ($Config.Platform -eq "gitlab") { 
            if ($Config.TargetType -eq "group") { "Group" } else { "Project" }
        } else { "Repository" }
        Write-Host "  ${targetLabel}: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($Config.Repository)" -ForegroundColor Green
    } else {
        Write-Host "  Target: " -NoNewline -ForegroundColor Cyan
        Write-Host "Not configured" -ForegroundColor Yellow
    }
    
    $tokenStatus = if ($Config.GitHubToken) { "Configured" } else { "Not set" }
    $tokenColor = if ($Config.GitHubToken) { "Green" } else { "Yellow" }
    Write-Host "  Token: " -NoNewline -ForegroundColor Cyan
    Write-Host "$tokenStatus" -ForegroundColor $tokenColor
    
    # Show Telegram status
    $telegramConfig = $Config.GetTelegramConfig()
    if ($telegramConfig.Enabled) {
        Write-Host "  Telegram: " -NoNewline -ForegroundColor Cyan
        $userCount = $telegramConfig.ChatIds.Count
        Write-Host "Enabled ($userCount)" -ForegroundColor Green
    } else {
        Write-Host "  Telegram: " -NoNewline -ForegroundColor Cyan
        Write-Host "Disabled" -ForegroundColor Gray
    }
    
    # Show Docker runners count
    $dockerRunners = $Config.GetDockerRunners()
    if ($dockerRunners.Count -gt 0) {
        Write-Host "  Docker: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($dockerRunners.Count) container(s)" -ForegroundColor Green
    }
    
    # Show local runners count and active runner
    $localRunners = $Config.GetLocalRunners()
    if ($localRunners.Count -gt 0) {
        Write-Host "  Local Runners: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($localRunners.Count) configured" -ForegroundColor Green
        
        $activeRunner = $Config.GetActiveRunner()
        if ($activeRunner) {
            Write-Host "  Active Runner: " -NoNewline -ForegroundColor Cyan
            Write-Host "$($activeRunner.Name)" -ForegroundColor Yellow
            Write-Host "    Path: " -NoNewline -ForegroundColor Cyan
            Write-Host "$($activeRunner.Path)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Configuration" -ForegroundColor Cyan
    Write-Host "    1. Configure $platformName Token" -ForegroundColor White
    
    if ($Config.Platform -eq "gitlab") {
        Write-Host "    2. Select Project/Group" -ForegroundColor White
        Write-Host "    3. Configure Instance URL" -ForegroundColor White
    } else {
        Write-Host "    2. Select Repository" -ForegroundColor White
        Write-Host "    3. Configure GitHub Secrets (Auto)" -ForegroundColor Yellow
    }
    
    Write-Host "    4. Switch Platform (GitHub / GitLab)" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Runner Management" -ForegroundColor Cyan
    Write-Host "    5. Install Runner" -ForegroundColor White
    Write-Host "    6. Start Runner" -ForegroundColor White
    Write-Host "    7. Stop Runner" -ForegroundColor White
    Write-Host "    8. Check Status" -ForegroundColor White
    Write-Host "    9. View Logs" -ForegroundColor White
    if ($Config.Platform -eq "gitlab") {
        Write-Host "    10. View Active Runners" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  Auto-Start" -ForegroundColor Cyan
    Write-Host "    11. Enable Auto-Start (on boot)" -ForegroundColor White
    Write-Host "    12. Disable Auto-Start" -ForegroundColor White
    Write-Host ""
    Write-Host "  Advanced" -ForegroundColor Cyan
    Write-Host "    13. Uninstall Runner" -ForegroundColor White
    Write-Host "    14. Clear Configuration" -ForegroundColor White
    Write-Host ""
    Write-Host "  Infrastructure Suite" -ForegroundColor Magenta
    Write-Host "    15. Telegram Notifications" -ForegroundColor White
    Write-Host "    16. Docker Container Management" -ForegroundColor White
    Write-Host "    17. Multi-Runner Management" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    18. Help and Quick Start Guide" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    0. Exit" -ForegroundColor White
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


function Show-HelpGuide {
    Clear-Host
    Show-Banner
    
    Write-Host "  QUICK START GUIDE" -ForegroundColor Cyan
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  FIRST TIME SETUP" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    1. Configure Token (Option 1)" -ForegroundColor White
    Write-Host "       • Get token from: https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host "       • Required scopes: repo, workflow" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    2. Select Repository (Option 2)" -ForegroundColor White
    Write-Host "       • Search and select your repository" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    3. Install Runner (Option 5)" -ForegroundColor White
    Write-Host "       • Downloads and configures runner" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    4. Start Runner (Option 6)" -ForegroundColor White
    Write-Host "       • Starts the runner process" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  DOCKER RUNNERS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Option 16 → Docker Container Management" -ForegroundColor White
    Write-Host ""
    Write-Host "    • Option 1: Build runner image" -ForegroundColor Gray
    Write-Host "      Creates Docker image with Node.js, PHP, Composer" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • Option 2: Start new container" -ForegroundColor Gray
    Write-Host "      Launches isolated runner in Docker" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • Option 8: Rebuild and restart (recommended)" -ForegroundColor Green
    Write-Host "      Auto-updates to latest runner version" -ForegroundColor DarkGray
    Write-Host "      Cleans up old offline runners" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • Option 9: Quick restart" -ForegroundColor Gray
    Write-Host "      Fast restart without rebuild" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • Option 10: Health check" -ForegroundColor Gray
    Write-Host "      Diagnose runner issues" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    • Option 11: Cleanup offline runners" -ForegroundColor Gray
    Write-Host "      Remove dead runners from GitHub" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  TIPS AND TRICKS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    • Partial container search:" -ForegroundColor White
    Write-Host "      Type 'avyx' instead of full ID '0d81c0b7d764...'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • Auto-start on boot:" -ForegroundColor White
    Write-Host "      Use Option 11 to enable automatic runner start" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • Telegram notifications:" -ForegroundColor White
    Write-Host "      Option 15 to get alerts about runner events" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • Multiple runners:" -ForegroundColor White
    Write-Host "      Option 16 → 7 for bulk deployment" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  TROUBLESHOOTING" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Runner stuck or offline?" -ForegroundColor White
    Write-Host "      → Option 16 → 9 (Quick restart)" -ForegroundColor Green
    Write-Host ""
    Write-Host "    Jobs queuing but not running?" -ForegroundColor White
    Write-Host "      → Option 16 → 10 (Health check)" -ForegroundColor Green
    Write-Host "      → Option 16 → 8 (Rebuild with latest version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "    Old runners accumulating?" -ForegroundColor White
    Write-Host "      → Option 16 → 11 (Cleanup offline runners)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  DOCUMENTATION" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    GitHub: https://github.com/ibuildrun/runner-manager" -ForegroundColor Cyan
    Write-Host "    Issues: https://github.com/ibuildrun/runner-manager/issues" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Press Enter to return to main menu"
}
