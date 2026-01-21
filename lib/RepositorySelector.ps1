# Repository Selection Module

# Load platform providers if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'IPlatformProvider').Type) {
    . "$PSScriptRoot\PlatformProvider.ps1"
}

function Invoke-RepositorySelection {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Write-Host ""
    $platformName = $Config.GetPlatformDisplayName()
    Write-Host (L "repo_selection_title" $platformName) -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $Config.GitHubToken) {
        Write-Host (L "repo_token_not_configured" $platformName) -ForegroundColor Red
        Write-Host (L "repo_configure_token_first") -ForegroundColor Yellow
        return
    }
    
    # For GitLab, ask for target type (Project or Group)
    if ($Config.Platform -eq "gitlab") {
        Show-TargetTypeSelection
        $targetType = Read-Host "Select target type (1-2)"
        
        if ($targetType -eq "1") {
            $Config.TargetType = "project"
            Invoke-ProjectSelection -Config $Config
        } elseif ($targetType -eq "2") {
            $Config.TargetType = "group"
            Invoke-GroupSelection -Config $Config
        } else {
            Write-Host (L "platform_invalid") -ForegroundColor Red
            return
        }
    } else {
        # GitHub - only repositories
        Invoke-GitHubRepositorySelection -Config $Config
    }
}

function Show-RepositoryPage {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Repositories,
        
        [Parameter(Mandatory=$true)]
        [int]$Page,
        
        [Parameter(Mandatory=$true)]
        [int]$PageSize
    )
    
    $startIndex = ($Page - 1) * $PageSize
    $endIndex = [Math]::Min($startIndex + $PageSize, $Repositories.Count)
    $totalPages = [Math]::Ceiling($Repositories.Count / $PageSize)
    
    Write-Host ""
    Write-Host "Page $Page of $totalPages (Total: $($Repositories.Count) repositories)" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = $startIndex; $i -lt $endIndex; $i++) {
        $repo = $Repositories[$i]
        $displayIndex = $i + 1
        $visibility = if ($repo.private) { "[Private]" } else { "[Public]" }
        Write-Host "$displayIndex. $visibility $($repo.full_name)" -ForegroundColor White
        if ($repo.description) {
            Write-Host "   $($repo.description)" -ForegroundColor Gray
        }
    }
    Write-Host ""
    
    return @{
        StartIndex = $startIndex
        EndIndex = $endIndex
        TotalPages = $totalPages
    }
}

