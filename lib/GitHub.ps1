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

function Get-GitHubRunners {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        [Parameter(Mandatory=$true)]
        [string]$Repository
    )
    
    try {
        $headers = @{
            "Authorization" = "token $Token"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/actions/runners" -Headers $headers -Method Get
        return $response.runners
    } catch {
        Write-Host "Error fetching runners: $_" -ForegroundColor Red
        return @()
    }
}

function Remove-GitHubRunner {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        [Parameter(Mandatory=$true)]
        [string]$Repository,
        [Parameter(Mandatory=$true)]
        [int]$RunnerId,
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    
    try {
        $headers = @{
            "Authorization" = "token $Token"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        $uri = "https://api.github.com/repos/$Repository/actions/runners/$RunnerId"
        if ($Force) {
            $uri += "?force=true"
        }
        
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete | Out-Null
        return $true
    } catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -match '"message":"([^"]+)"') {
            Write-Host "  Error: $($matches[1])" -ForegroundColor Red
        } else {
            Write-Host "  Error removing runner $RunnerId : $errorMessage" -ForegroundColor Red
        }
        return $false
    }
}

function Remove-OfflineRunners {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        [Parameter(Mandatory=$true)]
        [string]$Repository,
        [Parameter(Mandatory=$false)]
        [switch]$DryRun,
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    
    Write-Host ""
    Write-Host "=== Cleanup Offline Runners ===" -ForegroundColor Cyan
    Write-Host ""
    
    $runners = Get-GitHubRunners -Token $Token -Repository $Repository
    
    if ($runners.Count -eq 0) {
        Write-Host "No runners found" -ForegroundColor Yellow
        return
    }
    
    $offlineRunners = $runners | Where-Object { $_.status -eq "offline" }
    
    if ($offlineRunners.Count -eq 0) {
        Write-Host "No offline runners found" -ForegroundColor Green
        return
    }
    
    Write-Host "Found $($offlineRunners.Count) offline runner(s):" -ForegroundColor Yellow
    Write-Host ""
    
    # Separate runners with active jobs
    $runnersWithJobs = @()
    $runnersWithoutJobs = @()
    
    foreach ($runner in $offlineRunners) {
        $status = if ($runner.busy) { "BUSY" } else { "IDLE" }
        $color = if ($runner.busy) { "Yellow" } else { "Gray" }
        Write-Host "  - $($runner.name) (ID: $($runner.id)) [$status]" -ForegroundColor $color
        
        if ($runner.busy) {
            $runnersWithJobs += $runner
        } else {
            $runnersWithoutJobs += $runner
        }
    }
    
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "Dry run mode - no runners will be removed" -ForegroundColor Yellow
        if ($runnersWithJobs.Count -gt 0) {
            Write-Host "Note: $($runnersWithJobs.Count) runner(s) marked as BUSY would require --force flag" -ForegroundColor Yellow
        }
        return
    }
    
    # Ask about regular runners
    if ($runnersWithoutJobs.Count -gt 0) {
        Write-Host "Remove $($runnersWithoutJobs.Count) idle offline runner(s)? (y/N)" -ForegroundColor Cyan
        $confirm = Read-Host
        
        if ($confirm -eq 'y') {
            Write-Host ""
            foreach ($runner in $runnersWithoutJobs) {
                Write-Host "Removing: $($runner.name)..." -ForegroundColor Yellow
                if (Remove-GitHubRunner -Token $Token -Repository $Repository -RunnerId $runner.id) {
                    Write-Host "  $([char]0x2713) Removed" -ForegroundColor Green
                } else {
                    Write-Host "  $([char]0x2717) Failed" -ForegroundColor Red
                }
            }
        }
    }
    
    # Ask about busy runners
    if ($runnersWithJobs.Count -gt 0) {
        Write-Host ""
        Write-Host "WARNING: $($runnersWithJobs.Count) runner(s) are marked as BUSY (possibly stuck)" -ForegroundColor Yellow
        Write-Host "These runners are offline but GitHub thinks they're running jobs." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Force remove stuck runners? This will cancel any associated jobs. (y/N)" -ForegroundColor Red
        $forceConfirm = Read-Host
        
        if ($forceConfirm -eq 'y') {
            Write-Host ""
            foreach ($runner in $runnersWithJobs) {
                Write-Host "Force removing: $($runner.name)..." -ForegroundColor Red
                if (Remove-GitHubRunner -Token $Token -Repository $Repository -RunnerId $runner.id -Force) {
                    Write-Host "  $([char]0x2713) Force removed" -ForegroundColor Green
                } else {
                    Write-Host "  $([char]0x2717) Failed" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Skipped busy runners. They will remain until jobs complete or timeout." -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "$([char]0x2713) Cleanup complete" -ForegroundColor Green
    Write-Host ""
}
