# GitHub Platform Provider Implementation
# Implements IPlatformProvider interface for GitHub Actions runners

# Load the base interface if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'IPlatformProvider').Type) {
    . "$PSScriptRoot\PlatformProvider.ps1"
}

<#
.SYNOPSIS
GitHub platform provider implementation.

.DESCRIPTION
Implements the IPlatformProvider interface for GitHub Actions runners.
Provides GitHub-specific API integration, runner management, and Docker support.
#>
class GitHubProvider : IPlatformProvider {
    
    # ============================================================================
    # Platform Identification Methods
    # ============================================================================
    
    [string] GetPlatformName() {
        return "github"
    }
    
    [string] GetPlatformDisplayName() {
        return "GitHub"
    }
    
    # ============================================================================
    # Authentication Methods
    # ============================================================================
    
    [bool] ValidateToken([string]$Token, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            return $false
        }
        
        try {
            $user = $this.GetCurrentUser($Token, $InstanceUrl)
            return $null -ne $user
        }
        catch {
            return $false
        }
    }
    
    [object] GetCurrentUser([string]$Token, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        try {
            $headers = @{
                Authorization = "token $Token"
                Accept = "application/vnd.github.v3+json"
            }
            
            $response = Invoke-RestMethod `
                -Uri "https://api.github.com/user" `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to get GitHub user: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    # ============================================================================
    # Repository/Project Operations
    # ============================================================================
    
    [array] SearchRepositories([string]$Token, [string]$Query, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($Query)) {
            return $this.ListUserRepositories($Token, $InstanceUrl)
        }
        
        try {
            $headers = @{
                Authorization = "token $Token"
                Accept = "application/vnd.github.v3+json"
            }
            
            # URL encode the query using .NET method
            $encodedQuery = [Uri]::EscapeDataString($Query)
            $uri = "https://api.github.com/search/repositories?q=$encodedQuery&per_page=100"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response.items
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to search repositories: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    [array] ListUserRepositories([string]$Token, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        try {
            $headers = @{
                Authorization = "token $Token"
                Accept = "application/vnd.github.v3+json"
            }
            
            $repos = @()
            $page = 1
            $pageRepos = @()
            
            do {
                $uri = "https://api.github.com/user/repos?per_page=100&page=$page&sort=updated&affiliation=owner,collaborator,organization_member"
                
                $pageRepos = Invoke-RestMethod `
                    -Uri $uri `
                    -Headers $headers `
                    -Method Get `
                    -ErrorAction Stop
                
                $repos += $pageRepos
                $page++
            } while ($pageRepos.Count -eq 100)
            
            return $repos
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to list repositories: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    [object] GetRepository([string]$Token, [string]$RepoPath, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($RepoPath)) {
            throw [System.ArgumentException]::new("Repository path cannot be empty")
        }
        
        try {
            $headers = @{
                Authorization = "token $Token"
                Accept = "application/vnd.github.v3+json"
            }
            
            $uri = "https://api.github.com/repos/$RepoPath"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to get repository: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions")
            }
            elseif ($statusCode -eq 404) {
                throw [System.IO.FileNotFoundException]::new("Repository not found or not accessible: $RepoPath")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    # ============================================================================
    # Group Operations (Not supported by GitHub)
    # ============================================================================
    
    [array] SearchGroups([string]$Token, [string]$Query, [string]$InstanceUrl) {
        # GitHub does not support groups, return empty array
        return @()
    }
    
    [array] ListUserGroups([string]$Token, [string]$InstanceUrl) {
        # GitHub does not support groups, return empty array
        return @()
    }
    
    [object] GetGroup([string]$Token, [string]$GroupPath, [string]$InstanceUrl) {
        # GitHub does not support groups, return null
        return $null
    }
    
    # ============================================================================
    # Runner Operations
    # ============================================================================
    
    [string] GetRunnerRegistrationToken([string]$Token, [string]$TargetPath, [string]$TargetType, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($TargetPath)) {
            throw [System.ArgumentException]::new("Repository path cannot be empty")
        }
        
        try {
            $headers = @{
                Authorization = "token $Token"
                Accept = "application/vnd.github.v3+json"
            }
            
            $uri = "https://api.github.com/repos/$TargetPath/actions/runners/registration-token"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Post `
                -ErrorAction Stop
            
            return $response.token
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to get registration token: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions. Required scopes: repo, workflow")
            }
            elseif ($statusCode -eq 404) {
                throw [System.IO.FileNotFoundException]::new("Repository not found or not accessible: $TargetPath")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    [string] GetRunnerDownloadUrl([string]$Version, [string]$OS, [string]$Arch) {
        # Default values if not provided
        if ([string]::IsNullOrWhiteSpace($Version)) {
            $Version = "2.311.0"
        }
        if ([string]::IsNullOrWhiteSpace($OS)) {
            $OS = "win"
        }
        if ([string]::IsNullOrWhiteSpace($Arch)) {
            $Arch = "x64"
        }
        
        return "https://github.com/actions/runner/releases/download/v$Version/actions-runner-$OS-$Arch-$Version.zip"
    }
    
    [string] GetRunnerBinaryName() {
        return "Runner.Listener.exe"
    }
    
    [hashtable] GetRunnerConfigureArgs([string]$Url, [string]$Token, [string]$Name, [array]$Tags, [string]$Executor) {
        $args = @{
            url = $Url
            token = $Token
            name = $Name
            unattended = $true
            replace = $true
        }
        
        # Add labels if provided
        if ($null -ne $Tags -and $Tags.Count -gt 0) {
            $args['labels'] = ($Tags -join ',')
        }
        
        # Executor parameter is ignored for GitHub (not applicable)
        
        return $args
    }
    
    # ============================================================================
    # Docker Operations
    # ============================================================================
    
    [string] GetDockerImageName() {
        return "github-runner"
    }
    
    [hashtable] GetDockerEnvironmentVariables([string]$Token, [string]$TargetPath, [string]$RunnerName, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($TargetPath)) {
            throw [System.ArgumentException]::new("Repository path cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($RunnerName)) {
            throw [System.ArgumentException]::new("Runner name cannot be empty")
        }
        
        return @{
            GITHUB_TOKEN = $Token
            GITHUB_REPOSITORY = $TargetPath
            RUNNER_NAME = $RunnerName
        }
    }
    
    [string] GetDockerEntrypointScript() {
        return @"
#!/bin/bash
set -e

# Get registration token
REGISTRATION_TOKEN=`$(curl -s -X POST \
  -H "Authorization: token `${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/`${GITHUB_REPOSITORY}/actions/runners/registration-token" \
  | jq -r .token)

# Configure runner
./config.sh \
  --url "https://github.com/`${GITHUB_REPOSITORY}" \
  --token "`${REGISTRATION_TOKEN}" \
  --name "`${RUNNER_NAME}" \
  --labels "docker,self-hosted" \
  --unattended \
  --replace

# Cleanup function
cleanup() {
  echo "Removing runner..."
  ./config.sh remove --token "`${REGISTRATION_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start runner
./run.sh & wait `$!
"@
    }
    
    # ============================================================================
    # Instance URL Management
    # ============================================================================
    
    [string] GetDefaultInstanceUrl() {
        return "https://github.com"
    }
    
    [bool] RequiresInstanceUrl() {
        return $false
    }
}
