# RunnerManager Module Tests

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
. "$root\lib\RunnerManager.ps1"

Describe "RunnerManager Module" {

    Context "Function Definitions" {
        It "Should define Start-GitHubRunner" {
            Get-Command Start-GitHubRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Stop-GitHubRunner" {
            Get-Command Stop-GitHubRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Show-RunnerLogs" {
            Get-Command Show-RunnerLogs -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Show-RunnerLogs with non-existent path" {
        It "Should handle missing log directory gracefully" {
            { Show-RunnerLogs -RunnerPath "C:\nonexistent-runner-path-xyz" } | Should Not Throw
        }
    }
}
