# Docker Container Management Module
# Manages self-hosted runners in Docker containers

class DockerRunnerConfig {
    [string]$ContainerId
    [string]$Repository
    [string]$RunnerName
    [string]$ImageTag
    [datetime]$Created
    [string]$Status
    
    DockerRunnerConfig() {
        $this.Created = Get-Date
        $this.Status = "Unknown"
    }
}

function Test-DockerInstalled {
    try {
        $null = docker --version 2>&1
        return $true
    } catch {
        Write-Host "Docker is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        return $false
    }
}

function Test-DockerRunning {
    try {
        $null = docker ps 2>&1
        return $true
    } catch {
        Write-Host "Docker daemon is not running" -ForegroundColor Red
        Write-Host "Start Docker Desktop and try again" -ForegroundColor Yellow
        return $false
    }
}

function New-DockerRunnerImage {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ImageTag = "github-runner:latest"
    )
    
    Write-Host "Creating Docker image for GitHub runner..." -ForegroundColor Cyan
    
    $dockerfile = @"
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    libicu-dev \
    sudo \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    sshpass \
    lftp \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Install PHP 8.3
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
    php8.3-cli \
    php8.3-common \
    php8.3-curl \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-mysql \
    php8.3-pgsql \
    php8.3-sqlite3 \
    php8.3-bcmath \
    php8.3-gd \
    php8.3-intl \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create runner user
RUN useradd -m -s /bin/bash runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/runner

# Download and extract GitHub Actions runner
ARG RUNNER_VERSION="2.311.0"
RUN curl -o actions-runner-linux-x64.tar.gz -L \
    https://github.com/actions/runner/releases/download/v`${RUNNER_VERSION}/actions-runner-linux-x64-`${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner-linux-x64.tar.gz && \
    rm actions-runner-linux-x64.tar.gz && \
    chown -R runner:runner /home/runner

USER runner

# Entry point script
COPY entrypoint.sh /home/runner/entrypoint.sh
RUN sudo chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["/home/runner/entrypoint.sh"]
"@

    $entrypoint = @"
#!/bin/bash
set -e

if [ -z "`$GITHUB_TOKEN" ] || [ -z "`$GITHUB_REPOSITORY" ]; then
    echo "Error: GITHUB_TOKEN and GITHUB_REPOSITORY must be set"
    exit 1
fi

# Get registration token
REGISTRATION_TOKEN=`$(curl -s -X POST \
    -H "Authorization: token `$GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/`$GITHUB_REPOSITORY/actions/runners/registration-token" \
    | jq -r .token)

if [ -z "`$REGISTRATION_TOKEN" ] || [ "`$REGISTRATION_TOKEN" = "null" ]; then
    echo "Error: Failed to get registration token"
    exit 1
fi

# Configure runner
./config.sh --url "https://github.com/`$GITHUB_REPOSITORY" \
    --token "`$REGISTRATION_TOKEN" \
    --name "`${RUNNER_NAME:-docker-runner-`$(hostname)}" \
    --work _work \
    --labels docker,self-hosted \
    --unattended \
    --replace

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "`$REGISTRATION_TOKEN"
}

trap cleanup EXIT

