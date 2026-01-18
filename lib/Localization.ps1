# Localization Module
# English-only to avoid encoding issues

class LocalizationStrings {
    [hashtable]$Strings
    [string]$Language
    
    LocalizationStrings([string]$lang) {
        $this.Language = "en"  # Force English only
        $this.Strings = @{}
        $this.LoadStrings()
    }
    
    [string] Get([string]$key) {
        if ($this.Strings.ContainsKey($key)) {
            return $this.Strings[$key]
        }
        return $key
    }
    
    [void] LoadStrings() {
        $this.LoadEnglish()
    }
    
    [void] LoadEnglish() {
        $this.Strings = @{
            # Main Menu
            "menu_title" = "Runner Manager v3.0"
            "menu_subtitle" = "Advanced Infrastructure Suite"
            "menu_platform" = "Platform"
            "menu_instance" = "Instance"
            "menu_target" = "Target"
            "menu_repository" = "Repository"
            "menu_group" = "Group"
            "menu_project" = "Project"
            "menu_not_configured" = "Not configured"
            "menu_token" = "Token"
            "menu_configured" = "Configured"
            "menu_not_set" = "Not set"
            "menu_telegram" = "Telegram"
            "menu_enabled" = "Enabled"
            "menu_disabled" = "Disabled"
            "menu_users" = "users"
            "menu_docker_runners" = "Docker Runners"
            "menu_containers" = "containers"
            
            # Menu sections
            "menu_configuration" = "Configuration"
            "menu_runner_management" = "Runner Management"
            "menu_autostart" = "Auto-Start"
            "menu_advanced" = "Advanced"
            "menu_infrastructure" = "Infrastructure Suite"
            "menu_exit" = "Exit"
            
            # Menu options
            "menu_configure_token" = "Configure {0} Token"
            "menu_select_project_group" = "Select Project/Group"
            "menu_select_repository" = "Select Repository"
            "menu_configure_secrets" = "Configure GitHub Secrets (Auto)"
            "menu_configure_instance_url" = "Configure Instance URL"
            "menu_switch_platform" = "Switch Platform (GitHub <-> GitLab)"
            "menu_install_runner" = "Install Runner"
            "menu_start_runner" = "Start Runner"
            "menu_stop_runner" = "Stop Runner"
            "menu_check_status" = "Check Status"
            "menu_view_logs" = "View Logs"
            "menu_view_active_runners" = "View Active Runners"
            "menu_enable_autostart" = "Enable Auto-Start (on boot)"
            "menu_disable_autostart" = "Disable Auto-Start"
            "menu_uninstall_runner" = "Uninstall Runner"
            "menu_clear_config" = "Clear Configuration"
            "menu_telegram_notifications" = "Telegram Notifications"
            "menu_docker_management" = "Docker Container Management"
            
            # Common
            "select_option" = "Select option"
            "press_enter" = "Press Enter to continue"
            "cancelled" = "Cancelled"
            "error" = "Error"
            "success" = "Success"
            "warning" = "Warning"
            "yes" = "Yes"
            "no" = "No"
            "continue" = "Continue"
            "back" = "Back"
            "invalid_option" = "Invalid option"
            "goodbye" = "Goodbye!"
            
            # Token Configuration
            "token_config_title" = "{0} Token Configuration"
            "token_config_help_github" = "You need a Personal Access Token with permissions:"
            "token_config_perm_repo" = "repo (Full control of private repositories)"
            "token_config_perm_workflow" = "workflow (Update GitHub Action workflows)"
            "token_config_perm_api" = "api (Full API access)"
            "token_config_create_github" = "Create token: https://github.com/settings/tokens/new"
            "token_config_create_gitlab" = "Create token: https://gitlab.com/-/profile/personal_access_tokens"
            "token_config_create_gitlab_self" = "Or for self-hosted: https://your-gitlab.com/-/profile/personal_access_tokens"
            "token_current" = "Current token"
            "token_update" = "Update token? (y/N)"
            "token_enter_github" = "Enter GitHub Token (ghp_...)"
            "token_enter_gitlab" = "Enter GitLab Personal Access Token"
            "token_validating" = "Validating {0} token..."
            "token_valid" = "Token valid! Authenticated as: {0}"
            "token_invalid" = "Token validation failed"
            "token_check_retry" = "Please check your token and try again"
            "token_validation_error" = "Token validation error: {0}"
            "token_storage_question" = "Where to store the token?"
            "token_storage_env" = "Windows Environment Variable (User-level, persistent)"
            "token_storage_file" = "Configuration File (Local, base64 encoded)"
            "token_storage_session" = "Session Only (Not saved, re-enter each time)"
            "token_saved_env" = "Token saved to environment variable {0}"
            "token_saved_file" = "Token saved to configuration file (base64 encoded)"
            "token_saved_session" = "Token will be used for this session only"
            "token_not_saved" = "Invalid option, token not saved"
            
            # Platform Selection
            "platform_selection_title" = "Platform Selection"
            "platform_select_prompt" = "Select CI/CD platform:"
            "platform_github" = "GitHub Actions"
            "platform_gitlab" = "GitLab CI/CD"
            "platform_switched_github" = "Switched to GitHub"
            "platform_switched_gitlab" = "Switched to GitLab"
            "platform_invalid" = "Invalid selection"
            
            # Repository/Project Selection
            "repo_selection_title" = "{0} Target Selection"
            "repo_token_not_configured" = "{0} token not configured"
            "repo_configure_token_first" = "Please configure token first (option 1)"
            "repo_fetching" = "Fetching your {0}..."
            "repo_none_found" = "No {0} found"
            "repo_search_prompt" = "Search {0} (type to filter, Enter to select):"
            "repo_search" = "Search"
            "repo_found" = "Found {0} {1}:"
            "repo_select_prompt" = "Select {0} (1-{1})"
            "repo_no_match" = "No {0} match '{1}'"
            "repo_set_to" = "{0} set to: {1}"
            "repo_error_fetching" = "Error fetching {0}: {1}"
            "repo_repositories" = "repositories"
            "repo_projects" = "projects"
            "repo_groups" = "groups"
            
            # Target Type Selection
            "target_type_title" = "Target Type Selection"
            "target_type_prompt" = "Register runner for:"
            "target_type_project" = "Project (single project)"
            "target_type_group" = "Group (all projects in group)"
        }
    }
}

# Global localization instance
$global:Loc = $null

function Initialize-Localization {
    param(
        [string]$Language = "en"
    )
    
    $global:Loc = [LocalizationStrings]::new($Language)
}

function Get-LocalizedString {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$false)]
        [object[]]$Args
    )
    
    if ($null -eq $global:Loc) {
        Initialize-Localization
    }
    
    $text = $global:Loc.Get($Key)
    
    if ($Args -and $Args.Count -gt 0) {
        try {
            return $text -f $Args
        } catch {
            # If formatting fails, return original text
            return $text
        }
    }
    
    return $text
}

function Set-ApplicationLanguage {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("en")]
        [string]$Language
    )
    
    $global:Loc = [LocalizationStrings]::new($Language)
}

# Alias for convenience
Set-Alias -Name "L" -Value "Get-LocalizedString" -Scope Global
