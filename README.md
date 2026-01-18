# GitHub Runner Infrastructure Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)](https://www.docker.com/)
[![Telegram](https://img.shields.io/badge/Telegram-Bot-26A5E4.svg)](https://telegram.org/)

Comprehensive solution for managing GitHub Actions self-hosted runners with Docker container support and Telegram notifications. Full-featured infrastructure suite for CI/CD.

> **SECURITY NOTICE:** Version 3.0.2+ removes all hardcoded credentials. If you're using an older version, please update immediately and rotate any exposed credentials.

## Features

### Core Functions
- **Repository Search** - Search and select via GitHub API
- **Flexible Token Storage** - Environment variable, config file or session only
- **Interactive Menu** - User-friendly interface with categories
- **Auto-Start** - Launch runner on Windows startup
- **Status Monitoring** - Real-time status information
- **Log Viewing** - View logs directly from menu

### Docker Containers
- **Image Building** - Automatic Docker image creation for runners
- **Container Management** - Start, stop, remove containers
- **Bulk Deployment** - Launch multiple runners with one command
- **Isolation** - Each runner in separate container
- **Scaling** - Easy addition of new runners

### Telegram Notifications
- **Multiple Users** - Notifications for multiple people
- **Notification Types** - Info, Success, Warning, Error
- **Events** - Runner start/stop, container deployment
- **Connection Testing** - Verify bot connectivity
- **User Management** - Add/remove chat IDs

## Quick Start

### Requirements

- Windows 10/11
- PowerShell 5.1+
- GitHub Personal Access Token (`repo`, `workflow`)
- Docker Desktop (optional, for containers)
- Telegram Bot Token (optional, for notifications)

### Installation

```powershell
git clone https://github.com/yourusername/github-runner-infrastructure.git
cd github-runner-infrastructure
.\runner.ps1
```

### Basic Setup

1. **Configure GitHub Token** (Option 1)
   - Create token: https://github.com/settings/tokens/new
   - Scopes: `repo`, `workflow`
   - Choose storage method

2. **Select Repository** (Option 2)
   - Search your repositories
   - Select repository for runner

3. **Install Runner** (Option 5)
   - Download and configure
   - Register with repository

4. **Start Runner** (Option 6)
   - Launch in background

## Telegram Setup

### Creating Bot

1. Find @BotFather in Telegram
2. Send `/newbot`
3. Follow instructions
4. Save Bot Token

### Getting Chat ID

1. Send message to your bot
2. Open: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
3. Find `"chat":{"id":123456789}`
4. Use this number as Chat ID

### Script Configuration

1. Select **Option 14** in menu
2. Enter Bot Token
3. Add user Chat IDs
4. Test notifications

## Working with Docker

### Installing Docker

1. Download Docker Desktop: https://www.docker.com/products/docker-desktop
2. Install and launch
3. Verify Docker is running: `docker --version`

### Creating Runner Image

```powershell
# In menu select: 15 -> 1
# Or directly:
New-DockerRunnerImage -ImageTag "github-runner:latest"
```

### Starting Container

```powershell
# In menu: 15 -> 2
# Specify runner name or leave empty for auto-generation
```

### Bulk Deployment

```powershell
# In menu: 15 -> 7
# Specify number of containers (e.g., 5)
# All containers will be launched automatically
```

### Container Management

```powershell
# List containers
docker ps -a

# Stop
docker stop <container_name>

# Remove
docker rm <container_name>

# Logs
docker logs <container_name>
```

## Menu Structure

### Configuration
- **1** - Configure GitHub Token
- **2** - Select Repository
- **3** - Configure GitHub Secrets (Auto)
- **4** - View Configured Secrets

### Runner Management
- **5** - Install Runner
- **6** - Start Runner
- **7** - Stop Runner
- **8** - Check Status
- **9** - View Logs

### Auto-Start
- **10** - Enable Auto-Start (on boot)
- **11** - Disable Auto-Start

### Advanced
- **12** - Uninstall Runner
- **13** - Clear Configuration

### Infrastructure Suite
- **14** - Telegram Notifications
- **15** - Docker Container Management

## Architecture

```
github-runner-infrastructure/
├── runner.ps1                    # Main script
├── lib/                          # Modules
│   ├── Config.ps1                # Configuration management
│   ├── GitHub.ps1                # GitHub API
│   ├── UI.ps1                    # Interface
│   ├── TokenManager.ps1          # Token management
│   ├── RepositorySelector.ps1    # Repository selection
│   ├── SecretsManager.ps1        # GitHub secrets
│   ├── RunnerInstaller.ps1       # Runner installation
│   ├── RunnerManager.ps1         # Process management
│   ├── AutoStart.ps1             # Auto-start
│   ├── TelegramNotifier.ps1      # Telegram integration
│   └── DockerManager.ps1         # Docker management
├── .runner-config.json           # Configuration (auto-generated)
├── README.md                     # Documentation
├── CHANGELOG.md                  # Version history
└── LICENSE                       # MIT license
```

## Configuration

### .runner-config.json Format

```json
{
  "Repository": "owner/repo-name",
  "TokenStorage": "Environment|File|None",
  "TokenEncrypted": "base64-encoded-token",
  "LastUpdated": "2026-01-17T...",
  "Telegram": {
    "BotToken": "123456:ABC-DEF...",
    "ChatIds": ["123456789", "987654321"],
    "Enabled": true
  },
  "DockerRunners": [
    {
      "ContainerId": "abc123...",
      "Repository": "owner/repo",
      "RunnerName": "docker-runner-1",
      "ImageTag": "github-runner:latest",
      "Created": "2026-01-17T...",
      "Status": "Running"
    }
  ]
}
```

## Usage Examples

### Scenario 1: Local Runner

```powershell
.\runner.ps1
# 1 -> Configure token
# 2 -> Select repository
# 5 -> Install runner
# 6 -> Start runner
# 10 -> Enable auto-start
```

### Scenario 2: Docker Runners with Notifications

```powershell
.\runner.ps1
# 1 -> Configure token
# 2 -> Select repository
# 14 -> Configure Telegram
# 15 -> Docker Management
#   1 -> Build image
#   7 -> Bulk deployment (5 containers)
```

### Scenario 3: Infrastructure Monitoring

```powershell
.\runner.ps1
# 8 -> Check status
# 15 -> Docker Management
#   3 -> List containers
#   6 -> View logs
```

## Security

- Never commit `.runner-config.json` (already in .gitignore)
- Environment variable is safer than file storage
- Base64 is NOT encryption - use environment variable
- Regularly update GitHub tokens
- Use minimum required permissions for tokens
- Keep Telegram Bot Token secure

## Troubleshooting

### Docker Won't Start

```powershell
# Check installation
docker --version

# Verify Docker Desktop is running
docker ps
```

### Telegram Notifications Not Arriving

1. Verify Bot Token
2. Ensure you sent first message to bot
3. Check Chat ID via API
4. Test via option 14 -> 4

### Runner Shows Offline

1. Check process: `Get-Process -Name "Runner.Listener"`
2. View logs: Option 9
3. Restart: Option 7 -> Option 6

## Performance

### Docker Recommendations

- Use SSD for Docker volumes
- Minimum 2GB RAM per container
- Wired connection for stability
- Monitor disk usage

### Scaling

- Up to 10 containers on regular PC
- Up to 50+ on server hardware
- Use Docker Swarm for clusters
- Configure load balancing for high loads

## Contributing

Pull Requests are welcome!

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

MIT License - see [LICENSE](LICENSE)

## Useful Links

- [GitHub Token](https://github.com/settings/tokens/new)
- [GitHub Actions Docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [PowerShell Docs](https://docs.microsoft.com/en-us/powershell/)

## Key Features

- Fully PowerShell - no dependencies
- Modular architecture - easy to extend
- Docker integration - modern containerization
- Telegram bots - instant notifications
- Multiple users - team collaboration
- Bulk deployment - fast scaling
- Open Source - MIT license

---

Made for DevOps community
