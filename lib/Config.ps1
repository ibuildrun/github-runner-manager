# Configuration Management Module

# Load PlatformProvider if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'IPlatformProvider').Type) {
    . "$PSScriptRoot\PlatformProvider.ps1"
}

class RunnerConfig {
    [string]$GitHubToken
    [string]$Repository
    [string]$ConfigFile
    hidden [object]$FullConfig
    
    # New multi-platform fields
    [string]$Platform
    [string]$InstanceUrl
    [string]$TargetType
    [int]$ConfigVersion
    [string]$Language
    
    # Multi-runner support
    [string]$ActiveRunnerId
    
    RunnerConfig([string]$configPath) {
        $this.ConfigFile = $configPath
        $this.GitHubToken = $null
        $this.Repository = $null
        $this.FullConfig = $null
        $this.Platform = "github"  # Default platform
        $this.InstanceUrl = ""
        $this.TargetType = "project"
        $this.ConfigVersion = 2
        $this.Language = "en"  # Default language
        $this.ActiveRunnerId = $null
    }
    
    [void] Load() {
        # Try to load from file
        if (Test-Path $this.ConfigFile) {
            try {
                $content = Get-Content $this.ConfigFile -Raw -ErrorAction Stop
                if ([string]::IsNullOrWhiteSpace($content)) {
                    Write-Host "Warning: Configuration file is empty, using defaults" -ForegroundColor Yellow
                    return
                }
                
                $this.FullConfig = $content | ConvertFrom-Json -ErrorAction Stop
                
                # Validate config structure
                if ($null -eq $this.FullConfig) {
                    Write-Host "Warning: Invalid configuration, using defaults" -ForegroundColor Yellow
                    return
                }
                
                # Check if migration is needed (v1 to v2)
                if (-not $this.FullConfig.ConfigVersion -or $this.FullConfig.ConfigVersion -eq 1) {
                    Write-Host "Migrating configuration from v1 to v2..." -ForegroundColor Yellow
                    $this.FullConfig = [RunnerConfig]::MigrateFromV1($this.FullConfig)
                    # Save migrated config
                    $this.FullConfig | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
                    Write-Host "Configuration migrated successfully" -ForegroundColor Green
                }
                
                # Load platform-specific fields with null checks
                $this.Platform = if ($this.FullConfig.Platform) { $this.FullConfig.Platform } else { "github" }
                $this.InstanceUrl = if ($this.FullConfig.InstanceUrl) { $this.FullConfig.InstanceUrl } else { "" }
                $this.TargetType = if ($this.FullConfig.TargetType) { $this.FullConfig.TargetType } else { "project" }
                $this.ConfigVersion = if ($this.FullConfig.ConfigVersion) { $this.FullConfig.ConfigVersion } else { 2 }
                $this.Language = if ($this.FullConfig.Language) { $this.FullConfig.Language } else { "en" }
                $this.ActiveRunnerId = if ($this.FullConfig.ActiveRunnerId) { $this.FullConfig.ActiveRunnerId } else { $null }
                
                $this.Repository = $this.FullConfig.Repository
                
                if ($this.FullConfig.TokenStorage -eq "Environment") {
                    if ($this.Platform -eq "github") {
                        $this.GitHubToken = [System.Environment]::GetEnvironmentVariable("GITHUB_RUNNER_TOKEN", "User")
                    } elseif ($this.Platform -eq "gitlab") {
                        $this.GitHubToken = [System.Environment]::GetEnvironmentVariable("GITLAB_RUNNER_TOKEN", "User")
                    }
                } elseif ($this.FullConfig.TokenStorage -eq "File" -and $this.FullConfig.TokenEncrypted) {
                    try {
                        $this.GitHubToken = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($this.FullConfig.TokenEncrypted))
                    } catch {
                        Write-Host "Warning: Could not decode token from file" -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host "Warning: Could not load configuration: $_" -ForegroundColor Yellow
                Write-Host "Using default settings" -ForegroundColor Yellow
            }
        }
        
        # Fallback to environment variable
        if (-not $this.GitHubToken) {
            $this.GitHubToken = $env:GITHUB_TOKEN
            if (-not $this.GitHubToken) {
                $this.GitHubToken = $env:GITLAB_TOKEN
            }
        }
        
        # Auto-migrate existing runner installation
        $this.MigrateExistingRunner()
    }
    
    # Auto-migrate existing runner from C:\actions-runner
    [void] MigrateExistingRunner() {
        $defaultPath = "C:\actions-runner"
        
        # Check if we already have local runners configured
        $existingRunners = $this.GetLocalRunners()
        if ($existingRunners.Count -gt 0) {
            return  # Already migrated
        }
        
        # Check if runner exists at default path
        if (-not (Test-Path "$defaultPath\run.cmd")) {
            return  # No runner to migrate
        }
        
        # Check if we have repository configured
        if ([string]::IsNullOrEmpty($this.Repository)) {
            return  # Can't migrate without repository info
        }
        
        # Create runner entry for existing installation
        $runnerId = "migrated-" + [guid]::NewGuid().ToString().Substring(0, 8)
        $runner = @{
            Id = $runnerId
            Name = "Default Runner (Migrated)"
            Path = $defaultPath
            Repository = $this.Repository
            Platform = $this.Platform
            Created = (Get-Date).ToString("o")
            Status = "Installed"
        }
        
        # Add to config
        if (-not $this.FullConfig) {
            $this.FullConfig = @{
                Platform = $this.Platform
                Repository = $this.Repository
                LocalRunners = @()
            }
        }
        
        if (-not $this.FullConfig.LocalRunners) {
            $this.FullConfig | Add-Member -NotePropertyName "LocalRunners" -NotePropertyValue @() -Force
        }
        
        $this.FullConfig.LocalRunners += $runner
        $this.ActiveRunnerId = $runnerId
        
        # Save config
        $this.FullConfig | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
        
        Write-Host ""
        Write-Host "✓ Existing runner migrated to multi-runner system" -ForegroundColor Green
        Write-Host "  Path: $defaultPath" -ForegroundColor Gray
        Write-Host "  Name: Default Runner (Migrated)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Migration method from v1 to v2
    static [object] MigrateFromV1([object]$oldConfig) {
        $newConfig = @{
            Platform = "github"  # Default to GitHub for existing configs
            InstanceUrl = ""
            TargetType = "project"
            ConfigVersion = 2
            Repository = $oldConfig.Repository
            TokenStorage = $oldConfig.TokenStorage
            LastUpdated = (Get-Date).ToString("o")
        }
        
        # Preserve token if stored in file
        if ($oldConfig.TokenEncrypted) {
            $newConfig.TokenEncrypted = $oldConfig.TokenEncrypted
        }
        
        # Preserve Telegram config
        if ($oldConfig.Telegram) {
            $newConfig.Telegram = $oldConfig.Telegram
        }
        
        # Preserve Docker runners
        if ($oldConfig.DockerRunners) {
            $newConfig.DockerRunners = $oldConfig.DockerRunners
        }
        
        return $newConfig | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    }
    
    [void] Save([string]$tokenStorage) {
        $config = @{
            Platform = $this.Platform
            InstanceUrl = $this.InstanceUrl
            TargetType = $this.TargetType
            ConfigVersion = 2
            Language = $this.Language
            Repository = $this.Repository
            TokenStorage = $tokenStorage
            LastUpdated = (Get-Date).ToString("o")
            ActiveRunnerId = $this.ActiveRunnerId
        }
        
        # Preserve existing sections
        if ($this.FullConfig) {
            if ($this.FullConfig.Telegram) {
                $config.Telegram = $this.FullConfig.Telegram
            }
            if ($this.FullConfig.DockerRunners) {
                $config.DockerRunners = $this.FullConfig.DockerRunners
            }
            if ($this.FullConfig.LocalRunners) {
                $config.LocalRunners = $this.FullConfig.LocalRunners
            }
        }
        
        if ($tokenStorage -eq "File" -and $this.GitHubToken) {
            $config.TokenEncrypted = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.GitHubToken))
        }
        
        $config | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
        $this.FullConfig = $config | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        Write-Host "Configuration saved" -ForegroundColor Green
    }
    
