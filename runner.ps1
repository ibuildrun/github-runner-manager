#!/usr/bin/env pwsh
# GitHub Actions Self-Hosted Runner Manager
# Universal script for managing self-hosted runners for any repository

param(
    [string]$RunnerPath = "C:\actions-runner"
)

$ErrorActionPreference = "Stop"

# Import modules
. "$PSScriptRoot\lib\Config.ps1"
. "$PSScriptRoot\lib\GitHub.ps1"
. "$PSScriptRoot\lib\UI.ps1"
. "$PSScriptRoot\lib\TokenManager.ps1"
. "$PSScriptRoot\lib\RepositorySelector.ps1"
. "$PSScriptRoot\lib\RunnerInstaller.ps1"
. "$PSScriptRoot\lib\RunnerManager.ps1"
. "$PSScriptRoot\lib\AutoStart.ps1"

# Initialize configuration
$configPath = "$PSScriptRoot\.runner-config.json"
$config = [RunnerConfig]::new($configPath)
$config.Load()

# Main menu loop
do {
    Show-MainMenu -Config $config
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" { 
            Invoke-TokenConfiguration -Config $config
        }
        "2" { 
            Invoke-RepositorySelection -Config $config
        }
        "3" { 
            Install-GitHubRunner -Config $config -RunnerPath $RunnerPath
        }
        "4" { 
            Start-GitHubRunner -Config $config -RunnerPath $RunnerPath
        }
        "5" { 
            Stop-GitHubRunner -Config $config -RunnerPath $RunnerPath
        }
        "6" { 
            Show-Status -Config $config -RunnerPath $RunnerPath
        }
        "7" { 
            Show-RunnerLogs -RunnerPath $RunnerPath
        }
        "8" { 
            Enable-RunnerAutoStart -Config $config -RunnerPath $RunnerPath
        }
        "9" { 
            Disable-RunnerAutoStart -Config $config
        }
        "10" { 
            Uninstall-GitHubRunner -Config $config -RunnerPath $RunnerPath
        }
        "11" { 
            $config.Clear()
        }
        "0" { 
            break 
        }
        default { 
            Write-Host "Invalid option" -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
} while ($choice -ne "0")

Write-Host ""
Write-Host "Goodbye!" -ForegroundColor Cyan
