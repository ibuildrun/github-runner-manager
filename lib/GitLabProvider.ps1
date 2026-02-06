# GitLab Platform Provider Implementation
# Implements IPlatformProvider interface for GitLab CI/CD runners

# Load the base interface if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'IPlatformProvider').Type) {
    . "$PSScriptRoot\PlatformProvider.ps1"
}

<#
.SYNOPSIS
GitLab platform provider implementation.

.DESCRIPTION
Implements the IPlatformProvider interface for GitLab CI/CD runners.
Provides GitLab-specific API integration, runner management, and Docker support.
Supports both gitlab.com and self-hosted GitLab instances.
#>
class GitLabProvider : IPlatformProvider {
    
    # ============================================================================
    # Platform Identification Methods
    # ============================================================================
    
    [string] GetPlatformName() {
        return "gitlab"
    }
    
    [string] GetPlatformDisplayName() {
        return "GitLab"
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
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $uri = "$InstanceUrl/api/v4/user"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to get GitLab user: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions. Required scope: api")
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
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        if ([string]::IsNullOrWhiteSpace($Query)) {
            return $this.ListUserRepositories($Token, $InstanceUrl)
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $encodedQuery = [Uri]::EscapeDataString($Query)
            $uri = "$InstanceUrl/api/v4/projects?search=$encodedQuery&per_page=100"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to search projects: $($_.Exception.Message)"
            
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
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $projects = @()
            $page = 1
            $pageProjects = @()
            
            do {
                $uri = "$InstanceUrl/api/v4/projects?membership=true&per_page=100&page=$page&order_by=last_activity_at"
                
                $pageProjects = Invoke-RestMethod `
                    -Uri $uri `
                    -Headers $headers `
                    -Method Get `
                    -ErrorAction Stop
                
                $projects += $pageProjects
                $page++
            } while ($pageProjects.Count -eq 100)
            
            return $projects
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to list projects: $($_.Exception.Message)"
            
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
            throw [System.ArgumentException]::new("Project path cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $encodedPath = [Uri]::EscapeDataString($RepoPath)
            $uri = "$InstanceUrl/api/v4/projects/$encodedPath"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to get project: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions")
            }
            elseif ($statusCode -eq 404) {
                throw [System.IO.FileNotFoundException]::new("Project not found or not accessible: $RepoPath")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    # ============================================================================
    # Group Operations
    # ============================================================================
    
    [array] SearchGroups([string]$Token, [string]$Query, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        if ([string]::IsNullOrWhiteSpace($Query)) {
            return $this.ListUserGroups($Token, $InstanceUrl)
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $encodedQuery = [Uri]::EscapeDataString($Query)
            $uri = "$InstanceUrl/api/v4/groups?search=$encodedQuery&per_page=100"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to search groups: $($_.Exception.Message)"
            
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
    
    [array] ListUserGroups([string]$Token, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $groups = @()
            $page = 1
            $pageGroups = @()
            
            do {
                $uri = "$InstanceUrl/api/v4/groups?per_page=100&page=$page"
                
                $pageGroups = Invoke-RestMethod `
                    -Uri $uri `
                    -Headers $headers `
                    -Method Get `
                    -ErrorAction Stop
                
                $groups += $pageGroups
                $page++
            } while ($pageGroups.Count -eq 100)
            
            return $groups
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to list groups: $($_.Exception.Message)"
            
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
    
    [object] GetGroup([string]$Token, [string]$GroupPath, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($GroupPath)) {
            throw [System.ArgumentException]::new("Group path cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $encodedPath = [Uri]::EscapeDataString($GroupPath)
            $uri = "$InstanceUrl/api/v4/groups/$encodedPath"
            
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Headers $headers `
                -Method Get `
                -ErrorAction Stop
            
            return $response
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $message = "Failed to get group: $($_.Exception.Message)"
            
            if ($statusCode -eq 401) {
                throw [System.UnauthorizedAccessException]::new("Invalid token or token expired")
            }
            elseif ($statusCode -eq 403) {
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions")
            }
            elseif ($statusCode -eq 404) {
                throw [System.IO.FileNotFoundException]::new("Group not found or not accessible: $GroupPath")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    # ============================================================================
    # Runner Operations
    # ============================================================================
    
    [string] GetRunnerRegistrationToken([string]$Token, [string]$TargetPath, [string]$TargetType, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($TargetPath)) {
            throw [System.ArgumentException]::new("Target path cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $Token
            }
            
            $encodedPath = [Uri]::EscapeDataString($TargetPath)
            
            if ($TargetType -eq "group") {
                $uri = "$InstanceUrl/api/v4/groups/$encodedPath/runners/reset_registration_token"
            } else {
                # Default to project
                $uri = "$InstanceUrl/api/v4/projects/$encodedPath/runners/reset_registration_token"
            }
            
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
                throw [System.UnauthorizedAccessException]::new("Token lacks required permissions. Required scope: api")
            }
            elseif ($statusCode -eq 404) {
                throw [System.IO.FileNotFoundException]::new("$TargetType not found or not accessible: $TargetPath")
            }
            else {
                throw [System.Exception]::new($message)
            }
        }
    }
    
    [string] GetRunnerDownloadUrl([string]$Version, [string]$OS, [string]$Arch) {
        # Default values if not provided
        if ([string]::IsNullOrWhiteSpace($Version)) {
            $Version = "latest"
        }
        if ([string]::IsNullOrWhiteSpace($OS)) {
            $OS = "windows"
        }
        if ([string]::IsNullOrWhiteSpace($Arch)) {
            $Arch = "amd64"
        }
        
        # GitLab Runner download URL format
        if ($Version -eq "latest") {
            return "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-$OS-$Arch.exe"
        } else {
            return "https://gitlab-runner-downloads.s3.amazonaws.com/v$Version/binaries/gitlab-runner-$OS-$Arch.exe"
        }
    }
    
    [string] GetRunnerBinaryName() {
        return "gitlab-runner.exe"
    }
    
    [hashtable] GetRunnerConfigureArgs([string]$Url, [string]$Token, [string]$Name, [array]$Tags, [string]$Executor) {
        # Default executor to docker if not specified
        if ([string]::IsNullOrWhiteSpace($Executor)) {
            $Executor = "docker"
        }
        
        $args = @{
            url = $Url
            "registration-token" = $Token
            name = $Name
            executor = $Executor
            "non-interactive" = $true
        }
        
        # Add tags if provided
        if ($null -ne $Tags -and $Tags.Count -gt 0) {
            $args['tag-list'] = ($Tags -join ',')
        }
        
        # Add docker image if executor is docker
        if ($Executor -eq "docker") {
            $args['docker-image'] = "alpine:latest"
        }
        
        return $args
    }
    
    # ============================================================================
    # Docker Operations
    # ============================================================================
    
    [string] GetDockerImageName() {
        return "gitlab-runner"
    }
    
    [hashtable] GetDockerEnvironmentVariables([string]$Token, [string]$TargetPath, [string]$RunnerName, [string]$InstanceUrl) {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw [System.ArgumentException]::new("Token cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($TargetPath)) {
            throw [System.ArgumentException]::new("Target path cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($RunnerName)) {
            throw [System.ArgumentException]::new("Runner name cannot be empty")
        }
        
        if ([string]::IsNullOrWhiteSpace($InstanceUrl)) {
            $InstanceUrl = $this.GetDefaultInstanceUrl()
        }
        
        return @{
            GITLAB_TOKEN = $Token
            GITLAB_PROJECT = $TargetPath
            GITLAB_URL = $InstanceUrl
            RUNNER_NAME = $RunnerName
        }
    }
    
    [string] GetDockerEntrypointScript() {
        return @"
#!/bin/bash
set -e

# Get registration token
REGISTRATION_TOKEN=`$(curl -s -X POST \
  -H "PRIVATE-TOKEN: `${GITLAB_TOKEN}" \
  "`${GITLAB_URL}/api/v4/projects/`$(echo `${GITLAB_PROJECT} | sed 's/\//%2F/g')/runners/reset_registration_token" \
  | jq -r .token)

# Register runner
gitlab-runner register \
  --non-interactive \
  --url "`${GITLAB_URL}" \
  --registration-token "`${REGISTRATION_TOKEN}" \
  --name "`${RUNNER_NAME}" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --tag-list "docker,self-hosted"

# Cleanup function
cleanup() {
  echo "Unregistering runner..."
  gitlab-runner unregister --all-runners
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start runner
gitlab-runner run & wait `$!
"@
    }
    
    # ============================================================================
    # Instance URL Management
    # ============================================================================
    
    [string] GetDefaultInstanceUrl() {
        return "https://gitlab.com"
    }
    
    [bool] RequiresInstanceUrl() {
        return $true
    }
}
