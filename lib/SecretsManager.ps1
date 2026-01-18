# GitHub Secrets Management Module

. "$PSScriptRoot\GitHub.ps1"
. "$PSScriptRoot\UI.ps1"

function Test-SSHConnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Host,
        [Parameter(Mandatory=$true)]
        [string]$Port,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$true)]
        [string]$Password
    )
    
    Write-Host ""
    Write-Host "Testing SSH connection to ${User}@${Host}:${Port}..." -ForegroundColor Yellow
    
    try {
        # Create temporary script for SSH test
        $testScript = @"
`$password = ConvertTo-SecureString '$Password' -AsPlainText -Force
`$credential = New-Object System.Management.Automation.PSCredential ('$User', `$password)

try {
    `$session = New-PSSession -HostName $Host -Port $Port -UserName $User -SSHTransport -ErrorAction Stop
    if (`$session) {
        Remove-PSSession `$session
        exit 0
    }
} catch {
    # Try using plink if available
    `$plinkTest = echo y | plink -P $Port $User@$Host -pw '$Password' 'echo test' 2>&1
    if (`$LASTEXITCODE -eq 0) {
        exit 0
    }
    exit 1
}
exit 1
"@
        
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $testScript | Set-Content $tempFile
        
        $result = & powershell -File $tempFile
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$([char]0x2713) SSH connection successful!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "$([char]0x2717) SSH connection failed" -ForegroundColor Red
            Write-Host "Please check:" -ForegroundColor Yellow
            Write-Host "  - Host IP/hostname is correct" -ForegroundColor Gray
            Write-Host "  - Port is correct (default: 22)" -ForegroundColor Gray
            Write-Host "  - Username is correct" -ForegroundColor Gray
            Write-Host "  - Password is correct" -ForegroundColor Gray
            Write-Host "  - SSH server is running" -ForegroundColor Gray
            return $false
        }
    } catch {
        Write-Host "$([char]0x2717) Error testing connection: $_" -ForegroundColor Red
        return $false
    }
}

function Setup-SSHKeys {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Host,
        [Parameter(Mandatory=$true)]
        [string]$Port,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$true)]
        [string]$Password,
        [Parameter(Mandatory=$true)]
        [string]$Repository
    )
    
    Write-Host ""
    Write-Host "=== SSH Key Setup ===" -ForegroundColor Cyan
    
    $sshDir = "$env:USERPROFILE\.ssh"
    $keyPath = "$sshDir\github_runner_key"
    $pubKeyPath = "$keyPath.pub"
    
    # Create .ssh directory if not exists
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }
    
    # Generate SSH key if not exists
    if (-not (Test-Path $keyPath)) {
        Write-Host "Generating SSH key pair..." -ForegroundColor Yellow
        ssh-keygen -t rsa -b 4096 -f $keyPath -N '""' -C "github-runner@$env:COMPUTERNAME" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$([char]0x2713) SSH key pair generated" -ForegroundColor Green
        } else {
            Write-Host "$([char]0x2717) Failed to generate SSH key" -ForegroundColor Red
            return
        }
    } else {
        Write-Host "Using existing SSH key: $keyPath" -ForegroundColor Cyan
    }
    
    # Read public key
    if (Test-Path $pubKeyPath) {
        $publicKey = Get-Content $pubKeyPath -Raw
        
        Write-Host ""
        Write-Host "Copying public key to server..." -ForegroundColor Yellow
        
        # Create script to copy key
        $copyScript = @"
`$password = ConvertTo-SecureString '$Password' -AsPlainText -Force
`$publicKey = @'
$publicKey
'@

# Try using ssh-copy-id equivalent
`$command = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '`$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

try {
    echo y | plink -P $Port $User@$Host -pw '$Password' `$command 2>&1 | Out-Null
    if (`$LASTEXITCODE -eq 0) {
        exit 0
    }
} catch {}
exit 1
"@
        
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $copyScript | Set-Content $tempFile
        
        $result = & powershell -File $tempFile
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$([char]0x2713) Public key copied to server" -ForegroundColor Green
            
            # Read private key and save to GitHub secret
            Write-Host ""
            Write-Host "Saving private key to GitHub secret..." -ForegroundColor Yellow
            $privateKey = Get-Content $keyPath -Raw
            
            if (Set-GitHubSecretViaCLI -Repository $Repository -SecretName "SSH_PRIVATE_KEY" -SecretValue $privateKey) {
                Write-Host "$([char]0x2713) SSH_PRIVATE_KEY configured" -ForegroundColor Green
                Write-Host ""
                Write-Host "SSH key setup complete!" -ForegroundColor Green
                Write-Host "You can now use passwordless SSH authentication" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Note: You may want to remove SSH_PASSWORD secret if using keys only" -ForegroundColor Yellow
            } else {
                Write-Host "$([char]0x2717) Failed to save private key to GitHub" -ForegroundColor Red
            }
        } else {
            Write-Host "$([char]0x2717) Failed to copy public key to server" -ForegroundColor Red
            Write-Host "You can manually copy the key:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Public key location: $pubKeyPath" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "On the server, run:" -ForegroundColor Yellow
            Write-Host "  mkdir -p ~/.ssh" -ForegroundColor Gray
            Write-Host "  echo '$publicKey' >> ~/.ssh/authorized_keys" -ForegroundColor Gray
            Write-Host "  chmod 600 ~/.ssh/authorized_keys" -ForegroundColor Gray
        }
    } else {
        Write-Host "$([char]0x2717) Public key file not found" -ForegroundColor Red
    }
}