function Invoke-GitHubRepositorySelection {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Write-Host "Fetching your repositories..." -ForegroundColor Yellow
    
    $repos = Get-GitHubRepositories -Token $Config.GitHubToken
    
    if ($repos.Count -eq 0) {
        Write-Host "No repositories found" -ForegroundColor Yellow
        return
    }
    
    # Sort by updated date (most recent first)
    $repos = $repos | Sort-Object -Property updated_at -Descending
    
    $pageSize = 10
    $currentPage = 1
    $searchTerm = ""
    $filtered = $repos
    
    do {
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Repository Selection" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        if ($searchTerm) {
            Write-Host "Search filter: '$searchTerm'" -ForegroundColor Yellow
            Write-Host ""
        }
        
        $pageInfo = Show-RepositoryPage -Repositories $filtered -Page $currentPage -PageSize $pageSize
        
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  [number] - Select repository" -ForegroundColor White
        Write-Host "  n - Next page" -ForegroundColor White
        Write-Host "  p - Previous page" -ForegroundColor White
        Write-Host "  s - Search/Filter" -ForegroundColor White
        Write-Host "  c - Clear filter" -ForegroundColor White
        Write-Host "  q - Quit" -ForegroundColor White
        Write-Host ""
        
        $input = Read-Host "Enter command or number"
        
        switch -Regex ($input) {
            '^[0-9]+$' {
                # Number selected
                $index = [int]$input - 1
                if ($index -ge 0 -and $index -lt $filtered.Count) {
                    $Config.Repository = $filtered[$index].full_name
                    $Config.Save("None")
                    Write-Host ""
                    Write-Host "Repository set to: $($Config.Repository)" -ForegroundColor Green
                    return
                } else {
                    Write-Host "Invalid selection" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            '^n$' {
                # Next page
                if ($currentPage -lt $pageInfo.TotalPages) {
                    $currentPage++
                } else {
                    Write-Host "Already on last page" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
            }
            '^p$' {
                # Previous page
                if ($currentPage -gt 1) {
                    $currentPage--
                } else {
                    Write-Host "Already on first page" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
            }
            '^s$' {
                # Search
                Write-Host ""
                $searchTerm = Read-Host "Enter search term (searches in name and description)"
                if ($searchTerm) {
                    $filtered = $repos | Where-Object { 
                        $_.full_name -like "*$searchTerm*" -or 
                        ($_.description -and $_.description -like "*$searchTerm*")
                    }
                    
                    if ($filtered.Count -eq 0) {
                        Write-Host "No repositories match '$searchTerm'" -ForegroundColor Yellow
                        $filtered = $repos
                        $searchTerm = ""
                        Start-Sleep -Seconds 2
                    }
                    $currentPage = 1
                }
            }
            '^c$' {
                # Clear filter
                $filtered = $repos
                $searchTerm = ""
                $currentPage = 1
                Write-Host "Filter cleared" -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
            '^q$' {
                # Quit
                return
            }
            default {
                Write-Host "Invalid command" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Invoke-ProjectSelection {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Write-Host (L "repo_fetching" (L "repo_projects")) -ForegroundColor Yellow
    
    try {
        $provider = $Config.GetProvider()
        if ($null -eq $provider) {
            Write-Host "$(L 'error'): Could not load platform provider" -ForegroundColor Red
            return
        }
        
        $projects = $provider.ListUserRepositories($Config.GitHubToken, $Config.InstanceUrl)
        
        if ($projects.Count -eq 0) {
            Write-Host (L "repo_none_found" (L "repo_projects")) -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host (L "repo_search_prompt" (L "repo_projects")) -ForegroundColor Cyan
        Write-Host ""
        
        $searchTerm = Read-Host (L "repo_search")
        
        $filtered = $projects | Where-Object { 
            $_.path_with_namespace -like "*$searchTerm*" -or 
            $_.name -like "*$searchTerm*" -or
            ($_.description -and $_.description -like "*$searchTerm*")
        } | Select-Object -First 20
        
        if ($filtered.Count -eq 0) {
            Write-Host (L "repo_no_match" (L "repo_projects") $searchTerm) -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host (L "repo_found" $filtered.Count (L "repo_projects")) -ForegroundColor Green
        Write-Host ""
        
        for ($i = 0; $i -lt $filtered.Count; $i++) {
            $project = $filtered[$i]
            $visibility = switch ($project.visibility) {
                "private" { "[Private]" }
                "internal" { "[Internal]" }
                "public" { "[Public]" }
                default { "[Project]" }
            }
            Write-Host "$($i + 1). $visibility $($project.path_with_namespace)" -ForegroundColor White
            if ($project.description) {
                Write-Host "   $($project.description)" -ForegroundColor Gray
            }
        }
        Write-Host ""
        
        $selection = Read-Host (L "repo_select_prompt" (L "menu_project") $filtered.Count)
        
        $index = [int]$selection - 1
        if ($index -ge 0 -and $index -lt $filtered.Count) {
            $Config.Repository = $filtered[$index].path_with_namespace
            $Config.Save("None")
            Write-Host ""
            Write-Host (L "repo_set_to" (L "menu_project") $Config.Repository) -ForegroundColor Green
        } else {
            Write-Host (L "platform_invalid") -ForegroundColor Red
        }
    } catch {
        Write-Host (L "repo_error_fetching" (L "repo_projects") $_) -ForegroundColor Red
    }
}

function Invoke-GroupSelection {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Write-Host (L "repo_fetching" (L "repo_groups")) -ForegroundColor Yellow
    
    try {
        $provider = $Config.GetProvider()
        if ($null -eq $provider) {
            Write-Host "$(L 'error'): Could not load platform provider" -ForegroundColor Red
            return
        }
        
        $groups = $provider.ListUserGroups($Config.GitHubToken, $Config.InstanceUrl)
        
        if ($groups.Count -eq 0) {
            Write-Host (L "repo_none_found" (L "repo_groups")) -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host (L "repo_search_prompt" (L "repo_groups")) -ForegroundColor Cyan
        Write-Host ""
        
        $searchTerm = Read-Host (L "repo_search")
        
        $filtered = $groups | Where-Object { 
            $_.full_path -like "*$searchTerm*" -or 
            $_.name -like "*$searchTerm*" -or
            ($_.description -and $_.description -like "*$searchTerm*")
        } | Select-Object -First 20
        
        if ($filtered.Count -eq 0) {
            Write-Host (L "repo_no_match" (L "repo_groups") $searchTerm) -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host (L "repo_found" $filtered.Count (L "repo_groups")) -ForegroundColor Green
        Write-Host ""
        
        for ($i = 0; $i -lt $filtered.Count; $i++) {
            $group = $filtered[$i]
            $visibility = switch ($group.visibility) {
                "private" { "[Private]" }
                "internal" { "[Internal]" }
                "public" { "[Public]" }
                default { "[Group]" }
            }
            Write-Host "$($i + 1). $visibility $($group.full_path)" -ForegroundColor White
            if ($group.description) {
                Write-Host "   $($group.description)" -ForegroundColor Gray
            }
        }
        Write-Host ""
        
        $selection = Read-Host (L "repo_select_prompt" (L "menu_group") $filtered.Count)
        
        $index = [int]$selection - 1
        if ($index -ge 0 -and $index -lt $filtered.Count) {
            $Config.Repository = $filtered[$index].full_path
            $Config.Save("None")
            Write-Host ""
            Write-Host (L "repo_set_to" (L "menu_group") $Config.Repository) -ForegroundColor Green
        } else {
            Write-Host (L "platform_invalid") -ForegroundColor Red
        }
    } catch {
        Write-Host (L "repo_error_fetching" (L "repo_groups") $_) -ForegroundColor Red
    }
}
