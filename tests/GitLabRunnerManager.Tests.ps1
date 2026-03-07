# GitLabRunnerManager Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

. "$root\lib\GitLabRunnerManager.ps1"

Describe "GitLabRunnerManager Module" {

    Context "Function Definitions" {
        It "Should define Start-GitLabRunner" {
            Get-Command Start-GitLabRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Stop-GitLabRunner" {
            Get-Command Stop-GitLabRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Test-GitLabRunnerProcess" {
            Get-Command Test-GitLabRunnerProcess -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Find-GitLabRunnerProcess" {
            Get-Command Find-GitLabRunnerProcess -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-GitLabRunnerStatus" {
            Get-Command Get-GitLabRunnerStatus -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Show-GitLabRunnerLogs" {
            Get-Command Show-GitLabRunnerLogs -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Test-GitLabRunnerProcess" {
        It "Should return false for non-existent path" {
            $result = Test-GitLabRunnerProcess -RunnerPath "C:\nonexistent-gitlab-runner-xyz"
            $result | Should Be $false
        }
    }

    Context "Find-GitLabRunnerProcess" {
        It "Should return null for non-existent path" {
            $result = Find-GitLabRunnerProcess -RunnerPath "C:\nonexistent-gitlab-runner-xyz"
            $result | Should BeNullOrEmpty
        }
    }

    Context "Show-GitLabRunnerLogs with missing path" {
        It "Should handle missing log file gracefully" {
            { Show-GitLabRunnerLogs -RunnerPath "C:\nonexistent-gitlab-runner-xyz" } | Should Not Throw
        }
    }
}