# Start runner
./run.sh
"@

    # Create temporary directory for build context
    $tempDir = Join-Path $env:TEMP "github-runner-docker-$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Write Dockerfile with UTF8 encoding
        $dockerfile | Set-Content -Path "$tempDir\Dockerfile" -Encoding UTF8
        
        # For entrypoint.sh, convert to Unix line endings (LF only) and write as bytes
        $entrypointUnix = $entrypoint -replace "`r`n", "`n"
        $entrypointBytes = [System.Text.Encoding]::UTF8.GetBytes($entrypointUnix)
        $entrypointPath = Join-Path $tempDir "entrypoint.sh"
        [System.IO.File]::WriteAllBytes($entrypointPath, $entrypointBytes)
        
        # Build image
        Write-Host "Building Docker image..." -ForegroundColor Cyan
        docker build -t $ImageTag $tempDir
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$([char]0x2713) Docker image created successfully: $ImageTag" -ForegroundColor Green
            return $true
        } else {
            Write-Host "$([char]0x2717) Failed to build Docker image" -ForegroundColor Red
            return $false
        }
    } finally {
        # Cleanup
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Start-DockerRunner {
    param(
        [Parameter(Mandatory=$true)]
        [RunnerConfig]$Config,
        
        [Parameter(Mandatory=$false)]
        [string]$RunnerName,
        
        [Parameter(Mandatory=$false)]
        [string]$ImageTag = "github-runner:latest",
        
        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalEnvVars = @{}
    )
    
    if (-not (Test-DockerInstalled)) { return $null }
    if (-not (Test-DockerRunning)) { return $null }
    
    if (-not $Config.IsValid()) {
        Write-Host "Configuration is not valid. Please configure token and repository first." -ForegroundColor Red
        return $null
    }
    
    # Check if image exists
    $imageExists = docker images -q $ImageTag 2>$null
    if (-not $imageExists) {
        Write-Host "Image $ImageTag not found. Creating..." -ForegroundColor Yellow
        if (-not (New-DockerRunnerImage -ImageTag $ImageTag)) {
            return $null
        }
    }
    
    # Generate runner name based on repository if not provided
    if (-not $RunnerName) {
        $repoName = $Config.Repository -replace '.*/([^/]+)$', '$1'  # Extract repo name from owner/repo
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $RunnerName = "$repoName-runner-$timestamp"
    }
    
    Write-Host ""
    Write-Host "Starting Docker runner container..." -ForegroundColor Cyan
    Write-Host "Repository: $($Config.Repository)" -ForegroundColor Green
    Write-Host "Runner name: $RunnerName" -ForegroundColor Green
    Write-Host "Image: $ImageTag" -ForegroundColor Gray
    Write-Host ""
    
    # Build environment variables
    $envArgs = @(
        "-e", "GITHUB_TOKEN=$($Config.GitHubToken)",
        "-e", "GITHUB_REPOSITORY=$($Config.Repository)",
        "-e", "RUNNER_NAME=$RunnerName"
    )
    
    foreach ($key in $AdditionalEnvVars.Keys) {
        $envArgs += "-e"
        $envArgs += "$key=$($AdditionalEnvVars[$key])"
    }
    
    # Start container
    Write-Host "Creating container..." -ForegroundColor Yellow
    $containerId = docker run -d --name $RunnerName @envArgs $ImageTag
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Container started successfully" -ForegroundColor Green
        Write-Host "Container ID: $containerId" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Waiting for runner to register with GitHub..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Save container info
        $dockerRunner = [DockerRunnerConfig]::new()
        $dockerRunner.ContainerId = $containerId
        $dockerRunner.Repository = $Config.Repository
        $dockerRunner.RunnerName = $RunnerName
        $dockerRunner.ImageTag = $ImageTag
        $dockerRunner.Status = "Running"
        
        $Config.AddDockerRunner($dockerRunner)
        
        # Send Telegram notification if configured
        $telegramConfig = $Config.GetTelegramConfig()
        if ($telegramConfig -and $telegramConfig.Enabled) {
            Send-TelegramNotification `
                -Config $telegramConfig `
                -Type "Success" `
                -Title "Docker Runner Deployed" `
                -Message "Repository: $($Config.Repository)`nRunner: $RunnerName`nContainer: $($containerId.Substring(0,12))"
        }
        
        Write-Host "$([char]0x2713) Runner should appear in GitHub within 1-2 minutes" -ForegroundColor Green
        Write-Host "Check: https://github.com/$($Config.Repository)/settings/actions/runners" -ForegroundColor Cyan
        Write-Host ""
        
        return $dockerRunner
    } else {
        Write-Host "$([char]0x2717) Failed to start container" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Check Docker logs: docker logs $RunnerName" -ForegroundColor Gray
        Write-Host "  2. Verify token has 'repo' and 'workflow' scopes" -ForegroundColor Gray
        Write-Host "  3. Ensure repository exists: $($Config.Repository)" -ForegroundColor Gray
        Write-Host ""
        return $null
    }
}