function Get-TelegramChatId {
    Write-Host ""
    Write-Host "=== How to get Telegram Chat ID ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Open @userinfobot in Telegram" -ForegroundColor Yellow
    Write-Host "2. Send /start command" -ForegroundColor Yellow
    Write-Host "3. Copy your ID (number, e.g.: 123456789)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or for a group:" -ForegroundColor Gray
    Write-Host "1. Add @userinfobot to the group" -ForegroundColor Yellow
    Write-Host "2. Group ID starts with minus (e.g.: -100123456789)" -ForegroundColor Yellow
    Write-Host ""
}

function Test-GitHubCLI {
    try {
        $ghVersion = gh --version 2>$null
        return $true
    } catch {
        return $false
    }
}

function Install-GitHubCLI {
    Write-Host ""
    Write-Host "GitHub CLI (gh) is not installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "GitHub CLI is required for automatic secrets configuration." -ForegroundColor Gray
    Write-Host "Install now? (requires winget)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Yes, install via winget" -ForegroundColor White
    Write-Host "2. No, I'll install manually" -ForegroundColor White
    Write-Host "3. Cancel" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Select option (1-3)"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "Installing GitHub CLI..." -ForegroundColor Yellow
            try {
                winget install --id GitHub.cli --silent
                Write-Host "$([char]0x2713) GitHub CLI installed" -ForegroundColor Green
                Write-Host "Restart the script to apply changes" -ForegroundColor Yellow
                return $false
            } catch {
                Write-Host "$([char]0x2717) Installation error: $_" -ForegroundColor Red
                return $false
            }
        }
        "2" {
            Write-Host ""
            Write-Host "Install GitHub CLI manually:" -ForegroundColor Yellow
            Write-Host "https://cli.github.com/" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Or via winget:" -ForegroundColor Gray
            Write-Host "  winget install --id GitHub.cli" -ForegroundColor White
            Write-Host ""
            return $false
        }
        default {
            return $false
        }
    }
}

