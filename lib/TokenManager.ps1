# Token Management Module

. "$PSScriptRoot\GitHub.ps1"
. "$PSScriptRoot\UI.ps1"

function Invoke-TokenConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )
    
    Show-TokenConfigurationHelp
    
    if ($Config.GitHubToken) {
        Write-Host "Current token: $($Config.GitHubToken.Substring(0, 10))..." -ForegroundColor Green
        $response = Read-Host "Update token? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            return
        }
    }
    
    $token = Read-Host "Enter GitHub Token (ghp_...)" -MaskInput
    if ([string]::IsNullOrEmpty($token)) {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Validate token
    if (-not (Test-GitHubToken -Token $token)) {
        Write-Host "Please check your token and try again" -ForegroundColor Yellow
        return
    }
    
    $Config.GitHubToken = $token
    
    # Ask where to store
    Show-TokenStorageOptions
    
    $storage = Read-Host "Select option (1-3)"
    
    switch ($storage) {
        "1" {
            [System.Environment]::SetEnvironmentVariable("GITHUB_RUNNER_TOKEN", $token, "User")
            Write-Host "Token saved to environment variable GITHUB_RUNNER_TOKEN" -ForegroundColor Green
            $Config.Save("Environment")
        }
        "2" {
            $Config.Save("File")
            Write-Host "Token saved to configuration file (base64 encoded)" -ForegroundColor Green
        }
        "3" {
            $Config.Save("None")
            Write-Host "Token will be used for this session only" -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid option, token not saved" -ForegroundColor Red
        }
    }
}

Export-ModuleMember -Function Invoke-TokenConfiguration