function Stop-DockerRunner {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerIdOrName
    )
    
    if (-not (Test-DockerInstalled)) { return $false }
    if (-not (Test-DockerRunning)) { return $false }
    
    Write-Host "Stopping container $ContainerIdOrName..." -ForegroundColor Cyan
    
    docker stop $ContainerIdOrName 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Container stopped" -ForegroundColor Green
        return $true
    } else {
        Write-Host "$([char]0x2717) Failed to stop container" -ForegroundColor Red
        return $false
    }
}

function Remove-DockerRunner {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerIdOrName,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    
    if (-not (Test-DockerInstalled)) { return $false }
    if (-not (Test-DockerRunning)) { return $false }
    
    Write-Host "Removing container $ContainerIdOrName..." -ForegroundColor Cyan
    
    $args = @("rm")
    if ($Force) { $args += "-f" }
    $args += $ContainerIdOrName
    
    docker @args 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Container removed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "$([char]0x2717) Failed to remove container" -ForegroundColor Red
        return $false
    }
}

function Get-DockerRunners {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$All
    )
    
    if (-not (Test-DockerInstalled)) { return @() }
    if (-not (Test-DockerRunning)) { return @() }
    
    $args = @("ps", "--format", "{{.ID}}|{{.Names}}|{{.Status}}|{{.Image}}")
    if ($All) { $args += "-a" }
    
    $containers = docker @args 2>&1
    
    $runners = @()
    foreach ($line in $containers) {
        if ($line -match '^([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)$') {
            $runners += [PSCustomObject]@{
                ContainerId = $matches[1]
                Name = $matches[2]
                Status = $matches[3]
                Image = $matches[4]
            }
        }
    }
    
    return $runners
}

function Show-DockerRunnerLogs {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerIdOrName,
        
        [Parameter(Mandatory=$false)]
        [int]$Lines = 50
    )
    
    if (-not (Test-DockerInstalled)) { return }
    if (-not (Test-DockerRunning)) { return }
    
    Write-Host ""
    Write-Host "=== Container Logs: $ContainerIdOrName ===" -ForegroundColor Cyan
    Write-Host ""
    
    docker logs --tail $Lines $ContainerIdOrName
}

