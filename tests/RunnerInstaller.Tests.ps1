# RunnerInstaller Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

. "$root\lib\PlatformProvider.ps1"
. "$root\lib\GitHubProvider.ps1"
. "$root\lib\GitLabProvider.ps1"
. "$root\lib\GitHub.ps1"
. "$root\lib\RunnerInstaller.ps1"

Describe "RunnerInstaller Module" {

    Context "Function Definitions" {
        It "Should define Install-GitHubRunner" {
            Get-Command Install-GitHubRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Uninstall-GitHubRunner" {
            Get-Command Uninstall-GitHubRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }
}
