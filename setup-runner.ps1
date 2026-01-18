#!/usr/bin/env pwsh
# Quick setup script for AVYX GitHub Actions Runner

param(
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$InstallPath = "C:\actions-runner",
    [ValidateSet("install", "start", "stop", "status", "uninstall")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AVYX GitHub Actions Runner Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

# Validate token for install action
if ($Action -eq "install" -and [string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host "Error: GITHUB_TOKEN is required for installation" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  `$env:GITHUB_TOKEN = 'ghp_...'" -ForegroundColor White
    Write-Host "  .\setup-runner.ps1 -Action install" -ForegroundColor White
    Write-Host ""
    Write-Host "Or pass token directly:" -ForegroundColor Yellow
    Write-Host "  .\setup-runner.ps1 -GitHubToken 'ghp_...' -Action install" -ForegroundColor White
    exit 1
}

# Perform action
switch ($Action) {
    "install" {
        Write-Host "Installing runner to: $InstallPath" -ForegroundColor Yellow
        Write-Host ""
        
        # Create directory
        if (-not (Test-Path $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        }
        
        Set-Location $InstallPath
        
        # Download
        Write-Host "Downloading runner..." -ForegroundColor Yellow
        $runnerVersion = "2.331.0"
        $runnerUrl = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
        $runnerZip = "actions-runner-win-x64-$runnerVersion.zip"
        
        if (-not (Test-Path $runnerZip)) {
            Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -ErrorAction Stop
        }
        
        # Extract
        Write-Host "Extracting runner..." -ForegroundColor Yellow
        Expand-Archive -Path $runnerZip -DestinationPath $InstallPath -Force
        
        # Get token
        Write-Host "Getting registration token..." -ForegroundColor Yellow
        $tokenResponse = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/ibuildrun/avyx/actions/runners/registration-token" `
            -Method POST `
            -Headers @{ Authorization = "token $GitHubToken" } `
            -ErrorAction Stop
        
        $registrationToken = $tokenResponse.token
        
        # Configure
        Write-Host "Configuring runner..." -ForegroundColor Yellow
        $runnerName = "avyx-runner-$(Get-Random -Minimum 1000 -Maximum 9999)"
        
        & ".\config.cmd" `
            --url "https://github.com/ibuildrun/avyx" `
            --token $registrationToken `
            --name $runnerName `
            --work "_work" `
            --labels "windows,self-hosted,avyx" `
            --unattended `
            --replace
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Configuration failed" -ForegroundColor Red
            exit 1
        }
        
        # Install service
        Write-Host "Installing Windows Service..." -ForegroundColor Yellow
        & ".\svc.cmd" install
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Service installation failed" -ForegroundColor Red
            exit 1
        }
        
        # Start service
        Write-Host "Starting service..." -ForegroundColor Yellow
        & ".\svc.cmd" start
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Installation Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Runner: $runnerName" -ForegroundColor Cyan
        Write-Host "Path: $InstallPath" -ForegroundColor Cyan
        Write-Host "Status: Running" -ForegroundColor Green
        Write-Host ""
        Write-Host "Check status: https://github.com/ibuildrun/avyx/settings/actions/runners" -ForegroundColor Yellow
    }
    
    "start" {
        Write-Host "Starting runner service..." -ForegroundColor Yellow
        if (Test-Path "$InstallPath\svc.cmd") {
            Set-Location $InstallPath
            & ".\svc.cmd" start
            Write-Host "Service started" -ForegroundColor Green
        } else {
            Write-Host "Error: Runner not found at $InstallPath" -ForegroundColor Red
            exit 1
        }
    }
    
    "stop" {
        Write-Host "Stopping runner service..." -ForegroundColor Yellow
        if (Test-Path "$InstallPath\svc.cmd") {
            Set-Location $InstallPath
            & ".\svc.cmd" stop
            Write-Host "Service stopped" -ForegroundColor Green
        } else {
            Write-Host "Error: Runner not found at $InstallPath" -ForegroundColor Red
            exit 1
        }
    }
    
    "status" {
        Write-Host "Checking runner service status..." -ForegroundColor Yellow
        $service = Get-Service -Name "GitHub Actions Runner" -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "Service Status: $($service.Status)" -ForegroundColor Cyan
            Write-Host "Service Name: $($service.Name)" -ForegroundColor Cyan
            Write-Host "Display Name: $($service.DisplayName)" -ForegroundColor Cyan
        } else {
            Write-Host "Runner service not found" -ForegroundColor Yellow
        }
    }
    
    "uninstall" {
        Write-Host "Uninstalling runner..." -ForegroundColor Yellow
        if (Test-Path "$InstallPath\svc.cmd") {
            Set-Location $InstallPath
            & ".\svc.cmd" uninstall
            Write-Host "Service uninstalled" -ForegroundColor Green
        } else {
            Write-Host "Error: Runner not found at $InstallPath" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
