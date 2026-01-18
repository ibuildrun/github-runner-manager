# Changelog - GitHub Runner Infrastructure Manager

All notable changes to this project will be documented in this file.

## [3.0.2] - 2026-01-18

### 🔒 Security

**Removed Hardcoded Server Credentials**
- ✅ Removed hardcoded REG.RU server information from previous versions
- ✅ Added configurable SSH_HOST, SSH_PORT, SSH_USER parameters
- ✅ Users now configure their own server details via interactive prompts
- ✅ No default server credentials in code

**Enhanced SSH Configuration**
- ✅ Added SSH connection testing before saving credentials
- ✅ Added automatic SSH key generation and deployment
- ✅ Added passwordless authentication setup (SSH_PRIVATE_KEY)
- ✅ Interactive wizard for SSH key configuration

**IMPORTANT SECURITY NOTICE:**
Previous versions (before 3.0.2) contained hardcoded server credentials in commit history. 
If you cloned this repository before 2026-01-18, please:
1. Update to latest version: `git pull origin main`
2. Rotate any credentials that may have been exposed
3. Use the new SSH configuration system (option 3 in menu)

## [3.0.1] - 2026-01-18

### 🐛 Bug Fixes

**Fixed TelegramConfig Type Conversion Error**
- ✅ Resolved type conflict when running script multiple times in same PowerShell session
- ✅ Changed `GetTelegramConfig()` to return hashtable instead of typed object
- ✅ Changed `SaveTelegramConfig()` to accept hashtable parameter
- ✅ Added `ConvertTo-TelegramConfigObject` helper function for internal use
- ✅ Updated all Telegram notification calls to use hashtable approach
- ✅ Script can now be run multiple times without restarting PowerShell
- ✅ Updated TROUBLESHOOTING.md with fix status

**Technical Details:**
- Modified `lib/Config.ps1`: `GetTelegramConfig()` and `SaveTelegramConfig()` methods
- Modified `lib/TelegramNotifier.ps1`: Added helper function and updated all usages
- Modified `runner.ps1`: Updated Telegram notification calls
- Modified `lib/DockerManager.ps1`: Updated Telegram notification calls

## [3.0.0] - 2026-01-17

### 🚀 Infrastructure Suite - Major Release

#### Added - Core Infrastructure Features

**🐳 Docker Container Management**
- ✅ Automatic Docker image building for GitHub runners
- ✅ Container lifecycle management (start, stop, remove)
- ✅ Bulk deployment - deploy multiple containers simultaneously
- ✅ Container logs viewing directly from menu
- ✅ Runner isolation in separate containers
- ✅ Easy horizontal scaling with containers
- ✅ Ubuntu 22.04 based runner images
- ✅ Automatic runner registration and cleanup

**📱 Telegram Bot Integration**
- ✅ Multiple users notification support
- ✅ Send notifications for runner events (start, stop, deploy)
- ✅ Support for unlimited chat IDs
- ✅ Message types: Info, Success, Warning, Error
- ✅ Bot connection testing
- ✅ User management (add/remove chat IDs)
- ✅ Automatic notifications on runner lifecycle events
- ✅ Bulk deployment notifications

**🔧 Enhanced Configuration System**
- ✅ Extended RunnerConfig class with nested object support
- ✅ Persistent storage for Docker runners metadata
- ✅ Telegram configuration persistence
- ✅ Deep JSON serialization (depth 10)
- ✅ Backward compatible with 2.x configs
- ✅ GetTelegramConfig() method
- ✅ SaveTelegramConfig() method
- ✅ AddDockerRunner() method
- ✅ GetDockerRunners() method

#### Changed

**🎨 User Interface**
- 🔄 Updated main menu with "Infrastructure Suite" section
- 🔄 Enhanced status display with Telegram and Docker info
- 🔄 Added emoji indicators for better UX
- 🔄 Version bumped to 3.0 in header
- 🔄 New menu options: 14 (Telegram), 15 (Docker)

