# GitHub Actions Self-Hosted Runner Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

Universal PowerShell-based manager for GitHub Actions self-hosted runners on Windows. Simplifies installation, configuration, and management of runners for any GitHub repository.

[🇷🇺 Русская версия](README.ru.md)

## ✨ Features

- 🔍 **Repository Search** - Search and select from your GitHub repositories via API
- 🔐 **Flexible Token Storage** - Store token in environment variable, config file, or session only
- 📋 **Interactive Menu** - Easy-to-use menu interface with categorized options
- 🚀 **Auto-Start** - Configure runner to start automatically on Windows boot
- 🔄 **Auto-Restart** - Automatic restart on failures (3 attempts)
- 📊 **Status Monitoring** - Real-time runner status and configuration info
- 📝 **Log Viewing** - View recent runner logs directly from menu
- ✅ **Token Validation** - Validates GitHub token before saving
- 🎯 **Universal** - Works with any GitHub repository (public or private)

## 🚀 Quick Start

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or higher
- GitHub Personal Access Token with `repo` and `workflow` permissions
- Administrator privileges (only for auto-start feature)

### Installation

1. **Clone or download this repository**
   ```powershell
   git clone https://github.com/ibuildrun/github-runner-manager.git
   cd github-runner-manager
   ```

2. **Run the script**
   ```powershell
   .\runner.ps1
   ```

3. **Configure GitHub Token** (Option 1)
   - Create token at: https://github.com/settings/tokens/new
   - Required permissions: `repo`, `workflow`
   - Choose storage method:
     - **Environment Variable** - Persistent, user-level (recommended)
     - **Config File** - Local, base64 encoded
     - **Session Only** - Not saved, re-enter each time

4. **Select Repository** (Option 2)
   - Search through your repositories
   - Select the repository to attach the runner to

5. **Install Runner** (Option 3)
   - Downloads and configures the runner
   - Registers with selected repository

6. **Start Runner** (Option 4)
   - Starts the runner in background

## 📖 Usage

### Menu Options

#### Configuration
- **1. Configure GitHub Token** - Set up GitHub Personal Access Token with flexible storage options
- **2. Select Repository** - Search and select repository via GitHub API

#### Runner Management
- **3. Install Runner** - Download and configure GitHub Actions runner
- **4. Start Runner** - Start the runner (background or scheduled task)
- **5. Stop Runner** - Stop all runner processes
- **6. Check Status** - View runner installation and running status
- **7. View Logs** - Show recent runner logs (last 50 lines)

#### Auto-Start
- **8. Enable Auto-Start** - Configure runner to start on Windows boot (requires admin)
- **9. Disable Auto-Start** - Remove auto-start configuration (requires admin)

#### Advanced
- **10. Uninstall Runner** - Completely remove runner (requires admin)
- **11. Clear Configuration** - Reset repository and token configuration

## 🔐 Token Storage Options

### 1. Environment Variable (Recommended)
- Stored in Windows user environment variable `GITHUB_RUNNER_TOKEN`
- Persistent across sessions and reboots
- Accessible to all PowerShell sessions
- Most secure option for regular use

**View token:**
```powershell
$env:GITHUB_RUNNER_TOKEN
```

**Remove token:**
```powershell
[System.Environment]::SetEnvironmentVariable("GITHUB_RUNNER_TOKEN", $null, "User")
```

### 2. Configuration File
- Stored in `.runner-config.json` (base64 encoded)
- Local to the script directory
- Portable with the project
- Note: Base64 is NOT encryption, just encoding

### 3. Session Only
- Not saved anywhere
- Must re-enter token each time script runs
- Most secure for temporary or one-time use

## 📁 Project Structure

```
github-runner-manager/
├── runner.ps1                    # Main entry point
├── lib/                          # Modules
│   ├── Config.ps1                # Configuration management
│   ├── GitHub.ps1                # GitHub API integration
│   ├── UI.ps1                    # User interface
│   ├── TokenManager.ps1          # Token management
│   ├── RepositorySelector.ps1    # Repository selection
│   ├── RunnerInstaller.ps1       # Runner installation
│   ├── RunnerManager.ps1         # Process management
│   └── AutoStart.ps1             # Auto-start functionality
├── .runner-config.json           # Configuration file (auto-generated)
├── .gitignore                    # Git ignore rules
├── README.md                     # This file (English)
├── README.ru.md                  # Russian documentation
└── CHANGELOG.md                  # Version history
```

## 🔧 Configuration File Format

The `.runner-config.json` file stores:
```json
{
  "Repository": "owner/repo-name",
  "TokenStorage": "Environment|File|None",
  "TokenEncrypted": "base64-encoded-token",
  "LastUpdated": "2026-01-17T..."
}
```

## 🐛 Troubleshooting

### Token validation fails
- Verify token has `repo` and `workflow` permissions
- Check token hasn't expired
- Ensure token is for the correct GitHub account
- Try creating a new token

### Repository search returns no results
- Verify token has access to repositories
- Check search term spelling
- Try searching with partial repository name
- Ensure you have at least one repository

### Runner shows as offline
- Check if process is running: `Get-Process -Name "Runner.Listener"`
- View logs: Select option 7 in menu
- Restart runner: Stop (option 5) then Start (option 4)
- Check GitHub repository settings

### Auto-start not working
- Ensure you ran script as Administrator
- Check scheduled task: `Get-ScheduledTask -TaskName "GitHub Runner - *"`
- Verify task is enabled and set to run at startup
- Check task logs in Task Scheduler

### Installation fails
- Verify GitHub token has correct permissions
- Check internet connection
- Ensure C:\actions-runner directory is accessible
- Try running as Administrator
- Check Windows Defender or antivirus settings

## 🔒 Security Notes

- Never commit `.runner-config.json` to version control (already in .gitignore)
- Environment variable storage is more secure than file storage
- Token is validated before being saved
- Base64 encoding is NOT encryption - use environment variable for better security
- Keep your GitHub token secure and rotate it regularly
- Use tokens with minimal required permissions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Create GitHub Token](https://github.com/settings/tokens/new)
- [GitHub Actions Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Runner Releases](https://github.com/actions/runner/releases)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)

## 📊 System Requirements

- **OS**: Windows 10 (1809+) or Windows 11
- **PowerShell**: 5.1 or higher
- **RAM**: 2 GB minimum
- **Disk Space**: 500 MB for runner + space for builds
- **Network**: Internet connection for GitHub API and runner downloads

## 🎯 Use Cases

- **Personal Projects** - Run CI/CD for your personal repositories
- **Small Teams** - Cost-effective alternative to GitHub-hosted runners
- **Private Networks** - Run builds in your own network environment
- **Custom Hardware** - Use specific hardware or software configurations
- **Learning** - Understand GitHub Actions runner internals

## ⚡ Performance Tips

- Use SSD for runner installation directory
- Ensure adequate RAM for your build processes
- Configure Windows Defender exclusions for runner directory
- Use wired network connection for stability
- Monitor disk space regularly

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review [GitHub Actions documentation](https://docs.github.com/en/actions)
3. Open an [issue](https://github.com/ibuildrun/github-runner-manager/issues)

## 🙏 Acknowledgments

- GitHub Actions team for the runner software
- PowerShell community for best practices
- All contributors to this project

---

Made with ❤️ for the GitHub community
