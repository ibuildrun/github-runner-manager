# Config Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

# Load dependencies
. "$root\lib\Localization.ps1"
. "$root\lib\PlatformProvider.ps1"
. "$root\lib\GitHubProvider.ps1"
. "$root\lib\GitLabProvider.ps1"
. "$root\lib\TelegramNotifier.ps1"

# Force reload Config.ps1 by removing type check
if (-not ([System.Management.Automation.PSTypeName]'RunnerConfig').Type) {
    . "$root\lib\Config.ps1"
}

# Helper: count of auto-migrated runners (if C:\actions-runner\run.cmd exists)
$script:hasMigratedRunner = Test-Path "C:\actions-runner\run.cmd"

function New-TestConfig {
    param([string]$Path)
    if (Test-Path $Path) { Remove-Item $Path -Force }
    return [RunnerConfig]::new($Path)
}

Describe "RunnerConfig" {
    $testConfigDir = "$env:TEMP\octopus-runner-tests-$(Get-Random)"
    New-Item -ItemType Directory -Path $testConfigDir -Force | Out-Null

    Context "Constructor" {
        It "Should initialize with default values" {
            $config = [RunnerConfig]::new("$testConfigDir\ctor-test.json")
            $config.Platform | Should Be "github"
            $config.InstanceUrl | Should Be ""
            $config.TargetType | Should Be "project"
            $config.ConfigVersion | Should Be 2
            $config.Language | Should Be "en"
            $config.GitHubToken | Should BeNullOrEmpty
            $config.Repository | Should BeNullOrEmpty
            $config.ActiveRunnerId | Should BeNullOrEmpty
        }

        It "Should store config file path" {
            $f = "$testConfigDir\ctor-path.json"
            $config = [RunnerConfig]::new($f)
            $config.ConfigFile | Should Be $f
        }
    }

    Context "Load - Empty/Missing Config" {
        It "Should handle missing config file gracefully" {
            $config = [RunnerConfig]::new("$testConfigDir\missing.json")
            { $config.Load() } | Should Not Throw
        }

        It "Should handle empty config file" {
            $f = "$testConfigDir\empty.json"
            "" | Set-Content $f
            $config = [RunnerConfig]::new($f)
            { $config.Load() } | Should Not Throw
        }
    }

    Context "Save and Load" {
        It "Should save and reload configuration" {
            $f = "$testConfigDir\save-load.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "owner/repo"
            $config.Platform = "github"
            $config.Language = "ru"
            $config.Save("None")

            Test-Path $f | Should Be $true

            $config2 = [RunnerConfig]::new($f)
            $config2.Load()
            $config2.Repository | Should Be "owner/repo"
            $config2.Platform | Should Be "github"
            $config2.Language | Should Be "ru"
        }

        It "Should save token encrypted when storage is File" {
            $f = "$testConfigDir\token-file.json"
            $config = New-TestConfig -Path $f
            $config.GitHubToken = "ghp_test123456"
            $config.Repository = "owner/repo"
            $config.Save("File")

            $raw = Get-Content $f -Raw | ConvertFrom-Json
            $raw.TokenStorage | Should Be "File"
            $raw.TokenEncrypted | Should Not BeNullOrEmpty

            $decoded = [System.Text.Encoding]::UTF8.GetString(
                [System.Convert]::FromBase64String($raw.TokenEncrypted)
            )
            $decoded | Should Be "ghp_test123456"
        }

        It "Should not save token when storage is None" {
            $f = "$testConfigDir\token-none.json"
            $config = New-TestConfig -Path $f
            $config.GitHubToken = "ghp_test123456"
            $config.Repository = "owner/repo"
            $config.Save("None")

            $raw = Get-Content $f -Raw | ConvertFrom-Json
            $raw.TokenStorage | Should Be "None"
            $hasEncrypted = $null -ne $raw.TokenEncrypted
            $hasEncrypted | Should Be $false
        }
    }

    Context "IsValid" {
        It "Should return false when token is missing" {
            $config = [RunnerConfig]::new("$testConfigDir\isvalid1.json")
            $config.Repository = "owner/repo"
            $config.IsValid() | Should Be $false
        }

        It "Should return false when repository is missing" {
            $config = [RunnerConfig]::new("$testConfigDir\isvalid2.json")
            $config.GitHubToken = "ghp_test"
            $config.IsValid() | Should Be $false
        }

        It "Should return true when both are set" {
            $config = [RunnerConfig]::new("$testConfigDir\isvalid3.json")
            $config.GitHubToken = "ghp_test"
            $config.Repository = "owner/repo"
            $config.IsValid() | Should Be $true
        }
    }

    Context "GetProvider" {
        It "Should return GitHubProvider for github platform" {
            $config = [RunnerConfig]::new("$testConfigDir\provider1.json")
            $config.Platform = "github"
            $provider = $config.GetProvider()
            $provider | Should Not BeNullOrEmpty
            $provider.GetPlatformName() | Should Be "github"
        }

        It "Should return GitLabProvider for gitlab platform" {
            $config = [RunnerConfig]::new("$testConfigDir\provider2.json")
            $config.Platform = "gitlab"
            $provider = $config.GetProvider()
            $provider | Should Not BeNullOrEmpty
            $provider.GetPlatformName() | Should Be "gitlab"
        }
    }

    Context "GetPlatformDisplayName" {
        It "Should return GitHub for github" {
            $config = [RunnerConfig]::new("$testConfigDir\display1.json")
            $config.Platform = "github"
            $config.GetPlatformDisplayName() | Should Be "GitHub"
        }

        It "Should return GitLab for gitlab" {
            $config = [RunnerConfig]::new("$testConfigDir\display2.json")
            $config.Platform = "gitlab"
            $config.GetPlatformDisplayName() | Should Be "GitLab"
        }
    }

    Context "Telegram Config" {
        It "Should return disabled telegram config by default" {
            $config = [RunnerConfig]::new("$testConfigDir\tg-default.json")
            $config.Load()
            $tg = $config.GetTelegramConfig()
            $tg.Enabled | Should Be $false
            $tg.ChatIds.Count | Should Be 0
        }

        It "Should save and load telegram config" {
            $f = "$testConfigDir\tg-save.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "owner/repo"
            $config.Save("None")
            $config.Load()

            $tgConfig = @{
                BotToken = "123:ABC"
                ChatIds  = @("111", "222")
                Enabled  = $true
            }
            $config.SaveTelegramConfig($tgConfig)

            $config2 = [RunnerConfig]::new($f)
            $config2.Load()
            $tg = $config2.GetTelegramConfig()
            $tg.Enabled | Should Be $true
            $tg.BotToken | Should Be "123:ABC"
            $tg.ChatIds.Count | Should Be 2
        }
    }

    Context "Local Runners" {
        # Note: MigrateExistingRunner may auto-add a runner if C:\actions-runner\run.cmd exists
        $migratedCount = if ($script:hasMigratedRunner) { 1 } else { 0 }

        It "Should return empty array when no runners and no migration" {
            $f = "$testConfigDir\runners-empty.json"
            $config = New-TestConfig -Path $f
            # Don't set Repository to avoid triggering migration
            $config.Load()
            $runners = $config.GetLocalRunners()
            $runners.Count | Should Be 0
        }

        It "Should add and retrieve local runner" {
            $f = "$testConfigDir\runners-add.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "test-only/no-migration"
            $config.Save("None")
            $config.Load()

            $baseCount = $config.GetLocalRunners().Count

            $runner = @{
                Id         = "test-001"
                Name       = "Test Runner"
                Path       = "C:\test-runner"
                Repository = "test-only/no-migration"
                Platform   = "github"
                Created    = (Get-Date).ToString("o")
                Status     = "Not Installed"
            }
            $config.AddLocalRunner($runner)

            $runners = $config.GetLocalRunners()
            $runners.Count | Should Be ($baseCount + 1)

            $found = $runners | Where-Object { $_.Id -eq "test-001" }
            $found | Should Not BeNullOrEmpty
            $found.Name | Should Be "Test Runner"
        }

        It "Should set and get active runner" {
            $f = "$testConfigDir\runners-active.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "test-only/active"
            $config.Save("None")
            $config.Load()

            $runner = @{
                Id = "runner-abc"; Name = "ABC Runner"
                Path = "C:\abc-runner"; Repository = "test-only/active"
                Platform = "github"; Created = (Get-Date).ToString("o")
                Status = "Installed"
            }
            $config.AddLocalRunner($runner)
            $config.SetActiveRunner("runner-abc")

            $active = $config.GetActiveRunner()
            $active | Should Not BeNullOrEmpty
            $active.Id | Should Be "runner-abc"
        }

        It "Should remove local runner" {
            $f = "$testConfigDir\runners-remove.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "test-only/remove"
            $config.Save("None")
            $config.Load()

            $baseCount = $config.GetLocalRunners().Count

            $r1 = @{ Id = "r1"; Name = "R1"; Path = "C:\r1"; Repository = "test-only/remove"; Platform = "github"; Created = (Get-Date).ToString("o"); Status = "Installed" }
            $r2 = @{ Id = "r2"; Name = "R2"; Path = "C:\r2"; Repository = "test-only/remove"; Platform = "github"; Created = (Get-Date).ToString("o"); Status = "Installed" }
            $config.AddLocalRunner($r1)
            $config.AddLocalRunner($r2)

            $config.RemoveLocalRunner("r1")

            $runners = $config.GetLocalRunners()
            $runners.Count | Should Be ($baseCount + 1)
            $found = $runners | Where-Object { $_.Id -eq "r2" }
            $found | Should Not BeNullOrEmpty
        }

        It "Should clear active runner when removing active" {
            $f = "$testConfigDir\runners-clear-active.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "test-only/clear"
            $config.Save("None")
            $config.Load()

            $r = @{ Id = "active-r"; Name = "Active"; Path = "C:\active"; Repository = "test-only/clear"; Platform = "github"; Created = (Get-Date).ToString("o"); Status = "Installed" }
            $config.AddLocalRunner($r)
            $config.SetActiveRunner("active-r")

            $config.RemoveLocalRunner("active-r")
            $config.ActiveRunnerId | Should BeNullOrEmpty
        }

        It "Should return null when no runners for GetActiveRunner" {
            $config = [RunnerConfig]::new("$testConfigDir\runners-null.json")
            $config.Load()
            $config.GetActiveRunner() | Should BeNullOrEmpty
        }
    }

    Context "Docker Runners" {
        It "Should return empty array when no docker runners" {
            $config = [RunnerConfig]::new("$testConfigDir\docker-empty.json")
            $config.Load()
            $config.GetDockerRunners().Count | Should Be 0
        }
    }

    Context "Clear" {
        It "Should remove config file and reset state" {
            $f = "$testConfigDir\clear-test.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "owner/repo"
            $config.Save("None")

            Test-Path $f | Should Be $true
            $config.Clear()
            Test-Path $f | Should Be $false
            $config.Repository | Should BeNullOrEmpty
        }
    }

    Context "Config Migration v1 to v2" {
        It "Should migrate v1 config to v2" {
            $v1Config = @{
                Repository     = "owner/repo"
                TokenStorage   = "Environment"
                TokenEncrypted = "dGVzdA=="
                Telegram       = @{ BotToken = "123"; ChatIds = @("1"); Enabled = $true }
            }
            $result = [RunnerConfig]::MigrateFromV1($v1Config)
            $result.ConfigVersion | Should Be 2
            $result.Platform | Should Be "github"
            $result.Repository | Should Be "owner/repo"
            $result.TokenEncrypted | Should Be "dGVzdA=="
        }
    }

    Context "Preserve sections on Save" {
        It "Should preserve Telegram config on save" {
            $f = "$testConfigDir\preserve-tg.json"
            $config = New-TestConfig -Path $f
            $config.Repository = "owner/repo"
            $config.Save("None")
            $config.Load()

            $config.SaveTelegramConfig(@{ BotToken = "bot:token"; ChatIds = @("123"); Enabled = $true })

            $config2 = [RunnerConfig]::new($f)
            $config2.Load()
            $config2.Save("None")

            $raw = Get-Content $f -Raw | ConvertFrom-Json
            $raw.Telegram | Should Not BeNullOrEmpty
            $raw.Telegram.BotToken | Should Be "bot:token"
        }
    }

    # Cleanup
    if (Test-Path $testConfigDir) {
        Remove-Item $testConfigDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