**⚙️ Core Functionality**
- 🔄 Runner start/stop now sends Telegram notifications automatically
- 🔄 Improved error handling in Docker operations
- 🔄 Better process management for containers
- 🔄 Enhanced logging throughout all modules

**📦 Modules**
- 🔄 `Config.ps1` - Complete rewrite with nested config support
- 🔄 `UI.ps1` - Updated menu and status displays
- 🔄 `runner.ps1` - Added Telegram notifications on runner events

#### New Modules

- ✨ `TelegramNotifier.ps1` - Complete Telegram integration
  - Send-TelegramNotification function
  - Test-TelegramConnection function
  - Get-TelegramChatId function
  - Invoke-TelegramConfiguration function

- ✨ `DockerManager.ps1` - Complete Docker management
  - Test-DockerInstalled function
  - Test-DockerRunning function
  - New-DockerRunnerImage function
  - Start-DockerRunner function
  - Stop-DockerRunner function
  - Remove-DockerRunner function
  - Get-DockerRunners function
  - Show-DockerRunnerLogs function
  - Invoke-DockerManagement function

#### Documentation

- 📝 Completely rewritten README.md
  - Infrastructure-focused documentation
  - Docker setup and usage guide
  - Telegram bot configuration guide
  - Bulk deployment examples
  - Architecture diagrams
  - Use case scenarios
  - Troubleshooting section expanded
- 📝 Updated CHANGELOG.md with detailed changes
- 📝 Removed redundant documentation files (README.ru.md, QUICK_START.ru.md, CHEATSHEET.md, RELEASE_NOTES.md)
- 📝 Single source of truth - README.md only

#### Technical Details

**Docker Implementation**
- Base image: Ubuntu 22.04
- Runner version: 2.311.0
- Automatic token retrieval via GitHub API
- Graceful shutdown with cleanup
- Environment variables: GITHUB_TOKEN, GITHUB_REPOSITORY, RUNNER_NAME
- Labels: docker, self-hosted

**Telegram Implementation**
- API: Telegram Bot API
- Message format: Markdown
- Timestamp in all messages
- Error handling for failed sends
- Multiple recipients support

**Configuration Schema**
```json
{
  "Repository": "owner/repo",
  "TokenStorage": "Environment|File|None",
  "TokenEncrypted": "base64",
  "LastUpdated": "ISO8601",
  "Telegram": {
    "BotToken": "string",
    "ChatIds": ["array"],
    "Enabled": boolean
  },
  "DockerRunners": [{
    "ContainerId": "string",
    "Repository": "string",
    "RunnerName": "string",
    "ImageTag": "string",
    "Created": "ISO8601",
    "Status": "string"
  }]
}
```

#### Breaking Changes

- ⚠️ Configuration file format changed (backward compatible)
- ⚠️ New dependencies: Docker Desktop (optional)
- ⚠️ New dependencies: Telegram Bot (optional)
- ⚠️ Menu numbering changed (added options 14, 15)

#### Migration from 2.x

1. Existing configurations will be automatically migrated
2. No action required for basic functionality
3. To use Docker: Install Docker Desktop
4. To use Telegram: Create bot and configure (option 14)
5. All existing runners will continue to work

---

## [2.0.0] - 2026-01-17

### 🎉 Universal Runner Manager

#### Added
- 🔍 Repository Search via GitHub API
- 🔐 Flexible Token Storage (Environment/File/Session)
- ✅ Token Validation
- 🎯 Universal Repository Support
- 📊 Enhanced Status Display
- 🔄 Configuration Persistence
- 🧹 Clear Configuration Option

#### Changed
- 🔄 Renamed to "GitHub Actions Self-Hosted Runner Manager"
- 🔄 Improved menu structure
- 🔄 Enhanced error handling
- 🔄 Better security with multiple token storage methods

#### Removed
- ❌ Hard-coded repository references
- ❌ Manual configuration editing requirement

---

## [1.0.0] - 2026-01-15

### First Release
- Basic self-hosted runner
- Deploy via SSH/SCP
- Webhook fallback
- Telegram notifications (basic)
