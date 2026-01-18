# GitHub API Integration Module

function Get-GitHubUser {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.github.com/user" `
            -Headers @{ Authorization = "token $Token" } `
            -ErrorAction Stop
        return $response
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
        $repos = @()
        $page = 1
        
        do {
            $pageRepos = Invoke-RestMethod `
                -Uri "https://api.github.com/user/repos?per_page=100&page=$page&sort=updated" `
                -Headers @{ Authorization = "token $Token" } `
                -ErrorAction Stop
            $repos += $pageRepos
            $page++
        } while ($pageRepos.Count -eq 100)
        
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
        $response = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$Repository/actions/runners/registration-token" `
            -Method POST `
            -Headers @{ Authorization = "token $Token" } `
            -ErrorAction Stop
        return $response.token
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
    
    $user = Get-GitHubUser -Token $Token
    if ($user) {
        Write-Host "Token valid! Authenticated as: $($user.login)" -ForegroundColor Green
        return $true
    }
    
    Write-Host "Token validation failed" -ForegroundColor Red
    return $false
}

Export-ModuleMember -Function Get-GitHubUser, Get-GitHubRepositories, Get-RunnerRegistrationToken, Test-GitHubToken