function Invoke-DockerManagement {
    param(
        [Parameter(Mandatory=$true)]
        [RunnerConfig]$Config
    )
    
    do {
        Write-Host ""
        Write-Host "=== Docker Container Management ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Build runner image"
        Write-Host "2. Start new runner container"
        Write-Host "3. List running containers"
        Write-Host "4. Stop container"
        Write-Host "5. Remove container"
        Write-Host "6. View container logs"
        Write-Host "7. Bulk deploy (multiple containers)"
        Write-Host "0. Back"
        Write-Host ""
        
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            "1" {
                $imageTag = Read-Host "Enter image tag (default: github-runner:latest)"
                if ([string]::IsNullOrEmpty($imageTag)) {
                    $imageTag = "github-runner:latest"
                }
                New-DockerRunnerImage -ImageTag $imageTag
            }
            "2" {
                $runnerName = Read-Host "Enter runner name (leave empty for auto-generated)"
                $imageTag = Read-Host "Enter image tag (default: github-runner:latest)"
                if ([string]::IsNullOrEmpty($imageTag)) {
                    $imageTag = "github-runner:latest"
                }
                
                $runner = Start-DockerRunner -Config $Config -RunnerName $runnerName -ImageTag $imageTag
                
                if ($runner) {
                    # Send Telegram notification
                    $telegramConfig = $Config.GetTelegramConfig()
                    if ($telegramConfig.Enabled) {
                        $message = "Docker Runner Started`n`nRepository: $($Config.Repository)`nRunner: $($runner.RunnerName)`nContainer: $($runner.ContainerId.Substring(0,12))"
                        Send-TelegramNotification -TelegramConfig (ConvertTo-TelegramConfigObject $telegramConfig) -Message $message -Type "Success"
                    }
                }
            }
            "3" {
                $runners = Get-DockerRunners -All
                Write-Host ""
                Write-Host "=== Docker Runners ===" -ForegroundColor Cyan
                Write-Host ""
                
                if ($runners.Count -eq 0) {
                    Write-Host "No containers found" -ForegroundColor Yellow
                } else {
                    # Get saved runner configs to show repository info
                    $savedRunners = $Config.GetDockerRunners()
                    
                    # Enhance runner info with repository
                    $enhancedRunners = $runners | ForEach-Object {
                        $container = $_
                        $saved = $savedRunners | Where-Object { $_.ContainerId -like "$($container.ContainerId)*" -or $_.RunnerName -eq $container.Name }
                        
                        [PSCustomObject]@{
                            ContainerId = $container.ContainerId.Substring(0, [Math]::Min(12, $container.ContainerId.Length))
                            Name = $container.Name
                            Repository = if ($saved) { $saved.Repository } else { "N/A" }
                            Status = $container.Status
                            Image = $container.Image
                        }
                    }
                    
                    $enhancedRunners | Format-Table -Property ContainerId, Name, Repository, Status, Image -AutoSize
                    
                    Write-Host ""
                    Write-Host "Tip: Runner names now include repository (e.g., 'avyx-runner-...')" -ForegroundColor Gray
                }
            }
            "4" {
                $containerName = Read-Host "Enter container ID or name"
                Stop-DockerRunner -ContainerIdOrName $containerName
            }
            "5" {
                $containerName = Read-Host "Enter container ID or name"
                $force = Read-Host "Force remove? (y/n)"
                
                if ($force -eq 'y') {
                    Remove-DockerRunner -ContainerIdOrName $containerName -Force
                } else {
                    Remove-DockerRunner -ContainerIdOrName $containerName
                }
            }
            "6" {
                $containerName = Read-Host "Enter container ID or name"
                $lines = Read-Host "Number of lines (default: 50)"
                if ([string]::IsNullOrEmpty($lines)) { $lines = 50 }
                
                Show-DockerRunnerLogs -ContainerIdOrName $containerName -Lines $lines
            }
            "7" {
                $count = [int](Read-Host "How many containers to deploy?")
                $imageTag = Read-Host "Enter image tag (default: github-runner:latest)"
                if ([string]::IsNullOrEmpty($imageTag)) {
                    $imageTag = "github-runner:latest"
                }
                
                # Extract repo name for container naming
                $repoName = $Config.Repository -replace '.*/([^/]+)$', '$1'
                
                Write-Host ""
                Write-Host "Deploying $count containers for repository: $($Config.Repository)..." -ForegroundColor Cyan
                Write-Host ""
                
                for ($i = 1; $i -le $count; $i++) {
                    $runnerName = "$repoName-runner-$i-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    Write-Host "[$i/$count] Starting $runnerName..." -ForegroundColor Gray
                    Start-DockerRunner -Config $Config -RunnerName $runnerName -ImageTag $imageTag | Out-Null
                    Start-Sleep -Seconds 2
                }
                
                Write-Host ""
                Write-Host "$([char]0x2713) Bulk deployment completed!" -ForegroundColor Green
                
                # Send Telegram notification
                $telegramConfig = $Config.GetTelegramConfig()
                if ($telegramConfig.Enabled) {
                    $message = "Bulk Deployment Completed`n`nRepository: $($Config.Repository)`nContainers deployed: $count"
                    Send-TelegramNotification -TelegramConfig (ConvertTo-TelegramConfigObject $telegramConfig) -Message $message -Type "Success"
                }
            }
        }
        
        if ($choice -ne "0") {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($choice -ne "0")
}
