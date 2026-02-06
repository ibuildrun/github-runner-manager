# Platform Provider Interface Module
# Base class defining the interface that all platform providers must implement

class IPlatformProvider {
    # ============================================================================
    # Platform Identification Methods
    # ============================================================================
    
    <#
    .SYNOPSIS
    Returns the internal platform name identifier.
    
    .DESCRIPTION
    Returns a lowercase string identifier for the platform (e.g., "github", "gitlab").
    Used for configuration storage and internal logic.
    
    .OUTPUTS
    String - Platform identifier
    #>
    [string] GetPlatformName() {
        throw [System.NotImplementedException]::new("GetPlatformName() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Returns the display name for the platform.
    
    .DESCRIPTION
    Returns a human-readable display name for the platform (e.g., "GitHub", "GitLab").
    Used for UI display and user-facing messages.
    
    .OUTPUTS
    String - Platform display name
    #>
    [string] GetPlatformDisplayName() {
        throw [System.NotImplementedException]::new("GetPlatformDisplayName() must be implemented by derived class")
    }
    
    # ============================================================================
    # Authentication Methods
    # ============================================================================
    
    <#
    .SYNOPSIS
    Validates a platform access token.
    
    .DESCRIPTION
    Validates the provided token by making an API call to the platform.
    Returns true if the token is valid, false otherwise.
    
    .PARAMETER Token
    The access token to validate
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Boolean - True if token is valid, false otherwise
    #>
    [bool] ValidateToken([string]$Token, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("ValidateToken() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets the current authenticated user information.
    
    .DESCRIPTION
    Retrieves information about the user associated with the provided token.
    Returns an object with user details (username, name, avatar, etc.).
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Object - User information object
    #>
    [object] GetCurrentUser([string]$Token, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("GetCurrentUser() must be implemented by derived class")
    }
    
    # ============================================================================
    # Repository/Project Operations
    # ============================================================================
    
    <#
    .SYNOPSIS
    Searches for repositories/projects matching a query.
    
    .DESCRIPTION
    Searches the platform for repositories or projects that match the provided query string.
    Returns an array of matching repositories/projects.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER Query
    The search query string
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Array - Array of repository/project objects
    #>
    [array] SearchRepositories([string]$Token, [string]$Query, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("SearchRepositories() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Lists all repositories/projects accessible to the authenticated user.
    
    .DESCRIPTION
    Retrieves a list of all repositories or projects that the authenticated user has access to.
    Supports pagination for large result sets.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Array - Array of repository/project objects
    #>
    [array] ListUserRepositories([string]$Token, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("ListUserRepositories() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets detailed information about a specific repository/project.
    
    .DESCRIPTION
    Retrieves detailed information about a repository or project by its path.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER RepoPath
    The repository/project path (e.g., "owner/repo" for GitHub, "group/project" for GitLab)
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Object - Repository/project information object
    #>
    [object] GetRepository([string]$Token, [string]$RepoPath, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("GetRepository() must be implemented by derived class")
    }
    
    # ============================================================================
    # Group Operations (GitLab-specific, returns empty for GitHub)
    # ============================================================================
    
    <#
    .SYNOPSIS
    Searches for groups matching a query.
    
    .DESCRIPTION
    Searches for groups that match the provided query string.
    For GitHub, this returns an empty array as groups are not supported.
    For GitLab, this searches GitLab groups.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER Query
    The search query string
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Array - Array of group objects (empty for GitHub)
    #>
    [array] SearchGroups([string]$Token, [string]$Query, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("SearchGroups() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Lists all groups accessible to the authenticated user.
    
    .DESCRIPTION
    Retrieves a list of all groups that the authenticated user has access to.
    For GitHub, this returns an empty array as groups are not supported.
    For GitLab, this lists all accessible GitLab groups.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Array - Array of group objects (empty for GitHub)
    #>
    [array] ListUserGroups([string]$Token, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("ListUserGroups() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets detailed information about a specific group.
    
    .DESCRIPTION
    Retrieves detailed information about a group by its path.
    For GitHub, this returns null as groups are not supported.
    For GitLab, this retrieves GitLab group information.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER GroupPath
    The group path (e.g., "group/subgroup" for GitLab)
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    Object - Group information object (null for GitHub)
    #>
    [object] GetGroup([string]$Token, [string]$GroupPath, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("GetGroup() must be implemented by derived class")
    }
    
    # ============================================================================
    # Runner Operations
    # ============================================================================
    
    <#
    .SYNOPSIS
    Gets a runner registration token.
    
    .DESCRIPTION
    Retrieves a registration token that can be used to register a new runner.
    The token is obtained from the platform API.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER TargetPath
    The target path (repository path for GitHub, project/group path for GitLab)
    
    .PARAMETER TargetType
    The target type ("project" or "group" for GitLab, ignored for GitHub)
    
    .PARAMETER InstanceUrl
    The platform instance URL (required for GitLab, optional for GitHub)
    
    .OUTPUTS
    String - Runner registration token
    #>
    [string] GetRunnerRegistrationToken([string]$Token, [string]$TargetPath, [string]$TargetType, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("GetRunnerRegistrationToken() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets the download URL for the runner binary.
    
    .DESCRIPTION
    Returns the URL to download the platform-specific runner binary.
    
    .PARAMETER Version
    The runner version to download (optional, defaults to latest)
    
    .PARAMETER OS
    The operating system (e.g., "win", "linux", "osx")
    
    .PARAMETER Arch
    The architecture (e.g., "x64", "arm64")
    
    .OUTPUTS
    String - Download URL for the runner binary
    #>
    [string] GetRunnerDownloadUrl([string]$Version, [string]$OS, [string]$Arch) {
        throw [System.NotImplementedException]::new("GetRunnerDownloadUrl() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets the runner binary executable name.
    
    .DESCRIPTION
    Returns the name of the runner executable file.
    For GitHub: "Runner.Listener.exe"
    For GitLab: "gitlab-runner.exe"
    
    .OUTPUTS
    String - Runner binary name
    #>
    [string] GetRunnerBinaryName() {
        throw [System.NotImplementedException]::new("GetRunnerBinaryName() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets the command-line arguments for runner configuration.
    
    .DESCRIPTION
    Returns a hashtable of arguments to pass to the runner configuration command.
    The arguments are platform-specific.
    
    .PARAMETER Url
    The platform URL
    
    .PARAMETER Token
    The registration token
    
    .PARAMETER Name
    The runner name
    
    .PARAMETER Tags
    Array of tags/labels for the runner
    
    .PARAMETER Executor
    The executor type (GitLab-specific: "docker", "shell", etc.)
    
    .OUTPUTS
    Hashtable - Command-line arguments for runner configuration
    #>
    [hashtable] GetRunnerConfigureArgs([string]$Url, [string]$Token, [string]$Name, [array]$Tags, [string]$Executor) {
        throw [System.NotImplementedException]::new("GetRunnerConfigureArgs() must be implemented by derived class")
    }
    
    # ============================================================================
    # Docker Operations
    # ============================================================================
    
    <#
    .SYNOPSIS
    Gets the Docker image name for the platform runner.
    
    .DESCRIPTION
    Returns the Docker image name/tag for the platform-specific runner.
    For GitHub: "github-runner"
    For GitLab: "gitlab-runner"
    
    .OUTPUTS
    String - Docker image name
    #>
    [string] GetDockerImageName() {
        throw [System.NotImplementedException]::new("GetDockerImageName() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets environment variables for Docker container.
    
    .DESCRIPTION
    Returns a hashtable of environment variables to pass to the Docker container.
    These variables are used for runner registration and configuration.
    
    .PARAMETER Token
    The access token for authentication
    
    .PARAMETER TargetPath
    The target path (repository/project/group)
    
    .PARAMETER RunnerName
    The name for the runner
    
    .PARAMETER InstanceUrl
    The platform instance URL
    
    .OUTPUTS
    Hashtable - Environment variables for Docker container
    #>
    [hashtable] GetDockerEnvironmentVariables([string]$Token, [string]$TargetPath, [string]$RunnerName, [string]$InstanceUrl) {
        throw [System.NotImplementedException]::new("GetDockerEnvironmentVariables() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Gets the Docker entrypoint script.
    
    .DESCRIPTION
    Returns the entrypoint script content for the Docker container.
    This script handles runner registration and startup.
    
    .OUTPUTS
    String - Docker entrypoint script content
    #>
    [string] GetDockerEntrypointScript() {
        throw [System.NotImplementedException]::new("GetDockerEntrypointScript() must be implemented by derived class")
    }
    
    # ============================================================================
    # Instance URL Management
    # ============================================================================
    
    <#
    .SYNOPSIS
    Gets the default instance URL for the platform.
    
    .DESCRIPTION
    Returns the default instance URL.
    For GitHub: "https://github.com"
    For GitLab: "https://gitlab.com"
    
    .OUTPUTS
    String - Default instance URL
    #>
    [string] GetDefaultInstanceUrl() {
        throw [System.NotImplementedException]::new("GetDefaultInstanceUrl() must be implemented by derived class")
    }
    
    <#
    .SYNOPSIS
    Indicates whether the platform requires an instance URL.
    
    .DESCRIPTION
    Returns true if the platform requires an instance URL to be configured.
    For GitHub: false (always uses github.com)
    For GitLab: true (supports self-hosted instances)
    
    .OUTPUTS
    Boolean - True if instance URL is required, false otherwise
    #>
    [bool] RequiresInstanceUrl() {
        throw [System.NotImplementedException]::new("RequiresInstanceUrl() must be implemented by derived class")
    }
}

# ============================================================================
# Platform Factory Class
# ============================================================================

<#
.SYNOPSIS
Factory class for creating platform provider instances.

.DESCRIPTION
The PlatformFactory class provides static methods for instantiating platform providers,
listing available platforms, and retrieving platform display names. This implements
the Factory Pattern to abstract platform provider creation.
#>
class PlatformFactory {
    <#
    .SYNOPSIS
    Creates and returns a platform provider instance.
    
    .DESCRIPTION
    Factory method that instantiates the appropriate platform provider based on the
    platform name. Supports "github" and "gitlab" platforms.
    
    .PARAMETER PlatformName
    The name of the platform ("github" or "gitlab", case-insensitive)
    
    .OUTPUTS
    IPlatformProvider - An instance of the requested platform provider
    
    .EXAMPLE
    $provider = [PlatformFactory]::GetProvider("github")
    
    .EXAMPLE
    $provider = [PlatformFactory]::GetProvider("gitlab")
    
    .NOTES
    Throws an exception if the platform name is not supported.
    #>
    static [IPlatformProvider] GetProvider([string]$PlatformName) {
        $platformLower = $PlatformName.ToLower()
        
        if ($platformLower -eq "github") {
            # GitHubProvider must be loaded before calling this method
            # Use dynamic type resolution to avoid parse-time errors
            try {
                $instance = Invoke-Expression '[GitHubProvider]::new()'
                return $instance
            }
            catch {
                throw [System.InvalidOperationException]::new("GitHubProvider class not loaded. Please load GitHubProvider.ps1 before calling GetProvider('github'). Error: $($_.Exception.Message)")
            }
        }
        elseif ($platformLower -eq "gitlab") {
            # GitLabProvider must be loaded before calling this method
            try {
                $instance = Invoke-Expression '[GitLabProvider]::new()'
                return $instance
            }
            catch {
                throw [System.InvalidOperationException]::new("GitLabProvider class not loaded. Please load GitLabProvider.ps1 before calling GetProvider('gitlab'). Error: $($_.Exception.Message)")
            }
        }
        else {
            throw [System.ArgumentException]::new("Unsupported platform: $PlatformName. Supported platforms: github, gitlab")
        }
        
        # This line is unreachable but required for PowerShell type checking
        return $null
    }
    
    <#
    .SYNOPSIS
    Returns an array of all supported platform names.
    
    .DESCRIPTION
    Returns a list of all platform identifiers that can be used with GetProvider.
    
    .OUTPUTS
    Array - Array of platform name strings
    
    .EXAMPLE
    $platforms = [PlatformFactory]::GetAvailablePlatforms()
    # Returns: @("github", "gitlab")
    #>
    static [array] GetAvailablePlatforms() {
        return @("github", "gitlab")
    }
    
    <#
    .SYNOPSIS
    Gets the display name for a platform.
    
    .DESCRIPTION
    Returns the human-readable display name for a platform without instantiating
    the full provider. This is useful for UI display before provider creation.
    
    .PARAMETER PlatformName
    The name of the platform ("github" or "gitlab", case-insensitive)
    
    .OUTPUTS
    String - The platform display name
    
    .EXAMPLE
    $displayName = [PlatformFactory]::GetPlatformDisplayName("github")
    # Returns: "GitHub"
    
    .EXAMPLE
    $displayName = [PlatformFactory]::GetPlatformDisplayName("gitlab")
    # Returns: "GitLab"
    
    .NOTES
    This method provides display names without requiring provider instantiation.
    Once providers are implemented, it will delegate to the provider's GetPlatformDisplayName method.
    #>
    static [string] GetPlatformDisplayName([string]$PlatformName) {
        $platformLower = $PlatformName.ToLower()
        
        if ($platformLower -eq "github") {
            return "GitHub"
        }
        elseif ($platformLower -eq "gitlab") {
            return "GitLab"
        }
        else {
            throw [System.ArgumentException]::new("Unsupported platform: $PlatformName. Supported platforms: github, gitlab")
        }
        
        # This line is unreachable but required for PowerShell type checking
        return ""
    }
}
