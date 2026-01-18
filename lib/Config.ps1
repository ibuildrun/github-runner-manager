# Configuration Management Module

class RunnerConfig {
    [string]$GitHubToken
    [string]$Repository
    [string]$ConfigFile
    
    RunnerConfig([string]$configPath) {
        $this.ConfigFile = $configPath
        $this.GitHubToken = $null
        $this.Repository = $null
    }
    
    [void] Load() {
        # Try to load from file
        if (Test-Path $this.ConfigFile) {
            try {
                $saved = Get-Content $this.ConfigFile -Raw | ConvertFrom-Json
                $this.Repository = $saved.Repository
                
                if ($saved.TokenStorage -eq "Environment") {
                    $this.GitHubToken = [System.Environment]::GetEnvironmentVariable("GITHUB_RUNNER_TOKEN", "User")
                } elseif ($saved.TokenStorage -eq "File" -and $saved.TokenEncrypted) {
                    $this.GitHubToken = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($saved.TokenEncrypted))
                }
            } catch {
                Write-Host "Warning: Could not load configuration" -ForegroundColor Yellow
            }
        }
        
        # Fallback to environment variable
        if (-not $this.GitHubToken) {
            $this.GitHubToken = $env:GITHUB_TOKEN
        }
    }
    
    [void] Save([string]$tokenStorage) {
        $config = @{
            Repository = $this.Repository
            TokenStorage = $tokenStorage
            LastUpdated = (Get-Date).ToString("o")
        }
        
        if ($tokenStorage -eq "File" -and $this.GitHubToken) {
            $config.TokenEncrypted = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.GitHubToken))
        }
        
        $config | ConvertTo-Json | Set-Content $this.ConfigFile -Force
        Write-Host "Configuration saved" -ForegroundColor Green
    }
    
    [void] Clear() {
        if (Test-Path $this.ConfigFile) {
            Remove-Item $this.ConfigFile -Force
        }
        
        $this.Repository = $null
        $this.GitHubToken = $env:GITHUB_TOKEN
        
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

Export-ModuleMember -Function Test-AdminPrivileges
