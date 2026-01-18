# AVYX Deploy - GitHub Actions Runner

Self-hosted GitHub Actions runner for AVYX project deployment.

## Quick Start

```powershell
# Run as Administrator
cd deploy
.\runner.ps1
```

## Features

- Interactive menu for easy management
- Auto-start on Windows boot
- Automatic restart on failures
- Background execution
- Log viewing

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges (for auto-start)
- GitHub Personal Access Token with `repo` and `workflow` permissions

## Menu Options

1. **Install Runner** - Download and configure GitHub Actions runner
2. **Start Runner** - Start the runner (background or scheduled task)
3. **Stop Runner** - Stop all runner processes
4. **Check Status** - View runner installation and running status
5. **Enable Auto-Start** - Configure runner to start on Windows boot
6. **Disable Auto-Start** - Remove auto-start configuration
7. **Uninstall Runner** - Completely remove runner
8. **View Logs** - Show recent runner logs

## Environment Variables

Set GitHub token before running:

```powershell
$env:GITHUB_TOKEN = "ghp_your_token_here"
```

Or the script will prompt you for it.

## File Structure

```
deploy/
├── runner.ps1              # Main management script
├── .env.runner.example     # Example environment file
├── README.md               # This file
└── CHANGELOG.md            # Version history
```

## Troubleshooting

### Runner shows as offline
- Check if process is running: `Get-Process -Name "Runner.Listener"`
- View logs: Select option 8 in menu
- Restart runner: Stop (option 3) then Start (option 2)

### Auto-start not working
- Ensure you ran script as Administrator
- Check scheduled task: `Get-ScheduledTask -TaskName "AVYX GitHub Actions Runner"`
- Verify task is enabled and set to run at startup

### Installation fails
- Verify GitHub token has correct permissions
- Check internet connection
- Ensure C:\actions-runner directory is accessible

## Links

- Runner Status: https://github.com/ibuildrun/avyx/settings/actions/runners
- GitHub Actions Docs: https://docs.github.com/en/actions/hosting-your-own-runners
