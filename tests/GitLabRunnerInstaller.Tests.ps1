# GitLabRunnerInstaller Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

. "$root\lib\PlatformProvider.ps1"
. "$root\lib\GitHubProvider.ps1"
. "$root\lib\GitLabProvider.ps1"
. "$root\lib\GitLabRunnerInstaller.ps1"

Describe "GitLabRunnerInstaller Module" {

    Context "Function Definitions" {
        It "Should define Install-GitLabRunner" {
            Get-Command Install-GitLabRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Uninstall-GitLabRunner" {
            Get-Command Uninstall-GitLabRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }
}
