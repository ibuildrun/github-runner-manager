# Repository Selection Module

. "$PSScriptRoot\GitHub.ps1"
. "$PSScriptRoot\UI.ps1"

function Invoke-RepositorySelection {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Write-Host ""
    Write-Host "Repository Selection" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $Config.GitHubToken) {
        Write-Host "GitHub token not configured" -ForegroundColor Red
        Write-Host "Please configure token first (option 1)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Fetching your repositories..." -ForegroundColor Yellow
    
    $repos = Get-GitHubRepositories -Token $Config.GitHubToken
    
    if ($repos.Count -eq 0) {
        Write-Host "No repositories found" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Search repositories (type to filter, Enter to select):" -ForegroundColor Cyan
    Write-Host ""
    
    $searchTerm = Read-Host "Search"
    
    $filtered = $repos | Where-Object { 
        $_.full_name -like "*$searchTerm*" -or 
        $_.description -like "*$searchTerm*" 
    } | Select-Object -First 20
    
    if ($filtered.Count -eq 0) {
        Write-Host "No repositories match '$searchTerm'" -ForegroundColor Yellow
        return
    }
    
    Show-RepositoryList -Repositories $filtered
    
    $selection = Read-Host "Select repository (1-$($filtered.Count))"
    
    $index = [int]$selection - 1
    if ($index -ge 0 -and $index -lt $filtered.Count) {
        $Config.Repository = $filtered[$index].full_name
        $Config.Save("None")
        Write-Host ""
        Write-Host "Repository set to: $($Config.Repository)" -ForegroundColor Green
    } else {
        Write-Host "Invalid selection" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Invoke-RepositorySelection