    # Get platform provider instance
    [object] GetProvider() {
        try {
            # Load GitHubProvider if needed
            if ($this.Platform -eq "github" -and -not ([System.Management.Automation.PSTypeName]'GitHubProvider').Type) {
                . "$PSScriptRoot\GitHubProvider.ps1"
            }
            # Load GitLabProvider if needed (will be implemented in task 5.1)
            if ($this.Platform -eq "gitlab" -and -not ([System.Management.Automation.PSTypeName]'GitLabProvider').Type) {
                . "$PSScriptRoot\GitLabProvider.ps1"
            }
            
            return [PlatformFactory]::GetProvider($this.Platform)
        } catch {
            Write-Host "Error loading platform provider: $_" -ForegroundColor Red
            return $null
        }
    }
    
    # Get platform display name
    [string] GetPlatformDisplayName() {
        try {
            return [PlatformFactory]::GetPlatformDisplayName($this.Platform)
        } catch {
            return $this.Platform
        }
    }
    
    [object] GetTelegramConfig() {
        if (-not $this.FullConfig -or -not $this.FullConfig.Telegram) {
            return @{
                BotToken = $null
                ChatIds = @()
                Enabled = $false
            }
        }
        
        return @{
            BotToken = $this.FullConfig.Telegram.BotToken
            ChatIds = $this.FullConfig.Telegram.ChatIds
            Enabled = $this.FullConfig.Telegram.Enabled
        }
    }
    
