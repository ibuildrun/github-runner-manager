# Token Management Module

. "$PSScriptRoot\GitHub.ps1"

# Load platform providers if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'IPlatformProvider').Type) {
    . "$PSScriptRoot\PlatformProvider.ps1"
}

function Invoke-TokenConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    # Get platform display name
    $platformName = $Config.GetPlatformDisplayName()
    
    # Show help based on platform
    if ($Config.Platform -eq "gitlab") {
        Write-Host ""
        Write-Host (L "token_config_title" "GitLab") -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (L "token_config_help_github") -ForegroundColor Yellow
        Write-Host "  - $(L 'token_config_perm_api')" -ForegroundColor White
        Write-Host ""
        Write-Host (L "token_config_create_gitlab") -ForegroundColor Cyan
        Write-Host (L "token_config_create_gitlab_self") -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host (L "token_config_title" "GitHub") -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (L "token_config_help_github") -ForegroundColor Yellow
        Write-Host "  - $(L 'token_config_perm_repo')" -ForegroundColor White
        Write-Host "  - $(L 'token_config_perm_workflow')" -ForegroundColor White
        Write-Host ""
        Write-Host (L "token_config_create_github") -ForegroundColor Cyan
        Write-Host ""
    }
    
    if ($Config.GitHubToken) {
        Write-Host "$(L 'token_current'): $($Config.GitHubToken.Substring(0, 10))..." -ForegroundColor Green
        $response = Read-Host (L "token_update")
        if ($response -ne "y" -and $response -ne "Y") {
            return
        }
    }
    
    # Platform-specific token prompt
    if ($Config.Platform -eq "gitlab") {
        $token = Read-Host (L "token_enter_gitlab") -MaskInput
    } else {
        $token = Read-Host (L "token_enter_github") -MaskInput
    }
    
    if ([string]::IsNullOrEmpty($token)) {
        Write-Host (L "cancelled") -ForegroundColor Yellow
        return
    }
    
    # Validate token using platform provider
    Write-Host (L "token_validating" $platformName) -ForegroundColor Yellow
    
    try {
        $provider = $Config.GetProvider()
        if ($null -eq $provider) {
            Write-Host "$(L 'error'): Could not load platform provider" -ForegroundColor Red
            return
        }
        
        $isValid = $provider.ValidateToken($token, $Config.InstanceUrl)
        
        if ($isValid) {
            $user = $provider.GetCurrentUser($token, $Config.InstanceUrl)
            if ($user) {
                $username = if ($Config.Platform -eq "gitlab") { $user.username } else { $user.login }
                Write-Host (L "token_valid" $username) -ForegroundColor Green
            }
        } else {
            Write-Host (L "token_invalid") -ForegroundColor Red
            Write-Host (L "token_check_retry") -ForegroundColor Yellow
            return
        }
    } catch {
        Write-Host (L "token_validation_error" $_) -ForegroundColor Red
        return
    }
    
    $Config.GitHubToken = $token
    
    # Ask where to store
    Write-Host ""
    Write-Host (L "token_storage_question") -ForegroundColor Cyan
    Write-Host "  1. $(L 'token_storage_env')" -ForegroundColor White
    Write-Host "  2. $(L 'token_storage_file')" -ForegroundColor White
    Write-Host "  3. $(L 'token_storage_session')" -ForegroundColor White
    Write-Host ""
    
    $storage = Read-Host (L "select_option" "1-3")
    
    switch ($storage) {
        "1" {
            # Platform-specific environment variable
            if ($Config.Platform -eq "gitlab") {
                [System.Environment]::SetEnvironmentVariable("GITLAB_RUNNER_TOKEN", $token, "User")
                Write-Host (L "token_saved_env" "GITLAB_RUNNER_TOKEN") -ForegroundColor Green
            } else {
                [System.Environment]::SetEnvironmentVariable("GITHUB_RUNNER_TOKEN", $token, "User")
                Write-Host (L "token_saved_env" "GITHUB_RUNNER_TOKEN") -ForegroundColor Green
            }
            $Config.Save("Environment")
        }
        "2" {
            $Config.Save("File")
            Write-Host (L "token_saved_file") -ForegroundColor Green
        }
        "3" {
            $Config.Save("None")
            Write-Host (L "token_saved_session") -ForegroundColor Yellow
        }
        default {
            Write-Host (L "token_not_saved") -ForegroundColor Red
        }
    }
}
