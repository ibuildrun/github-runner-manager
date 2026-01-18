# GitHub API Integration Module
# This module provides backward-compatible wrapper functions around GitHubProvider

# Load GitHubProvider if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'GitHubProvider').Type) {
    . "$PSScriptRoot\GitHubProvider.ps1"
}

# Create a singleton instance of GitHubProvider for reuse
$script:GitHubProviderInstance = [GitHubProvider]::new()

function Get-GitHubUser {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    try {
        $user = $script:GitHubProviderInstance.GetCurrentUser($Token, "")
        return $user
    } catch {
        Write-Host "Error fetching user info: $_" -ForegroundColor Red
        return $null
    }
}

function Get-GitHubRepositories {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    try {
        $repos = $script:GitHubProviderInstance.ListUserRepositories($Token, "")
        return $repos
    } catch {
        Write-Host "Error fetching repositories: $_" -ForegroundColor Red
        return @()
    }
}

function Get-RunnerRegistrationToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        [Parameter(Mandatory=$true)]
        [string]$Repository
    )
    
    try {
        $registrationToken = $script:GitHubProviderInstance.GetRunnerRegistrationToken($Token, $Repository, "repository", "")
        return $registrationToken
    } catch {
        Write-Host "Error getting registration token: $_" -ForegroundColor Red
        return $null
    }
}

function Test-GitHubToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    Write-Host "Validating token..." -ForegroundColor Yellow
    
    $isValid = $script:GitHubProviderInstance.ValidateToken($Token, "")
    if ($isValid) {
        $user = Get-GitHubUser -Token $Token
        if ($user) {
            Write-Host "Token valid! Authenticated as: $($user.login)" -ForegroundColor Green
            return $true
        }
    }
    
    Write-Host "Token validation failed" -ForegroundColor Red
    return $false
}
