# Multi-Runner Management Module
# Manages multiple local GitHub/GitLab runners

function Show-LocalRunners {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    $runners = $Config.GetLocalRunners()
    
    Write-Host ""
    Write-Host "=== $(L 'multirunner_local_title') ===" -ForegroundColor Cyan
    Write-Host ""
    
    if ($runners.Count -eq 0) {
        Write-Host (L "multirunner_no_runners") -ForegroundColor Yellow
        Write-Host ""
        Write-Host (L "multirunner_tip") -ForegroundColor Gray
        Write-Host ""
        Write-Host (L "multirunner_note_local") -ForegroundColor DarkGray
        Write-Host (L "multirunner_note_docker") -ForegroundColor DarkGray
        return
    }
    
    $activeRunnerId = $Config.ActiveRunnerId
    
    foreach ($runner in $runners) {
        $isActive = $runner.Id -eq $activeRunnerId
        $prefix = if ($isActive) { "[ACTIVE]" } else { "       " }
        
        # Check if runner is installed
        $isInstalled = Test-Path "$($runner.Path)\run.cmd"
        
        # Check if runner is running
        $isRunning = Test-RunnerProcess -RunnerPath $runner.Path
        
        # Determine status
        if (-not $isInstalled) {
            $status = L "multirunner_status_not_installed"
            $statusColor = "Red"
            $statusIcon = "✗"
        } elseif ($isRunning) {
            $status = L "multirunner_status_running"
            $statusColor = "Green"
            $statusIcon = "✓"
        } else {
            $status = L "multirunner_status_stopped"
            $statusColor = "Yellow"
            $statusIcon = "○"
        }
        
        Write-Host "$prefix Runner: $($runner.Name)" -ForegroundColor $(if ($isActive) { "Green" } else { "White" })
        Write-Host "        $(L 'multirunner_type'): $(L 'multirunner_type_local')" -ForegroundColor Cyan
        Write-Host "        $(L 'multirunner_id'): $($runner.Id)" -ForegroundColor Gray
        Write-Host "        $(L 'multirunner_repository'): $($runner.Repository)" -ForegroundColor Gray
        Write-Host "        $(L 'multirunner_path'): $($runner.Path)" -ForegroundColor Gray
        Write-Host "        $(L 'multirunner_platform'): $($runner.Platform)" -ForegroundColor Gray
        Write-Host "        $(L 'multirunner_status'): $statusIcon $status" -ForegroundColor $statusColor
        
        if ($isInstalled -and $isRunning) {
            # Try to get process info
            $process = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue | Where-Object {
                try {
                    $_.Path -and $_.Path.StartsWith($runner.Path, [StringComparison]::OrdinalIgnoreCase)
                } catch {
                    $false
                }
            } | Select-Object -First 1
            
            if ($process) {
                Write-Host "        $(L 'multirunner_pid'): $($process.Id)" -ForegroundColor DarkGray
                $uptime = (Get-Date) - $process.StartTime
                Write-Host "        $(L 'multirunner_uptime'): $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor DarkGray
            }
        }
        
        Write-Host ""
    }
    
    Write-Host (L "multirunner_docker_note") -ForegroundColor DarkGray
    Write-Host ""
}

