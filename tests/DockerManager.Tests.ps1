# DockerManager Module Tests

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

. "$root\lib\DockerManager.ps1"

Describe "DockerRunnerConfig Class" {

    Context "Constructor" {
        It "Should initialize with defaults" {
            $drc = [DockerRunnerConfig]::new()
            $drc.Status | Should Be "Unknown"
            $drc.Created | Should Not BeNullOrEmpty
        }

        It "Should allow setting properties" {
            $drc = [DockerRunnerConfig]::new()
            $drc.ContainerId = "abc123"
            $drc.Repository = "owner/repo"
            $drc.RunnerName = "test-runner"
            $drc.ImageTag = "github-runner:latest"

            $drc.ContainerId | Should Be "abc123"
            $drc.Repository | Should Be "owner/repo"
            $drc.RunnerName | Should Be "test-runner"
            $drc.ImageTag | Should Be "github-runner:latest"
        }
    }
}

Describe "Docker Helper Functions" {

    Context "Test-DockerInstalled" {
        It "Should return boolean" {
            $result = Test-DockerInstalled
            $result | Should BeOfType [bool]
        }
    }

    Context "Test-DockerRunning" {
        It "Should return boolean" {
            $result = Test-DockerRunning
            $result | Should BeOfType [bool]
        }
    }
}
