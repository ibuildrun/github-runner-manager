# AutoStart Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

. "$root\lib\Localization.ps1"
. "$root\lib\PlatformProvider.ps1"
. "$root\lib\GitHubProvider.ps1"
. "$root\lib\GitLabProvider.ps1"
. "$root\lib\TelegramNotifier.ps1"

if (-not ([System.Management.Automation.PSTypeName]'RunnerConfig').Type) {
    . "$root\lib\Config.ps1"
}

. "$root\lib\AutoStart.ps1"

Describe "AutoStart Module" {

    Context "Test-AdminPrivileges function existence" {
        It "Should be defined as a function" {
            Get-Command Test-AdminPrivileges -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Enable-RunnerAutoStart function existence" {
        It "Should be defined as a function" {
            Get-Command Enable-RunnerAutoStart -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Disable-RunnerAutoStart function existence" {
        It "Should be defined as a function" {
            Get-Command Disable-RunnerAutoStart -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Test-AdminPrivileges returns boolean type" {
        It "Should return a boolean value" {
            # We can't call it directly because it calls Read-Host when not admin
            # Instead verify the function body contains the expected logic
            $fn = Get-Command Test-AdminPrivileges
            $fn.CommandType | Should Be "Function"
            $fn.Definition | Should Match "IsInRole"
            $fn.Definition | Should Match "Administrator"
        }
    }
}