function Set-GitHubSecretViaCLI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Repository,
        [Parameter(Mandatory=$true)]
        [string]$SecretName,
        [Parameter(Mandatory=$true)]
        [string]$SecretValue
    )
    
    try {
        # Use gh CLI to set secret
        $SecretValue | gh secret set $SecretName --repo $Repository 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            return $true
        } else {
            Write-Host "Error setting secret $SecretName" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Initialize-GitHubCLI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    Write-Host "Authenticating with GitHub CLI..." -ForegroundColor Yellow
    
    try {
        # Temporarily remove GITHUB_TOKEN environment variable to avoid conflicts
        $originalToken = $env:GITHUB_TOKEN
        $env:GITHUB_TOKEN = $null
        
        try {
            # Login using token
            $Token | gh auth login --with-token 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$([char]0x2713) Authentication successful" -ForegroundColor Green
                return $true
            } else {
                Write-Host "$([char]0x2717) Authentication failed" -ForegroundColor Red
                return $false
            }
        } finally {
            # Restore original token
            $env:GITHUB_TOKEN = $originalToken
        }
    } catch {
        Write-Host "$([char]0x2717) Error: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-SecretsConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    if (-not $Config.IsValid()) {
        Write-Host ""
        Write-Host "Error: Configure GitHub token and repository first" -ForegroundColor Red
        Write-Host "Complete options 1 and 2 from the main menu" -ForegroundColor Yellow
        return
    }
    
    # Check if gh CLI is installed
    if (-not (Test-GitHubCLI)) {
        if (-not (Install-GitHubCLI)) {
            return
        }
    }
    
    # Initialize gh CLI with token
    if (-not (Initialize-GitHubCLI -Token $Config.GitHubToken)) {
        Write-Host ""
        Write-Host "Failed to authenticate with GitHub CLI" -ForegroundColor Red
        Write-Host "Check your token and try again" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "=== GitHub Secrets Configuration ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Repository: $($Config.Repository)" -ForegroundColor Green
    Write-Host ""
    Write-Host "The following secrets will be configured:" -ForegroundColor Yellow
    Write-Host "  1. SSH_HOST - server IP address" -ForegroundColor Gray
    Write-Host "  2. SSH_PORT - SSH port (default: 22)" -ForegroundColor Gray
    Write-Host "  3. SSH_USER - SSH username" -ForegroundColor Gray
    Write-Host "  4. SSH_PASSWORD - SSH password" -ForegroundColor Gray
    Write-Host "  5. TELEGRAM_BOT_TOKEN - Telegram bot token" -ForegroundColor Gray
    Write-Host "  6. TELEGRAM_ADMIN_CHAT_ID - your Telegram Chat ID" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    $secretsConfigured = 0
    
    # 1. SSH_HOST
    Write-Host ""
    Write-Host "[1/6] SSH_HOST" -ForegroundColor Cyan
    Write-Host "Enter server IP address or hostname" -ForegroundColor Yellow
    Write-Host "Example: 192.168.1.100 or server.example.com" -ForegroundColor Gray
    $sshHost = Read-Host "Host"
    
    if ([string]::IsNullOrEmpty($sshHost)) {
        Write-Host "Skipped" -ForegroundColor Yellow
    } else {
        Write-Host "Saving SSH_HOST..." -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_HOST" -SecretValue $sshHost) {
            Write-Host "$([char]0x2713) SSH_HOST configured" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # 2. SSH_PORT
    Write-Host ""
    Write-Host "[2/6] SSH_PORT" -ForegroundColor Cyan
    Write-Host "Enter SSH port (press Enter for default 22)" -ForegroundColor Yellow
    $sshPort = Read-Host "Port"
    
    if ([string]::IsNullOrEmpty($sshPort)) {
        $sshPort = "22"
    }
    
    Write-Host "Saving SSH_PORT..." -ForegroundColor Yellow
    if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_PORT" -SecretValue $sshPort) {
        Write-Host "$([char]0x2713) SSH_PORT configured" -ForegroundColor Green
        $secretsConfigured++
    }
    
    # 3. SSH_USER
    Write-Host ""
    Write-Host "[3/6] SSH_USER" -ForegroundColor Cyan
    Write-Host "Enter SSH username" -ForegroundColor Yellow
    Write-Host "Example: root, ubuntu, admin" -ForegroundColor Gray
    $sshUser = Read-Host "Username"
    
    if ([string]::IsNullOrEmpty($sshUser)) {
        Write-Host "Skipped" -ForegroundColor Yellow
    } else {
        Write-Host "Saving SSH_USER..." -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_USER" -SecretValue $sshUser) {
            Write-Host "$([char]0x2713) SSH_USER configured" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # 4. SSH_PASSWORD
    Write-Host ""
    Write-Host "[4/6] SSH_PASSWORD" -ForegroundColor Cyan
    Write-Host "Enter SSH password" -ForegroundColor Yellow
    $sshPassword = Read-Host "Password" -MaskInput
    
    if ([string]::IsNullOrEmpty($sshPassword)) {
        Write-Host "Skipped" -ForegroundColor Yellow
    } else {
        Write-Host "Saving SSH_PASSWORD..." -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_PASSWORD" -SecretValue $sshPassword) {
            Write-Host "$([char]0x2713) SSH_PASSWORD configured" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # Test SSH connection if all SSH parameters provided
    if (-not [string]::IsNullOrEmpty($sshHost) -and -not [string]::IsNullOrEmpty($sshUser) -and -not [string]::IsNullOrEmpty($sshPassword)) {
        Write-Host ""
        Write-Host "=== SSH Connection Test ===" -ForegroundColor Cyan
        $testConnection = Read-Host "Test SSH connection now? (y/N)"
        
        if ($testConnection -eq "y" -or $testConnection -eq "Y") {
            if (Test-SSHConnection -Host $sshHost -Port $sshPort -User $sshUser -Password $sshPassword) {
                Write-Host ""
                Write-Host "=== SSH Key Setup ===" -ForegroundColor Cyan
                Write-Host "Would you like to set up passwordless SSH access using SSH keys?" -ForegroundColor Yellow
                Write-Host "This will:" -ForegroundColor Gray
                Write-Host "  1. Generate SSH key pair (if not exists)" -ForegroundColor Gray
                Write-Host "  2. Copy public key to server" -ForegroundColor Gray
                Write-Host "  3. Configure SSH_PRIVATE_KEY secret for GitHub Actions" -ForegroundColor Gray
                Write-Host ""
                
                $setupKeys = Read-Host "Setup SSH keys? (y/N)"
                if ($setupKeys -eq "y" -or $setupKeys -eq "Y") {
                    Setup-SSHKeys -Host $sshHost -Port $sshPort -User $sshUser -Password $sshPassword -Repository $Config.Repository
                }
            }
        }
    }
    
    # 5. TELEGRAM_BOT_TOKEN
    Write-Host ""
    Write-Host "[5/6] TELEGRAM_BOT_TOKEN" -ForegroundColor Cyan
    Write-Host "Enter Telegram bot token (get from @BotFather)" -ForegroundColor Yellow
    Write-Host "Format: 1234567890:ABCdefGHIjklMNOpqrsTUVwxyz" -ForegroundColor Gray
    $botToken = Read-Host "Token" -MaskInput
    
    if ([string]::IsNullOrEmpty($botToken)) {
        Write-Host "Skipped" -ForegroundColor Yellow
    } else {
        Write-Host "Saving TELEGRAM_BOT_TOKEN..." -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "TELEGRAM_BOT_TOKEN" -SecretValue $botToken) {
            Write-Host "$([char]0x2713) TELEGRAM_BOT_TOKEN configured" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # 6. TELEGRAM_ADMIN_CHAT_ID
    Write-Host ""
    Write-Host "[6/6] TELEGRAM_ADMIN_CHAT_ID" -ForegroundColor Cyan
    Get-TelegramChatId
    $chatId = Read-Host "Chat ID"
    
    if ([string]::IsNullOrEmpty($chatId)) {
        Write-Host "Skipped" -ForegroundColor Yellow
    } else {
        Write-Host "Saving TELEGRAM_ADMIN_CHAT_ID..." -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "TELEGRAM_ADMIN_CHAT_ID" -SecretValue $chatId) {
            Write-Host "$([char]0x2713) TELEGRAM_ADMIN_CHAT_ID configured" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Configuration complete!" -ForegroundColor Green
    Write-Host "Configured secrets: $secretsConfigured/6" -ForegroundColor Cyan
    Write-Host ""
    
    if ($secretsConfigured -gt 0) {
        Write-Host "Secrets are now available in GitHub Actions workflows" -ForegroundColor Green
        Write-Host "Repository: https://github.com/$($Config.Repository)/settings/secrets/actions" -ForegroundColor Cyan
    }
}

function Show-ConfiguredSecrets {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    if (-not $Config.IsValid()) {
        Write-Host ""
        Write-Host "Error: Configure GitHub token and repository first" -ForegroundColor Red
        return
    }
    
    if (-not (Test-GitHubCLI)) {
        Write-Host ""
        Write-Host "GitHub CLI is not installed" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "=== Configured Secrets ===" -ForegroundColor Cyan
    Write-Host "Repository: $($Config.Repository)" -ForegroundColor Green
    Write-Host ""
    
    try {
        $secretsList = gh secret list --repo $Config.Repository 2>&1
        
        $requiredSecrets = @(
            "SSH_HOST",
            "SSH_PORT", 
            "SSH_USER",
            "SSH_PASSWORD",
            "SSH_PRIVATE_KEY",
            "TELEGRAM_BOT_TOKEN",
            "TELEGRAM_ADMIN_CHAT_ID"
        )
        
        Write-Host "Required secrets status:" -ForegroundColor Yellow
        foreach ($secretName in $requiredSecrets) {
            if ($secretsList -match $secretName) {
                Write-Host "  $([char]0x2713) $secretName" -ForegroundColor Green
            } else {
                Write-Host "  $([char]0x2717) $secretName (not configured)" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "Full secrets list:" -ForegroundColor Gray
        Write-Host $secretsList -ForegroundColor Gray
        
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}
