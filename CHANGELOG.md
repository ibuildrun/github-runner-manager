# Changelog - GitHub Actions Self-Hosted Runner Manager

## [3.0.0] - 2026-01-17

### 🚀 Universal Runner Manager

#### Added
- 🔍 **Repository Search** - Search and select from your GitHub repositories via API
- 🔐 **Flexible Token Storage** - Store token in environment variable, config file, or session only
- ✅ **Token Validation** - Validates token before saving
- 🎯 **Universal Support** - Works with any GitHub repository
- 📊 **Enhanced Status** - Shows configuration info in status display
- 🔄 **Configuration Persistence** - Saves settings across sessions
- 🧹 **Clear Configuration** - Option to reset all settings
- 📋 **Interactive Repository Browser** - Search through repositories with filtering

#### Changed
- 🔄 Renamed from "AVYX GitHub Actions Runner Manager" to "GitHub Actions Self-Hosted Runner Manager"
- 🔄 Improved menu structure with categorized sections
- 🔄 Enhanced error handling and user feedback
- 🔄 Better security with multiple token storage methods
- 🔄 Repository-specific scheduled task naming
- 🔄 No longer requires manual configuration editing

#### Removed
- ❌ Hard-coded repository references
- ❌ Requirement to manually edit configuration files

#### Security
- 🔒 Token validation before storage
- 🔒 Multiple storage options for different security needs
- 🔒 Base64 encoding for file storage (note: not encryption)
- 🔒 Environment variable storage recommended for best security

### Configuration File

The script now creates `.runner-config.json` with:
```json
{
  "Repository": "owner/repo-name",
  "TokenStorage": "Environment|File|None",
  "TokenEncrypted": "base64-encoded-token",
  "LastUpdated": "2026-01-17T..."
}
```

### Token Storage Options

1. **Environment Variable** (Recommended)
   - Stored in `GITHUB_RUNNER_TOKEN` user environment variable
   - Persistent across sessions
   - Most secure option

2. **Configuration File**
   - Stored in `.runner-config.json` (base64 encoded)
   - Local to deploy directory
   - Portable with project

3. **Session Only**
   - Not saved anywhere
   - Must re-enter each time
   - Most secure for temporary use

### Migration from 2.x

1. Run the new script: `.\runner.ps1`
2. Configure token (Option 1) - choose storage method
3. Select repository (Option 2) - search and select
4. Existing runner installation will be detected
5. Reinstall if needed to update configuration

---

## [2.0.0] - 2026-01-17

### 🎉 Complete Deploy System Overhaul

#### Added
- ✅ Simplified workflow for deploy via self-hosted runner
- ✅ SFTP/lftp for reliable shared hosting uploads
- ✅ Automatic `.env` save and restore between deploys
- ✅ Separate frontend and backend builds in different jobs
- ✅ PowerShell script `start.ps1` for quick runner start
- ✅ Batch file `start-runner.bat` for one-click start
- ✅ Detailed `QUICK_START.md` with step-by-step instructions
- ✅ Updated `README.md` with full documentation
- ✅ `lftp` installation in Docker image for SFTP deploy

#### Changed
- 🔄 Workflow now uses artifacts for passing built files
- 🔄 Simplified deploy structure - removed unnecessary fallback mechanisms
- 🔄 Improved health checks with more detailed information
- 🔄 Telegram notifications now show more details

#### Removed
- ❌ Removed old `deploy-new.yml` workflow
- ❌ Removed complex SSH fallback mechanisms
- ❌ Removed webhook deploy dependency

#### Fixed
- 🐛 Fixed SSH connection issues to REG.RU
- 🐛 Fixed file uploads to shared hosting
- 🐛 Fixed `.env` preservation between deploys
- 🐛 Fixed storage directory permissions

---

## [1.0.0] - 2026-01-15

### First Release
- Basic self-hosted runner
- Deploy via SSH/SCP
- Webhook fallback
- Telegram notifications
