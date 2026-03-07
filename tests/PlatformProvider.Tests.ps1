# PlatformProvider Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

# Load modules
. "$root\lib\PlatformProvider.ps1"
. "$root\lib\GitHubProvider.ps1"
. "$root\lib\GitLabProvider.ps1"

Describe "IPlatformProvider Interface" {

    Context "Base class throws NotImplementedException" {
        $provider = [IPlatformProvider]::new()

        It "GetPlatformName should throw" {
            { $provider.GetPlatformName() } | Should Throw
        }

        It "GetPlatformDisplayName should throw" {
            { $provider.GetPlatformDisplayName() } | Should Throw
        }

        It "ValidateToken should throw" {
            { $provider.ValidateToken("token", "") } | Should Throw
        }

        It "GetCurrentUser should throw" {
            { $provider.GetCurrentUser("token", "") } | Should Throw
        }

        It "SearchRepositories should throw" {
            { $provider.SearchRepositories("token", "query", "") } | Should Throw
        }

        It "GetRunnerRegistrationToken should throw" {
            { $provider.GetRunnerRegistrationToken("t", "r", "repository", "") } | Should Throw
        }

        It "GetRunnerRemovalToken should throw" {
            { $provider.GetRunnerRemovalToken("t", "r", "repository", "") } | Should Throw
        }

        It "GetRunnerDownloadUrl should throw" {
            { $provider.GetRunnerDownloadUrl("v", "linux", "x64") } | Should Throw
        }

        It "GetDockerImageName should throw" {
            { $provider.GetDockerImageName() } | Should Throw
        }

        It "GetDefaultInstanceUrl should throw" {
            { $provider.GetDefaultInstanceUrl() } | Should Throw
        }

        It "RequiresInstanceUrl should throw" {
            { $provider.RequiresInstanceUrl() } | Should Throw
        }
    }
}

Describe "GitHubProvider" {
    $provider = [GitHubProvider]::new()

    Context "Platform Identification" {
        It "Should return 'github' as platform name" {
            $provider.GetPlatformName() | Should Be "github"
        }

        It "Should return 'GitHub' as display name" {
            $provider.GetPlatformDisplayName() | Should Be "GitHub"
        }
    }

    Context "Token Validation" {
        It "Should return false for empty token" {
            $provider.ValidateToken("", "") | Should Be $false
        }

        It "Should return false for whitespace token" {
            $provider.ValidateToken("   ", "") | Should Be $false
        }

        It "Should return false for null token" {
            $provider.ValidateToken($null, "") | Should Be $false
        }
    }

    Context "GetCurrentUser with invalid token" {
        It "Should throw for empty token" {
            { $provider.GetCurrentUser("", "") } | Should Throw
        }

        It "Should throw for null token" {
            { $provider.GetCurrentUser($null, "") } | Should Throw
        }
    }

    Context "SearchRepositories with invalid token" {
        It "Should throw for empty token" {
            { $provider.SearchRepositories("", "query", "") } | Should Throw
        }
    }

    Context "Instance URL" {
        It "Should not require instance URL" {
            $provider.RequiresInstanceUrl() | Should Be $false
        }

        It "Should return github.com as default instance URL" {
            $provider.GetDefaultInstanceUrl() | Should Be "https://github.com"
        }
    }

    Context "Docker" {
        It "Should return github-runner as docker image name" {
            $provider.GetDockerImageName() | Should Be "github-runner"
        }
    }

    Context "Runner Download URL" {
        It "Should return valid URL for windows x64" {
            $url = $provider.GetRunnerDownloadUrl("2.321.0", "win", "x64")
            $url | Should Match "actions-runner-win-x64"
            $url | Should Match "2.321.0"
        }

        It "Should return valid URL for linux x64" {
            $url = $provider.GetRunnerDownloadUrl("2.321.0", "linux", "x64")
            $url | Should Match "actions-runner-linux-x64"
        }
    }
}

Describe "GitLabProvider" {
    $provider = [GitLabProvider]::new()

    Context "Platform Identification" {
        It "Should return 'gitlab' as platform name" {
            $provider.GetPlatformName() | Should Be "gitlab"
        }

        It "Should return 'GitLab' as display name" {
            $provider.GetPlatformDisplayName() | Should Be "GitLab"
        }
    }

    Context "Token Validation" {
        It "Should return false for empty token" {
            $provider.ValidateToken("", "") | Should Be $false
        }

        It "Should return false for null token" {
            $provider.ValidateToken($null, "") | Should Be $false
        }
    }

    Context "GetCurrentUser with invalid token" {
        It "Should throw for empty token" {
            { $provider.GetCurrentUser("", "") } | Should Throw
        }
    }

    Context "Instance URL" {
        It "Should require instance URL" {
            $provider.RequiresInstanceUrl() | Should Be $true
        }

        It "Should return gitlab.com as default" {
            $provider.GetDefaultInstanceUrl() | Should Be "https://gitlab.com"
        }
    }

    Context "Docker" {
        It "Should return gitlab-runner as docker image name" {
            $provider.GetDockerImageName() | Should Be "gitlab-runner"
        }
    }
}

Describe "PlatformFactory" {

    Context "GetProvider" {
        It "Should return GitHubProvider for 'github'" {
            $p = [PlatformFactory]::GetProvider("github")
            $p | Should Not BeNullOrEmpty
            $p.GetPlatformName() | Should Be "github"
        }

        It "Should return GitLabProvider for 'gitlab'" {
            $p = [PlatformFactory]::GetProvider("gitlab")
            $p | Should Not BeNullOrEmpty
            $p.GetPlatformName() | Should Be "gitlab"
        }

        It "Should throw for unknown platform" {
            { [PlatformFactory]::GetProvider("bitbucket") } | Should Throw
        }
    }

    Context "GetAvailablePlatforms" {
        It "Should return github and gitlab" {
            $platforms = [PlatformFactory]::GetAvailablePlatforms()
            ($platforms -contains "github") | Should Be $true
            ($platforms -contains "gitlab") | Should Be $true
        }
    }

    Context "GetPlatformDisplayName" {
        It "Should return GitHub for github" {
            [PlatformFactory]::GetPlatformDisplayName("github") | Should Be "GitHub"
        }

        It "Should return GitLab for gitlab" {
            [PlatformFactory]::GetPlatformDisplayName("gitlab") | Should Be "GitLab"
        }
    }
}
