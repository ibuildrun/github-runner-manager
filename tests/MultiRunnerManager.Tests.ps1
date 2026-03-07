# MultiRunnerManager Module Tests

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
. "$root\lib\MultiRunnerManager.ps1"

Describe "MultiRunnerManager Module" {

    Context "Function Definitions" {
        It "Should define Show-LocalRunners" {
            Get-Command Show-LocalRunners -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Add-LocalRunner" {
            Get-Command Add-LocalRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Select-ActiveRunner" {
            Get-Command Select-ActiveRunner -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Remove-LocalRunnerInteractive" {
            Get-Command Remove-LocalRunnerInteractive -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Test-RunnerProcess" {
            Get-Command Test-RunnerProcess -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Get-ActiveRunnerPath" {
            Get-Command Get-ActiveRunnerPath -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should define Invoke-MultiRunnerMenu" {
            Get-Command Invoke-MultiRunnerMenu -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Test-RunnerProcess" {
        It "Should return false for non-existent runner path" {
            $result = Test-RunnerProcess -RunnerPath "C:\nonexistent-runner-xyz-12345"
            $result | Should Be $false
        }
    }

    Context "Get-ActiveRunnerPath" {
        It "Should return null when no runners configured" {
            $testConfigFile = "$env:TEMP\octopus-multi-test-config.json"
            if (Test-Path $testConfigFile) { Remove-Item $testConfigFile -Force }

            $config = [RunnerConfig]::new($testConfigFile)
            $config.Load()

            $result = Get-ActiveRunnerPath -Config $config
            $result | Should BeNullOrEmpty

            if (Test-Path $testConfigFile) { Remove-Item $testConfigFile -Force }
        }

        It "Should return path of active runner" {
            $testConfigFile = "$env:TEMP\octopus-multi-test-config2.json"
            if (Test-Path $testConfigFile) { Remove-Item $testConfigFile -Force }

            $config = [RunnerConfig]::new($testConfigFile)
            $config.Repository = "owner/repo"
            $config.Save("None")
            $config.Load()

            $runner = @{
                Id = "test-path-runner"; Name = "Path Test"
                Path = "C:\test-runner-path"; Repository = "owner/repo"
                Platform = "github"; Created = (Get-Date).ToString("o")
                Status = "Installed"
            }
            $config.AddLocalRunner($runner)
            $config.SetActiveRunner("test-path-runner")

            $result = Get-ActiveRunnerPath -Config $config
            $result | Should Be "C:\test-runner-path"

            if (Test-Path $testConfigFile) { Remove-Item $testConfigFile -Force }
        }
    }

    Context "Show-LocalRunners with empty config" {
        It "Should not throw when no runners" {
            $testConfigFile = "$env:TEMP\octopus-multi-test-config3.json"
            if (Test-Path $testConfigFile) { Remove-Item $testConfigFile -Force }

            $config = [RunnerConfig]::new($testConfigFile)
            $config.Load()

            { Show-LocalRunners -Config $config } | Should Not Throw

            if (Test-Path $testConfigFile) { Remove-Item $testConfigFile -Force }
        }
    }
}
