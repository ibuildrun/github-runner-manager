# Runner Installation Module

. "$PSScriptRoot\GitHub.ps1"

function Install-GitHubRunner {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Installing GitHub Actions Runner..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check configuration
    if (-not $Config.IsValid()) {
        Write-Host "Configuration incomplete" -ForegroundColor Red
        if (-not $Config.GitHubToken) {
            Write-Host "Please configure token first (option 1)" -ForegroundColor Yellow
        }
        if (-not $Config.Repository) {
            Write-Host "Please select repository first (option 2)" -ForegroundColor Yellow
        }
        return
    }
    
    # Check if already installed
    if (Test-Path "$RunnerPath\run.cmd") {
        Write-Host "Runner is already installed at: $RunnerPath" -ForegroundColor Yellow
        $response = Read-Host "Reinstall? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            return
        }
        
        # Remove old config
        if (Test-Path "$RunnerPath\.runner") {
            Write-Host "Removing old configuration..." -ForegroundColor Yellow
            Set-Location $RunnerPath
            $removeToken = Get-RunnerRegistrationToken -Token $Config.GitHubToken -Repository $Config.Repository
            if ($removeToken) {
                & ".\config.cmd" remove --token $removeToken
            }
        }
    }
    
    # Create directory
    if (-not (Test-Path $RunnerPath)) {
        New-Item -ItemType Directory -Path $RunnerPath -Force | Out-Null
    }
    
    Set-Location $RunnerPath
    
    # Download
    Write-Host "Downloading runner..." -ForegroundColor Yellow
    $runnerVersion = "2.321.0"
    $runnerUrl = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
    $runnerZip = "actions-runner-win-x64-$runnerVersion.zip"
    
    if (-not (Test-Path $runnerZip)) {
        Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -ErrorAction Stop
    }
    
    # Extract
    Write-Host "Extracting runner..." -ForegroundColor Yellow
    Expand-Archive -Path $runnerZip -DestinationPath $RunnerPath -Force
    
    # Configure
    Write-Host "Configuring runner..." -ForegroundColor Yellow
    $runnerName = "$($Config.Repository.Replace('/', '-'))-$(Get-Random -Minimum 1000 -Maximum 9999)"
    $registrationToken = Get-RunnerRegistrationToken -Token $Config.GitHubToken -Repository $Config.Repository
    
    if (-not $registrationToken) {
        Write-Host "Failed to get registration token" -ForegroundColor Red
        return
    }
    
    & ".\config.cmd" `
        --url "https://github.com/$($Config.Repository)" `
        --token $registrationToken `
        --name $runnerName `
        --work "_work" `
        --labels "windows,self-hosted" `
        --unattended `
        --replace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Runner installed successfully!" -ForegroundColor Green
        Write-Host "Name: $runnerName" -ForegroundColor Cyan
        Write-Host "Repository: $($Config.Repository)" -ForegroundColor Cyan
        Write-Host "Path: $RunnerPath" -ForegroundColor Cyan
    } else {
        Write-Host "Installation failed" -ForegroundColor Red
    }
}

function Uninstall-GitHubRunner {
    param(
        [Parameter(Mandatory=$true)]
        $Config,
        [Parameter(Mandatory=$true)]
        [string]$RunnerPath
    )
    
    Write-Host ""
    Write-Host "Uninstalling runner..." -ForegroundColor Cyan
    
    $response = Read-Host "Are you sure? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        return
    }
    
    # Stop runner
    Stop-GitHubRunner -Config $Config -RunnerPath $RunnerPath
    
    # Disable auto-start
    Disable-RunnerAutoStart -Config $Config
    
    # Remove config
    if (Test-Path "$RunnerPath\.runner") {
        Write-Host "Removing configuration..." -ForegroundColor Yellow
        Set-Location $RunnerPath
        
        # Only try to remove from GitHub if we have valid config
        if ($Config.IsValid()) {
            $removeToken = Get-RunnerRegistrationToken -Token $Config.GitHubToken -Repository $Config.Repository
            if ($removeToken) {
                & ".\config.cmd" remove --token $removeToken
            }
        } else {
            Write-Host "Skipping GitHub removal (no valid configuration)" -ForegroundColor Yellow
            # Just remove local config
            if (Test-Path "$RunnerPath\.runner") {
                Remove-Item "$RunnerPath\.runner" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$RunnerPath\.credentials") {
                Remove-Item "$RunnerPath\.credentials" -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Remove directory
    if (Test-Path $RunnerPath) {
        Write-Host "Removing files..." -ForegroundColor Yellow
        try {
            Remove-Item -Path $RunnerPath -Recurse -Force -ErrorAction Stop
            Write-Host "Runner uninstalled" -ForegroundColor Green
        } catch {
            Write-Host "Could not remove all files. Some may be in use." -ForegroundColor Yellow
            Write-Host "You can manually delete: $RunnerPath" -ForegroundColor Gray
        }
    } else {
        Write-Host "Runner directory not found" -ForegroundColor Yellow
    }
}
