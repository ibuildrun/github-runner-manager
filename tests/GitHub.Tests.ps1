# GitHub API Wrapper Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

. "$root\lib\PlatformProvider.ps1"
. "$root\lib\GitHubProvider.ps1"
. "$root\lib\GitHub.ps1"

Describe "GitHub API Wrapper Functions" {

    Context "Function Definitions" {
        It "Should define Get-GitHubUser" {
            Get-Command Get-GitHubUser -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-GitHubRepositories" {
            Get-Command Get-GitHubRepositories -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-RunnerRegistrationToken" {
            Get-Command Get-RunnerRegistrationToken -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-RunnerRemovalToken" {
            Get-Command Get-RunnerRemovalToken -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Test-GitHubToken" {
            Get-Command Test-GitHubToken -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-GitHubRunners" {
            Get-Command Get-GitHubRunners -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Remove-GitHubRunner" {
            Get-Command Remove-GitHubRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Remove-OfflineRunners" {
            Get-Command Remove-OfflineRunners -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Get-GitHubUser with invalid token" {
        It "Should return null for invalid token" {
            $result = Get-GitHubUser -Token "invalid_token_xyz"
            $result | Should BeNullOrEmpty
        }
    }

    Context "Get-GitHubRepositories with invalid token" {
        It "Should return empty array for invalid token" {
            $result = Get-GitHubRepositories -Token "invalid_token_xyz"
            $result.Count | Should Be 0
        }
    }

    Context "Get-GitHubRunners with invalid token" {
        It "Should return empty array for invalid token" {
            $result = Get-GitHubRunners -Token "invalid_token_xyz" -Repository "owner/repo"
            $result.Count | Should Be 0
        }
    }
}