    [void] SaveTelegramConfig([hashtable]$telegramConfig) {
        if (-not $this.FullConfig) {
            $this.Load()
        }
        
        $config = @{
            Platform = $this.Platform
            InstanceUrl = $this.InstanceUrl
            TargetType = $this.TargetType
            ConfigVersion = 2
            Language = $this.Language
            Repository = $this.Repository
            TokenStorage = if ($this.FullConfig.TokenStorage) { $this.FullConfig.TokenStorage } else { "Environment" }
            LastUpdated = (Get-Date).ToString("o")
            Telegram = @{
                BotToken = $telegramConfig.BotToken
                ChatIds = $telegramConfig.ChatIds
                Enabled = $telegramConfig.Enabled
            }
        }
        
        if ($this.FullConfig.TokenEncrypted) {
            $config.TokenEncrypted = $this.FullConfig.TokenEncrypted
        }
        
        if ($this.FullConfig.DockerRunners) {
            $config.DockerRunners = $this.FullConfig.DockerRunners
        }
        
        $config | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
        $this.FullConfig = $config | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    }
    
    [void] AddDockerRunner([object]$dockerRunner) {
        if (-not $this.FullConfig) {
            $this.Load()
        }
        
        if (-not $this.FullConfig.DockerRunners) {
            $this.FullConfig | Add-Member -NotePropertyName "DockerRunners" -NotePropertyValue @() -Force
        }
        
        $runnerData = @{
            ContainerId = $dockerRunner.ContainerId
            Repository = $dockerRunner.Repository
            RunnerName = $dockerRunner.RunnerName
            ImageTag = $dockerRunner.ImageTag
            Created = $dockerRunner.Created.ToString("o")
            Status = $dockerRunner.Status
        }
        
        $this.FullConfig.DockerRunners += $runnerData
        $this.FullConfig | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
    }
    
    [array] GetDockerRunners() {
        if (-not $this.FullConfig -or -not $this.FullConfig.DockerRunners) {
            return @()
        }
        return $this.FullConfig.DockerRunners
    }
    
    [void] AddLocalRunner([hashtable]$runner) {
        if (-not $this.FullConfig) {
            $this.Load()
        }
        
        if (-not $this.FullConfig.LocalRunners) {
            $this.FullConfig | Add-Member -NotePropertyName "LocalRunners" -NotePropertyValue @() -Force
        }
        
        $this.FullConfig.LocalRunners += $runner
        $this.FullConfig | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
    }
    
    [array] GetLocalRunners() {
        if (-not $this.FullConfig -or -not $this.FullConfig.LocalRunners) {
            return @()
        }
        return $this.FullConfig.LocalRunners
    }
    
    [object] GetActiveRunner() {
        $runners = $this.GetLocalRunners()
        if ($runners.Count -eq 0) {
            return $null
        }
        
        if ($this.ActiveRunnerId) {
            $runner = $runners | Where-Object { $_.Id -eq $this.ActiveRunnerId }
            if ($runner) {
                return $runner
            }
        }
        
        # Return first runner if no active runner set
        return $runners[0]
    }
    
    [void] SetActiveRunner([string]$runnerId) {
        $this.ActiveRunnerId = $runnerId
        $this.Save($this.FullConfig.TokenStorage)
    }
    
    [void] RemoveLocalRunner([string]$runnerId) {
        if (-not $this.FullConfig -or -not $this.FullConfig.LocalRunners) {
            return
        }
        
        $this.FullConfig.LocalRunners = @($this.FullConfig.LocalRunners | Where-Object { $_.Id -ne $runnerId })
        
        if ($this.ActiveRunnerId -eq $runnerId) {
            $this.ActiveRunnerId = $null
        }
        
        $this.FullConfig | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigFile -Force
    }
    
    [void] Clear() {
        if (Test-Path $this.ConfigFile) {
            Remove-Item $this.ConfigFile -Force
        }
        
        $this.Repository = $null
        $this.GitHubToken = $env:GITHUB_TOKEN
        $this.FullConfig = $null
        
        Write-Host "Configuration cleared" -ForegroundColor Green
    }
    
    [bool] IsValid() {
        return (-not [string]::IsNullOrEmpty($this.GitHubToken)) -and (-not [string]::IsNullOrEmpty($this.Repository))
    }
}

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Host "Error: This operation requires Administrator privileges" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return $false
    }
    return $true
}