function Add-LocalRunner {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    Write-Host ""
    Write-Host "=== Add New Local Runner ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Generate unique ID
    $runnerId = [guid]::NewGuid().ToString().Substring(0, 8)
    
    # Get runner name
    Write-Host "Enter runner name (e.g., 'Main Runner', 'Backup Runner'):" -ForegroundColor Cyan
    $runnerName = Read-Host "Name"
    
    if ([string]::IsNullOrWhiteSpace($runnerName)) {
        Write-Host "Runner name cannot be empty" -ForegroundColor Red
        return
    }
    
    # Get runner path
    Write-Host ""
    Write-Host "Enter runner installation path:" -ForegroundColor Cyan
    Write-Host "Example: C:\actions-runner-$runnerId" -ForegroundColor Gray
    $runnerPath = Read-Host "Path"
    
    if ([string]::IsNullOrWhiteSpace($runnerPath)) {
        $runnerPath = "C:\actions-runner-$runnerId"
        Write-Host "Using default path: $runnerPath" -ForegroundColor Yellow
    }
    
    # Check if path already exists
    if (Test-Path $runnerPath) {
        Write-Host "Warning: Path already exists. Runner may already be installed." -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne "y") {
            Write-Host "Cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    # Get repository
    Write-Host ""
    Write-Host "Current repository: $($Config.Repository)" -ForegroundColor Yellow
    $useCurrentRepo = Read-Host "Use current repository? (y/n)"
    
    $repository = $Config.Repository
    if ($useCurrentRepo -ne "y") {
        Write-Host "Enter repository (owner/repo):" -ForegroundColor Cyan
        $repository = Read-Host "Repository"
        
        if ([string]::IsNullOrWhiteSpace($repository)) {
            Write-Host "Repository cannot be empty" -ForegroundColor Red
            return
        }
    }
    
    # Create runner object
    $runner = @{
        Id = $runnerId
        Name = $runnerName
        Path = $runnerPath
        Repository = $repository
        Platform = $Config.Platform
        Created = (Get-Date).ToString("o")
        Status = "Not Installed"
    }
    
    # Add to config
    $Config.AddLocalRunner($runner)
    
    # Set as active if it's the first runner
    $runners = $Config.GetLocalRunners()
    if ($runners.Count -eq 1) {
        $Config.SetActiveRunner($runnerId)
    }
    
    Write-Host ""
    Write-Host "Runner added successfully!" -ForegroundColor Green
    Write-Host "Runner ID: $runnerId" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Select this runner as active (option 2)" -ForegroundColor Gray
    Write-Host "2. Install the runner (option 5 in main menu)" -ForegroundColor Gray
}

function Select-ActiveRunner {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    $runners = $Config.GetLocalRunners()
    
    if ($runners.Count -eq 0) {
        Write-Host ""
        Write-Host "No runners configured. Add a runner first." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "=== Select Active Runner ===" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $runners.Count; $i++) {
        $runner = $runners[$i]
        $isActive = $runner.Id -eq $Config.ActiveRunnerId
        $marker = if ($isActive) { " [ACTIVE]" } else { "" }
        
        Write-Host "$($i + 1). $($runner.Name)$marker" -ForegroundColor $(if ($isActive) { "Green" } else { "White" })
        Write-Host "   Repository: $($runner.Repository)" -ForegroundColor Gray
        Write-Host "   Path: $($runner.Path)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "0. Cancel" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Select runner"
    
    if ($choice -eq "0") {
        return
    }
    
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $runners.Count) {
        $selectedRunner = $runners[$index]
        $Config.SetActiveRunner($selectedRunner.Id)
        $Config.Repository = $selectedRunner.Repository
        
        Write-Host ""
        Write-Host "Active runner set to: $($selectedRunner.Name)" -ForegroundColor Green
    } else {
        Write-Host "Invalid selection" -ForegroundColor Red
    }
}

function Remove-LocalRunnerInteractive {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    $runners = $Config.GetLocalRunners()
    
    if ($runners.Count -eq 0) {
        Write-Host ""
        Write-Host "No runners configured" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "=== Remove Local Runner ===" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $runners.Count; $i++) {
        $runner = $runners[$i]
        Write-Host "$($i + 1). $($runner.Name)" -ForegroundColor White
        Write-Host "   Repository: $($runner.Repository)" -ForegroundColor Gray
        Write-Host "   Path: $($runner.Path)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "0. Cancel" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Select runner to remove"
    
    if ($choice -eq "0") {
        return
    }
    
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $runners.Count) {
        $selectedRunner = $runners[$index]
        
        Write-Host ""
        Write-Host "Warning: This will remove runner configuration" -ForegroundColor Yellow
        Write-Host "Runner files in $($selectedRunner.Path) will NOT be deleted" -ForegroundColor Yellow
        Write-Host ""
        $confirm = Read-Host "Are you sure? (yes/no)"
        
        if ($confirm -eq "yes") {
            $Config.RemoveLocalRunner($selectedRunner.Id)
            Write-Host ""
            Write-Host "Runner removed from configuration" -ForegroundColor Green
        } else {
            Write-Host "Cancelled" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Invalid selection" -ForegroundColor Red
    }
}

function Test-RunnerProcess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    # Check if Runner.Listener process is running with this path
    $processes = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
    
    if (-not $processes) {
        return $false
    }
    
    foreach ($proc in $processes) {
        try {
            $procPath = $proc.Path
            if ($procPath -and $procPath.StartsWith($RunnerPath, [StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        } catch {
            # Process may have exited
            continue
        }
    }
    
    return $false
}

function Get-ActiveRunnerPath {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    $activeRunner = $Config.GetActiveRunner()
    
    if (-not $activeRunner) {
        return $null
    }
    
    return $activeRunner.Path
}

function Invoke-MultiRunnerMenu {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    do {
        Clear-Host
        Show-Banner
        
        Write-Host ""
        Write-Host "=== $(L 'multirunner_title') ===" -ForegroundColor Cyan
        Write-Host ""
        
        Show-LocalRunners -Config $Config
        
        Write-Host "1. $(L 'multirunner_option_add')" -ForegroundColor White
        Write-Host "2. $(L 'multirunner_option_select')" -ForegroundColor White
        Write-Host "3. $(L 'multirunner_option_remove')" -ForegroundColor White
        Write-Host ""
        Write-Host "0. $(L 'multirunner_option_back')" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host (L "menu_select_option")
        
        switch ($choice) {
            "1" { Add-LocalRunner -Config $Config }
            "2" { Select-ActiveRunner -Config $Config }
            "3" { Remove-LocalRunnerInteractive -Config $Config }
            "0" { break }
            default { 
                Write-Host (L "invalid_option") -ForegroundColor Red 
            }
        }
        
        if ($choice -ne "0") {
            Write-Host ""
            Read-Host (L "press_enter")
        }
    } while ($choice -ne "0")
}
