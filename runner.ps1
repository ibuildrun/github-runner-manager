#!/usr/bin/env pwsh
# GitHub Actions Infrastructure Suite
# Advanced management system for self-hosted runners with Docker and Telegram integration

param(
    [string]$RunnerPath = "C:\actions-runner"
)

$ErrorActionPreference = "Stop"

# Import localization module first
. "$PSScriptRoot\lib\Localization.ps1"

# Import modules in correct order (dependencies first)
. "$PSScriptRoot\lib\PlatformProvider.ps1"
. "$PSScriptRoot\lib\GitHubProvider.ps1"
. "$PSScriptRoot\lib\GitLabProvider.ps1"
. "$PSScriptRoot\lib\TelegramNotifier.ps1"
. "$PSScriptRoot\lib\Config.ps1"
. "$PSScriptRoot\lib\GitHub.ps1"
. "$PSScriptRoot\lib\UI.ps1"
. "$PSScriptRoot\lib\TokenManager.ps1"
. "$PSScriptRoot\lib\RepositorySelector.ps1"
. "$PSScriptRoot\lib\SecretsManager.ps1"
. "$PSScriptRoot\lib\RunnerInstaller.ps1"
. "$PSScriptRoot\lib\RunnerManager.ps1"
. "$PSScriptRoot\lib\AutoStart.ps1"
. "$PSScriptRoot\lib\DockerManager.ps1"
. "$PSScriptRoot\lib\GitLabRunnerInstaller.ps1"
. "$PSScriptRoot\lib\GitLabRunnerManager.ps1"
. "$PSScriptRoot\lib\MultiRunnerManager.ps1"

# Initialize configuration
$configPath = "$PSScriptRoot\.runner-config.json"
$config = [RunnerConfig]::new($configPath)
$config.Load()

# Set language from config
if ($config.Language) {
    Set-Language -Language $config.Language
} else {
    # Auto-detect system language
    $systemLang = (Get-Culture).TwoLetterISOLanguageName
    if ($systemLang -eq "ru") {
        Set-Language -Language "ru"
        $config.Language = "ru"
        $config.Save("None")
    } else {
        Set-Language -Language "en"
    }
}

# Helper function to safely get effective runner path
function Get-EffectiveRunnerPath {
    param($Config, $DefaultPath)
    try {
        $activeRunner = $Config.GetActiveRunner()
        if ($activeRunner -and $activeRunner.Path) {
            return $activeRunner.Path
        }
    } catch {
        # Ignore errors, use default
    }
    return $DefaultPath
}

# Determine runner path: use active runner if available, otherwise use parameter
$effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath

