# UI Module Tests

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

. "$root\lib\UI.ps1"

Describe "UI Module" {

    Context "Function Definitions" {
        It "Should define Show-Banner" {
            Get-Command Show-Banner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Show-MainMenu" {
            Get-Command Show-MainMenu -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Show-Status" {
            Get-Command Show-Status -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Show-HelpGuide" {
            Get-Command Show-HelpGuide -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Show-PlatformSelection" {
            Get-Command Show-PlatformSelection -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-ScheduledTaskName" {
            Get-Command Get-ScheduledTaskName -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Show-Banner" {
        It "Should not throw" {
            { Show-Banner } | Should Not Throw
        }
    }

    Context "Show-PlatformSelection" {
        It "Should not throw" {
            { Show-PlatformSelection } | Should Not Throw
        }
    }

    Context "Get-ScheduledTaskName" {
        It "Should return task name containing repository" {
            $name = Get-ScheduledTaskName -Repository "owner/repo"
            $name | Should Not BeNullOrEmpty
            $name | Should Match "runner|Runner|owner"
        }
    }

    Context "Show-HelpGuide" {
        It "Should not throw" {
            # Mock Read-Host to avoid blocking
            function Read-Host { return "" }
            { Show-HelpGuide } | Should Not Throw
        }
    }
}
