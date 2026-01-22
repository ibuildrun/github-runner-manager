# GitHub Secrets Management Module

. "$PSScriptRoot\GitHub.ps1"
. "$PSScriptRoot\Localization.ps1"

function Test-SSHConnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$HostName,
        [Parameter(Mandatory=$true)]
        [string]$Port,
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [string]$Password
    )
    
    Write-Host ""
    Write-Host (L "secrets_testing_ssh" $UserName $HostName $Port) -ForegroundColor Yellow
    
    try {
        # First, check if port is accessible
        $testSocket = New-Object System.Net.Sockets.TcpClient
        try {
            $testSocket.Connect($HostName, $Port)
            $testSocket.Close()
            Write-Host "$([char]0x2713) $(L 'secrets_ssh_port_ok')" -ForegroundColor Green
        } catch {
            Write-Host "$([char]0x2717) $(L 'secrets_ssh_port_fail')" -ForegroundColor Red
            Write-Host (L "secrets_check_list") -ForegroundColor Yellow
            Write-Host "  - $(L 'secrets_check_host' $HostName)" -ForegroundColor Gray
            Write-Host "  - $(L 'secrets_check_port' $Port)" -ForegroundColor Gray
            Write-Host "  - $(L 'secrets_check_server')" -ForegroundColor Gray
            Write-Host "  - $(L 'secrets_check_firewall')" -ForegroundColor Gray
            return $false
        }
        
        # Check if SSH keys are already configured
        Write-Host (L "secrets_checking_keys") -ForegroundColor Yellow
        $sshDir = "$env:USERPROFILE\.ssh"
        $knownHostsFile = "$sshDir\known_hosts"
        
        # Try simple SSH command without password (using existing keys if any)
        $testCommand = "ssh -o BatchMode=yes -o ConnectTimeout=5 -p $Port ${UserName}@${HostName} `"echo test`" 2>&1"
        $result = cmd /c $testCommand
        
        if ($LASTEXITCODE -eq 0 -or $result -match "test") {
            Write-Host "$([char]0x2713) $(L 'secrets_ssh_success_keys')" -ForegroundColor Green
            Write-Host ""
            Write-Host (L "secrets_note_keys_exist") -ForegroundColor Cyan
            Write-Host (L "secrets_password_not_needed") -ForegroundColor Cyan
            return $true
        }
        
        Write-Host ""
        Write-Host (L "secrets_auto_test_unreliable") -ForegroundColor Yellow
        Write-Host ""
        Write-Host (L "secrets_verify_manually") -ForegroundColor Cyan
        Write-Host "  $(L 'secrets_run_command' $UserName $HostName)" -ForegroundColor White
        Write-Host ""
        
        $manualTest = Read-Host (L "secrets_can_connect")
        
        if ($manualTest -eq "y" -or $manualTest -eq "Y") {
            Write-Host "$([char]0x2713) $(L 'secrets_manual_verify_ok')" -ForegroundColor Green
            Write-Host (L "secrets_creds_saved") -ForegroundColor Cyan
            return $true
        } else {
            Write-Host "$([char]0x2717) $(L 'secrets_verify_creds')" -ForegroundColor Red
            Write-Host ""
            Write-Host (L "secrets_check") -ForegroundColor Yellow
            Write-Host "  - $(L 'secrets_host' $HostName)" -ForegroundColor Gray
            Write-Host "  - $(L 'secrets_port' $Port)" -ForegroundColor Gray
            Write-Host "  - $(L 'secrets_username' $UserName)" -ForegroundColor Gray
            Write-Host "  - $(L 'secrets_password_hidden')" -ForegroundColor Gray
            return $false
        }
        
    } catch {
        Write-Host "$([char]0x2717) $(L 'secrets_error_testing' $_)" -ForegroundColor Red
        Write-Host ""
        Write-Host (L "secrets_note_limited") -ForegroundColor Yellow
        Write-Host (L "secrets_if_manual_ok" $UserName $HostName) -ForegroundColor Cyan
        return $false
    }
}

function Setup-SSHKeys {
    param(
        [Parameter(Mandatory=$true)]
        [string]$HostName,
        [Parameter(Mandatory=$true)]
        [string]$Port,
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [string]$Password,
        [Parameter(Mandatory=$true)]
        [string]$Repository
    )
    
    Write-Host ""
    Write-Host (L "secrets_ssh_setup_title") -ForegroundColor Cyan
    
    $sshDir = "$env:USERPROFILE\.ssh"
    $keyPath = "$sshDir\github_runner_key"
    $pubKeyPath = "$keyPath.pub"
    
    # Create .ssh directory if not exists
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }
    
    # Generate SSH key if not exists
    if (-not (Test-Path $keyPath)) {
        Write-Host (L "secrets_generating_key") -ForegroundColor Yellow
        ssh-keygen -t rsa -b 4096 -f $keyPath -N '""' -C "github-runner@$env:COMPUTERNAME" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$([char]0x2713) $(L 'secrets_key_generated')" -ForegroundColor Green
        } else {
            Write-Host "$([char]0x2717) $(L 'secrets_key_gen_failed')" -ForegroundColor Red
            return
        }
    } else {
        Write-Host (L "secrets_using_existing" $keyPath) -ForegroundColor Cyan
    }
    
    # Read public key
    if (Test-Path $pubKeyPath) {
        $publicKey = Get-Content $pubKeyPath -Raw
        
        Write-Host ""
        Write-Host (L "secrets_copying_key") -ForegroundColor Yellow
        
        # Create script to copy key
        $copyScript = @"
`$password = ConvertTo-SecureString '$Password' -AsPlainText -Force
`$publicKey = @'
$publicKey
'@

# Try using ssh-copy-id equivalent
`$command = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '`$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

try {
    echo y | plink -P $Port $UserName@$HostName -pw '$Password' `$command 2>&1 | Out-Null
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
            Write-Host "$([char]0x2713) $(L 'secrets_key_copied')" -ForegroundColor Green
            
            # Read private key and save to GitHub secret
            Write-Host ""
            Write-Host (L "secrets_saving_private") -ForegroundColor Yellow
            $privateKey = Get-Content $keyPath -Raw
            
            if (Set-GitHubSecretViaCLI -Repository $Repository -SecretName "SSH_PRIVATE_KEY" -SecretValue $privateKey) {
                Write-Host "$([char]0x2713) $(L 'secrets_private_key_ok')" -ForegroundColor Green
                Write-Host ""
                Write-Host (L "secrets_setup_complete") -ForegroundColor Green
                Write-Host (L "secrets_passwordless") -ForegroundColor Cyan
                Write-Host ""
                Write-Host (L "secrets_note_remove_pass") -ForegroundColor Yellow
            } else {
                Write-Host "$([char]0x2717) $(L 'secrets_key_gen_failed')" -ForegroundColor Red
            }
        } else {
            Write-Host "$([char]0x2717) $(L 'secrets_key_copy_failed')" -ForegroundColor Red
            Write-Host (L "secrets_manual_copy") -ForegroundColor Yellow
            Write-Host ""
            Write-Host (L "secrets_pubkey_location" $pubKeyPath) -ForegroundColor Cyan
            Write-Host ""
            Write-Host (L "secrets_on_server_run") -ForegroundColor Yellow
            Write-Host "  mkdir -p ~/.ssh" -ForegroundColor Gray
            Write-Host "  echo '$publicKey' >> ~/.ssh/authorized_keys" -ForegroundColor Gray
            Write-Host "  chmod 600 ~/.ssh/authorized_keys" -ForegroundColor Gray
        }
    } else {
        Write-Host "$([char]0x2717) $(L 'secrets_pubkey_not_found')" -ForegroundColor Red
    }
}

function Get-TelegramChatId {
    Write-Host ""
    Write-Host (L "secrets_chatid_title") -ForegroundColor Cyan
    Write-Host ""
    Write-Host (L "secrets_chatid_step1") -ForegroundColor Yellow
    Write-Host (L "secrets_chatid_step2") -ForegroundColor Yellow
    Write-Host (L "secrets_chatid_step3") -ForegroundColor Yellow
    Write-Host ""
    Write-Host (L "secrets_chatid_group") -ForegroundColor Gray
    Write-Host (L "secrets_chatid_group1") -ForegroundColor Yellow
    Write-Host (L "secrets_chatid_group2") -ForegroundColor Yellow
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
    Write-Host (L "secrets_gh_not_installed") -ForegroundColor Yellow
    Write-Host ""
    Write-Host (L "secrets_gh_required") -ForegroundColor Gray
    Write-Host (L "secrets_install_now") -ForegroundColor Yellow
    Write-Host ""
    Write-Host (L "secrets_install_yes") -ForegroundColor White
    Write-Host (L "secrets_install_manual") -ForegroundColor White
    Write-Host (L "secrets_install_cancel") -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host (L "secrets_select_option")
    
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host (L "secrets_installing_gh") -ForegroundColor Yellow
            try {
                winget install --id GitHub.cli --silent
                Write-Host "$([char]0x2713) $(L 'secrets_gh_installed')" -ForegroundColor Green
                Write-Host (L "secrets_restart_script") -ForegroundColor Yellow
                return $false
            } catch {
                Write-Host "$([char]0x2717) $(L 'secrets_install_error' $_)" -ForegroundColor Red
                return $false
            }
        }
        "2" {
            Write-Host ""
            Write-Host (L "secrets_install_manual_msg") -ForegroundColor Yellow
            Write-Host "https://cli.github.com/" -ForegroundColor Cyan
            Write-Host ""
            Write-Host (L "secrets_or_via_winget") -ForegroundColor Gray
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
    
    Write-Host (L "secrets_authenticating") -ForegroundColor Yellow
    
    try {
        # Temporarily remove GITHUB_TOKEN environment variable to avoid conflicts
        $originalToken = $env:GITHUB_TOKEN
        $env:GITHUB_TOKEN = $null
        
        try {
            # Login using token
            $Token | gh auth login --with-token 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$([char]0x2713) $(L 'secrets_auth_success')" -ForegroundColor Green
                return $true
            } else {
                Write-Host "$([char]0x2717) $(L 'secrets_auth_failed')" -ForegroundColor Red
                return $false
            }
        } finally {
            # Restore original token
            $env:GITHUB_TOKEN = $originalToken
        }
    } catch {
        Write-Host "$([char]0x2717) $(L 'secrets_error' $_)" -ForegroundColor Red
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
        Write-Host (L "secrets_error_config_first") -ForegroundColor Red
        Write-Host (L "secrets_complete_options") -ForegroundColor Yellow
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
        Write-Host (L "secrets_gh_auth_failed") -ForegroundColor Red
        Write-Host (L "secrets_check_token") -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host (L "secrets_config_title") -ForegroundColor Cyan
    Write-Host ""
    Write-Host (L "secrets_repository" $Config.Repository) -ForegroundColor Green
    Write-Host ""
    Write-Host (L "secrets_will_configure") -ForegroundColor Yellow
    Write-Host "  $(L 'secrets_ssh_host_desc')" -ForegroundColor Gray
    Write-Host "  $(L 'secrets_ssh_port_desc')" -ForegroundColor Gray
    Write-Host "  $(L 'secrets_ssh_user_desc')" -ForegroundColor Gray
    Write-Host "  $(L 'secrets_ssh_pass_desc')" -ForegroundColor Gray
    Write-Host "  $(L 'secrets_tg_token_desc')" -ForegroundColor Gray
    Write-Host "  $(L 'secrets_tg_chat_desc')" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host (L "secrets_continue")
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host (L "secrets_cancelled") -ForegroundColor Yellow
        return
    }
    
    $secretsConfigured = 0
    
    # 1. SSH_HOST
    Write-Host ""
    Write-Host (L "secrets_step_ssh_host") -ForegroundColor Cyan
    Write-Host (L "secrets_enter_host") -ForegroundColor Yellow
    Write-Host (L "secrets_example_host") -ForegroundColor Gray
    $sshHost = Read-Host (L "secrets_host_label")
    
    if ([string]::IsNullOrEmpty($sshHost)) {
        Write-Host (L "secrets_skipped") -ForegroundColor Yellow
    } else {
        Write-Host (L "secrets_saving" "SSH_HOST") -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_HOST" -SecretValue $sshHost) {
            Write-Host "$([char]0x2713) $(L 'secrets_configured' 'SSH_HOST')" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # 2. SSH_PORT
    Write-Host ""
    Write-Host (L "secrets_step_ssh_port") -ForegroundColor Cyan
    Write-Host (L "secrets_enter_port") -ForegroundColor Yellow
    $sshPort = Read-Host (L "secrets_port_label")
    
    if ([string]::IsNullOrEmpty($sshPort)) {
        $sshPort = "22"
    }
    
    Write-Host (L "secrets_saving" "SSH_PORT") -ForegroundColor Yellow
    if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_PORT" -SecretValue $sshPort) {
        Write-Host "$([char]0x2713) $(L 'secrets_configured' 'SSH_PORT')" -ForegroundColor Green
        $secretsConfigured++
    }
    
    # 3. SSH_USER
    Write-Host ""
    Write-Host (L "secrets_step_ssh_user") -ForegroundColor Cyan
    Write-Host (L "secrets_enter_user") -ForegroundColor Yellow
    Write-Host (L "secrets_example_user") -ForegroundColor Gray
    $sshUser = Read-Host (L "secrets_user_label")
    
    if ([string]::IsNullOrEmpty($sshUser)) {
        Write-Host (L "secrets_skipped") -ForegroundColor Yellow
    } else {
        Write-Host (L "secrets_saving" "SSH_USER") -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_USER" -SecretValue $sshUser) {
            Write-Host "$([char]0x2713) $(L 'secrets_configured' 'SSH_USER')" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # 4. SSH_PASSWORD
    Write-Host ""
    Write-Host (L "secrets_step_ssh_pass") -ForegroundColor Cyan
    Write-Host (L "secrets_enter_pass") -ForegroundColor Yellow
    $sshPassword = Read-Host (L "secrets_pass_label") -MaskInput
    
    if ([string]::IsNullOrEmpty($sshPassword)) {
        Write-Host (L "secrets_skipped") -ForegroundColor Yellow
    } else {
        Write-Host (L "secrets_saving" "SSH_PASSWORD") -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "SSH_PASSWORD" -SecretValue $sshPassword) {
            Write-Host "$([char]0x2713) $(L 'secrets_configured' 'SSH_PASSWORD')" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # Test SSH connection if all SSH parameters provided
    if (-not [string]::IsNullOrEmpty($sshHost) -and -not [string]::IsNullOrEmpty($sshUser) -and -not [string]::IsNullOrEmpty($sshPassword)) {
        Write-Host ""
        Write-Host (L "secrets_test_title") -ForegroundColor Cyan
        $testConnection = Read-Host (L "secrets_test_now")
        
        if ($testConnection -eq "y" -or $testConnection -eq "Y") {
            if (Test-SSHConnection -HostName $sshHost -Port $sshPort -UserName $sshUser -Password $sshPassword) {
                Write-Host ""
                Write-Host (L "secrets_setup_keys_title") -ForegroundColor Cyan
                Write-Host (L "secrets_setup_keys_question") -ForegroundColor Yellow
                Write-Host (L "secrets_setup_keys_will") -ForegroundColor Gray
                Write-Host "  $(L 'secrets_setup_keys_step1')" -ForegroundColor Gray
                Write-Host "  $(L 'secrets_setup_keys_step2')" -ForegroundColor Gray
                Write-Host "  $(L 'secrets_setup_keys_step3')" -ForegroundColor Gray
                Write-Host ""
                
                $setupKeys = Read-Host (L "secrets_setup_keys_confirm")
                if ($setupKeys -eq "y" -or $setupKeys -eq "Y") {
                    Setup-SSHKeys -HostName $sshHost -Port $sshPort -UserName $sshUser -Password $sshPassword -Repository $Config.Repository
                }
            }
        }
    }
    
    # 5. TELEGRAM_BOT_TOKEN
    Write-Host ""
    Write-Host (L "secrets_step_tg_token") -ForegroundColor Cyan
    Write-Host (L "secrets_enter_tg_token") -ForegroundColor Yellow
    Write-Host (L "secrets_tg_token_format") -ForegroundColor Gray
    $botToken = Read-Host (L "secrets_token_label") -MaskInput
    
    if ([string]::IsNullOrEmpty($botToken)) {
        Write-Host (L "secrets_skipped") -ForegroundColor Yellow
    } else {
        Write-Host (L "secrets_saving" "TELEGRAM_BOT_TOKEN") -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "TELEGRAM_BOT_TOKEN" -SecretValue $botToken) {
            Write-Host "$([char]0x2713) $(L 'secrets_configured' 'TELEGRAM_BOT_TOKEN')" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # 6. TELEGRAM_ADMIN_CHAT_ID
    Write-Host ""
    Write-Host (L "secrets_step_tg_chat") -ForegroundColor Cyan
    Get-TelegramChatId
    $chatId = Read-Host (L "secrets_chat_label")
    
    if ([string]::IsNullOrEmpty($chatId)) {
        Write-Host (L "secrets_skipped") -ForegroundColor Yellow
    } else {
        Write-Host (L "secrets_saving" "TELEGRAM_ADMIN_CHAT_ID") -ForegroundColor Yellow
        if (Set-GitHubSecretViaCLI -Repository $Config.Repository -SecretName "TELEGRAM_ADMIN_CHAT_ID" -SecretValue $chatId) {
            Write-Host "$([char]0x2713) $(L 'secrets_configured' 'TELEGRAM_ADMIN_CHAT_ID')" -ForegroundColor Green
            $secretsConfigured++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host (L "secrets_summary_title") -ForegroundColor Green
    Write-Host (L "secrets_summary_count" $secretsConfigured) -ForegroundColor Cyan
    Write-Host ""
    
    if ($secretsConfigured -gt 0) {
        Write-Host (L "secrets_available_in_actions") -ForegroundColor Green
        Write-Host (L "secrets_repo_url" $Config.Repository) -ForegroundColor Cyan
    }
}

function Show-ConfiguredSecrets {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    if (-not $Config.IsValid()) {
        Write-Host ""
        Write-Host (L "secrets_error_config_first") -ForegroundColor Red
        return
    }
    
    if (-not (Test-GitHubCLI)) {
        Write-Host ""
        Write-Host (L "secrets_gh_not_installed") -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host (L "secrets_list_title") -ForegroundColor Cyan
    Write-Host (L "secrets_repository" $Config.Repository) -ForegroundColor Green
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
        
        Write-Host (L "secrets_required_status") -ForegroundColor Yellow
        foreach ($secretName in $requiredSecrets) {
            if ($secretsList -match $secretName) {
                Write-Host "  $([char]0x2713) $secretName" -ForegroundColor Green
            } else {
                Write-Host "  $([char]0x2717) $secretName $(L 'secrets_not_configured')" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host (L "secrets_full_list") -ForegroundColor Gray
        Write-Host $secretsList -ForegroundColor Gray
        
    } catch {
        Write-Host (L "secrets_error" $_) -ForegroundColor Red
    }
    
    Write-Host ""
}
