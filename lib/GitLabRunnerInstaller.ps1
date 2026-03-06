# GitLab Runner Installation Module

# Load platform providers if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'GitLabProvider').Type) {
    . "$PSScriptRoot\GitLabProvider.ps1"
}

function Install-GitLabRunner {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "GitLab Runner Installation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $Config.GitHubToken) {
        Write-Host "GitLab token not configured" -ForegroundColor Red
        return
    }
    
    if (-not $Config.Repository) {
        Write-Host "Project/Group not selected" -ForegroundColor Red
        return
    }
    
    # Create runner directory
    if (-not (Test-Path $RunnerPath)) {
        New-Item -ItemType Directory -Path $RunnerPath -Force | Out-Null
        Write-Host "Created directory: $RunnerPath" -ForegroundColor Green
    }
    
    # Get provider
    $provider = $Config.GetProvider()
    if ($null -eq $provider) {
        Write-Host "Error: Could not load GitLab provider" -ForegroundColor Red
        return
    }
    
    # Download GitLab Runner
    Write-Host "Downloading GitLab Runner..." -ForegroundColor Yellow
    
    $downloadUrl = $provider.GetRunnerDownloadUrl("latest", "windows", "amd64")
    $binaryPath = Join-Path $RunnerPath "gitlab-runner.exe"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $binaryPath -ErrorAction Stop
        Write-Host "Downloaded GitLab Runner to: $binaryPath" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading runner: $_" -ForegroundColor Red
        return
    }
    
    # Get registration token
    Write-Host "Getting registration token..." -ForegroundColor Yellow
    
    try {
        $registrationToken = $provider.GetRunnerRegistrationToken(
            $Config.GitHubToken,
            $Config.Repository,
            $Config.TargetType,
            $Config.InstanceUrl
        )
        
        if ([string]::IsNullOrEmpty($registrationToken)) {
            Write-Host "Error: Could not get registration token" -ForegroundColor Red
            return
        }
        
        Write-Host "Registration token obtained" -ForegroundColor Green
    } catch {
        Write-Host "Error getting registration token: $_" -ForegroundColor Red
        return
    }
    
    # Ask for runner name
    $defaultName = "gitlab-runner-$(Get-Random -Minimum 1000 -Maximum 9999)"
    $runnerName = Read-Host "Enter runner name (default: $defaultName)"
    if ([string]::IsNullOrEmpty($runnerName)) {
        $runnerName = $defaultName
    }
    
    # Ask for tags
    Write-Host ""
    Write-Host "Enter tags (comma-separated, e.g. docker,windows,production)" -ForegroundColor Cyan
    $tagsInput = Read-Host "Tags (default: docker,self-hosted)"
    if ([string]::IsNullOrEmpty($tagsInput)) {
        $tags = @("docker", "self-hosted")
    } else {
        $tags = $tagsInput -split ',' | ForEach-Object { $_.Trim() }
    }
    
    # Ask for executor
    Write-Host ""
    Write-Host "Select executor:" -ForegroundColor Cyan
    Write-Host "  1. Docker (recommended)" -ForegroundColor White
    Write-Host "  2. Shell" -ForegroundColor White
    $executorChoice = Read-Host "Select (1-2, default: 1)"
    
    $executor = if ($executorChoice -eq "2") { "shell" } else { "docker" }
    
    # Register runner
    Write-Host ""
    Write-Host "Registering runner..." -ForegroundColor Yellow
    
    $instanceUrl = if ([string]::IsNullOrEmpty($Config.InstanceUrl)) { 
        "https://gitlab.com" 
    } else { 
        $Config.InstanceUrl 
    }
    
    $registerArgs = @(
        "register",
        "--non-interactive",
        "--url", $instanceUrl,
        "--registration-token", $registrationToken,
        "--name", $runnerName,
        "--executor", $executor,
        "--tag-list", ($tags -join ',')
    )
    
    if ($executor -eq "docker") {
        $registerArgs += "--docker-image"
        $registerArgs += "alpine:latest"
    }
    
    try {
        $process = Start-Process -FilePath $binaryPath `
            -ArgumentList $registerArgs `
            -WorkingDirectory $RunnerPath `
            -Wait `
            -PassThru `
            -NoNewWindow `
            -RedirectStandardOutput "$RunnerPath\register-output.log" `
            -RedirectStandardError "$RunnerPath\register-error.log"
        
        if ($process.ExitCode -eq 0) {
            Write-Host ""
            Write-Host "Runner registered successfully!" -ForegroundColor Green
            Write-Host "Runner name: $runnerName" -ForegroundColor Cyan
            Write-Host "Executor: $executor" -ForegroundColor Cyan
            Write-Host "Tags: $($tags -join ', ')" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "You can now start the runner (option 6)" -ForegroundColor Yellow
        } else {
            Write-Host "Runner registration failed" -ForegroundColor Red
            $errorLog = Get-Content "$RunnerPath\register-error.log" -Raw -ErrorAction SilentlyContinue
            if ($errorLog) {
                Write-Host "Error details:" -ForegroundColor Yellow
                Write-Host $errorLog -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "Error registering runner: $_" -ForegroundColor Red
    }
}

function Uninstall-GitLabRunner {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "GitLab Runner Uninstallation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Are you sure you want to uninstall the runner? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Stop runner if running
    $process = Get-Process -Name "gitlab-runner" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Stopping runner..." -ForegroundColor Yellow
        Stop-Process -Name "gitlab-runner" -Force
        Start-Sleep -Seconds 2
    }
    
    # Unregister runner
    $binaryPath = Join-Path $RunnerPath "gitlab-runner.exe"
    if (Test-Path $binaryPath) {
        Write-Host "Unregistering runner..." -ForegroundColor Yellow
        try {
            & $binaryPath unregister --all-runners
            Write-Host "Runner unregistered" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Could not unregister runner: $_" -ForegroundColor Yellow
        }
    }
    
    # Remove directory
    if (Test-Path $RunnerPath) {
        Write-Host "Removing runner directory..." -ForegroundColor Yellow
        Remove-Item -Path $RunnerPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Runner uninstalled" -ForegroundColor Green
    } else {
        Write-Host "Runner directory not found" -ForegroundColor Yellow
    }
}