# Main menu loop
do {
    Show-MainMenu -Config $config
    $choice = Read-Host (L "menu_select_option")
    
    switch ($choice) {
        "1" { 
            Invoke-TokenConfiguration -Config $config
        }
        "2" { 
            Invoke-RepositorySelection -Config $config
        }
        "3" { 
            if ($config.Platform -eq "gitlab") {
                # Configure GitLab Instance URL
                Write-Host ""
                Write-Host "GitLab Instance URL Configuration" -ForegroundColor Cyan
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Current URL: $($config.InstanceUrl)" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Enter GitLab instance URL (leave empty for gitlab.com):" -ForegroundColor Cyan
                $url = Read-Host "URL"
                
                if ([string]::IsNullOrEmpty($url)) {
                    $config.InstanceUrl = "https://gitlab.com"
                } else {
                    $config.InstanceUrl = $url
                }
                
                $config.Save("None")
                Write-Host "Instance URL updated" -ForegroundColor Green
            } else {
                Invoke-SecretsConfiguration -Config $config
            }
        }
        "4" { 
            # Switch Platform
            Write-Host ""
            Show-PlatformSelection
            $platformChoice = Read-Host "Select platform (1-2)"
            
            if ($platformChoice -eq "1") {
                $config.Platform = "github"
                $config.InstanceUrl = ""
                Write-Host "Switched to GitHub" -ForegroundColor Green
            } elseif ($platformChoice -eq "2") {
                $config.Platform = "gitlab"
                if ([string]::IsNullOrEmpty($config.InstanceUrl)) {
                    $config.InstanceUrl = "https://gitlab.com"
                }
                Write-Host "Switched to GitLab" -ForegroundColor Green
            } else {
                Write-Host "Invalid selection" -ForegroundColor Red
            }
            
            $config.Save("None")
        }
        "5" { 
            if ($config.Platform -eq "gitlab") {
                Install-GitLabRunner -Config $config -RunnerPath "C:\gitlab-runner"
            } else {
                $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
                Install-GitHubRunner -Config $config -RunnerPath $effectiveRunnerPath
            }
        }
        "6" { 
            if ($config.Platform -eq "gitlab") {
                Start-GitLabRunner -RunnerPath "C:\gitlab-runner"
            } else {
                $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
                Start-GitHubRunner -Config $config -RunnerPath $effectiveRunnerPath
            }
            
            # Send Telegram notification
            $telegramConfig = $config.GetTelegramConfig()
            if ($telegramConfig.Enabled) {
                $platformName = $config.GetPlatformDisplayName()
                $message = "Runner Started`n`nPlatform: $platformName`nTarget: $($config.Repository)"
                Send-TelegramNotification -TelegramConfig (ConvertTo-TelegramConfigObject $telegramConfig) -Message $message -Type "Success"
            }
        }
        "7" { 
            if ($config.Platform -eq "gitlab") {
                Stop-GitLabRunner
            } else {
                $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
                Stop-GitHubRunner -Config $config -RunnerPath $effectiveRunnerPath
            }
            
            # Send Telegram notification
            $telegramConfig = $config.GetTelegramConfig()
            if ($telegramConfig.Enabled) {
                $platformName = $config.GetPlatformDisplayName()
                $message = "Runner Stopped`n`nPlatform: $platformName`nTarget: $($config.Repository)"
                Send-TelegramNotification -TelegramConfig (ConvertTo-TelegramConfigObject $telegramConfig) -Message $message -Type "Warning"
            }
        }
        "8" { 
            if ($config.Platform -eq "gitlab") {
                Get-GitLabRunnerStatus -RunnerPath "C:\gitlab-runner"
            } else {
                $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
                Show-Status -Config $config -RunnerPath $effectiveRunnerPath
            }
        }
        "9" { 
            if ($config.Platform -eq "gitlab") {
                Show-GitLabRunnerLogs -RunnerPath "C:\gitlab-runner"
            } else {
                $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
                Show-RunnerLogs -RunnerPath $effectiveRunnerPath
            }
        }
        "10" {
            if ($config.Platform -eq "gitlab") {
                # View Active Runners for GitLab
                Write-Host ""
                Write-Host "Active GitLab Runners" -ForegroundColor Cyan
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "This feature will be implemented soon" -ForegroundColor Yellow
                Write-Host "You can view runners in GitLab UI:" -ForegroundColor Cyan
                if ($config.TargetType -eq "group") {
                    Write-Host "$($config.InstanceUrl)/$($config.Repository)/-/runners" -ForegroundColor White
                } else {
                    Write-Host "$($config.InstanceUrl)/$($config.Repository)/-/settings/ci_cd#js-runners-settings" -ForegroundColor White
                }
            } else {
                Enable-RunnerAutoStart -Config $config -RunnerPath $RunnerPath
            }
        }
        "11" { 
            $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
            Enable-RunnerAutoStart -Config $config -RunnerPath $effectiveRunnerPath
        }
        "12" { 
            Disable-RunnerAutoStart -Config $config
        }
        "13" { 
            if ($config.Platform -eq "gitlab") {
                Uninstall-GitLabRunner -RunnerPath "C:\gitlab-runner"
            } else {
                $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
                Uninstall-GitHubRunner -Config $config -RunnerPath $effectiveRunnerPath
            }
        }
        "14" { 
            $config.Clear()
        }
        "15" {
            Invoke-TelegramConfiguration -Config $config
        }
        "16" {
            Invoke-DockerManagement -Config $config
        }
        "17" {
            Invoke-MultiRunnerMenu -Config $config
            $effectiveRunnerPath = Get-EffectiveRunnerPath -Config $config -DefaultPath $RunnerPath
        }
        "18" {
            Show-HelpGuide
        }
        "19" {
            # Language Selection
            Write-Host ""
            Write-Host "=== Language / Язык ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "1. English" -ForegroundColor White
            Write-Host "2. Русский" -ForegroundColor White
            Write-Host ""
            $langChoice = Read-Host "Select language / Выберите язык"
            
            if ($langChoice -eq "1") {
                Set-Language -Language "en"
                $config.Language = "en"
                $config.Save("None")
                Write-Host "Language changed to English" -ForegroundColor Green
            } elseif ($langChoice -eq "2") {
                Set-Language -Language "ru"
                $config.Language = "ru"
                $config.Save("None")
                Write-Host "Язык изменен на Русский" -ForegroundColor Green
            } else {
                Write-Host "Invalid selection / Неверный выбор" -ForegroundColor Red
            }
        }
        "0" { 
            break 
        }
        default { 
            Write-Host "Invalid option. Please try again." -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
} while ($choice -ne "0")

Write-Host ""
Write-Host "Thank you for using Octopus Runner Manager!" -ForegroundColor Cyan
Write-Host "Powered by ibuildrun" -ForegroundColor Magenta
Write-Host ""
