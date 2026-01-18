# Troubleshooting Guide

## Common Issues and Solutions

### 1. TelegramConfig Type Conversion Error

**Error Message:**
```
Не удается преобразовать значение "TelegramConfig" типа "TelegramConfig" в тип "TelegramConfig"
Cannot convert value "TelegramConfig" of type "TelegramConfig" to type "TelegramConfig"
```

**Status:** FIXED in latest version

**Cause:** 
This error occurred in older versions when running the script multiple times in the same PowerShell session. PowerShell would load the TelegramConfig class definition each time, causing a type conflict.

**Solution:**
Update to the latest version of the script. The issue has been resolved by using hashtables instead of typed objects for Telegram configuration.

If you still encounter this error with an older version:
1. **Close and reopen PowerShell** (Recommended)
   - Close your current PowerShell window
   - Open a new PowerShell window
   - Run the script again: `.\runner.ps1`

2. **Update to latest version**
   ```powershell
   git pull origin main
   ```

### 2. Telegram "chat not found" Error

**Error Message:**
```
Bad Request: chat not found
```

**Cause:**
The bot cannot send messages to a chat that hasn't initiated conversation with it.

**Solution:**
1. Open Telegram
2. Search for your bot (use the bot username)
3. Click "START" button
4. Try sending test notification again

### 3. Repository Search Shows No Results

**Cause:**
- Token doesn't have correct permissions
- No repositories accessible with current token

**Solution:**
1. Check token has `repo` scope for GitHub
2. Check token has `api` scope for GitLab
3. Verify token is not expired
4. Try reconfiguring token (Option 1)

### 4. Docker Commands Fail

**Cause:**
- Docker Desktop not running
- Docker not installed

**Solution:**
1. Install Docker Desktop: https://www.docker.com/products/docker-desktop
2. Start Docker Desktop
3. Verify Docker is running: `docker ps`

### 5. Runner Installation Fails

**Cause:**
- No internet connection
- GitHub/GitLab API rate limit
- Invalid token

**Solution:**
1. Check internet connection
2. Verify token is valid (Option 1)
3. Wait if rate limited (usually 1 hour)
4. Check repository exists and you have access

## Best Practices

### Running the Script

1. **Script can now be run multiple times** in the same PowerShell session without type errors
2. **Fresh PowerShell session recommended** for clean state
3. **Update regularly** to get latest fixes: `git pull origin main`

### Token Management

1. **Use Environment Variables** for production (most secure)
2. **Use File Storage** for development (convenient)
3. **Use Session Only** for testing (temporary)

### Telegram Setup

1. **Create bot** via @BotFather first
2. **Start conversation** with bot before adding Chat ID
3. **Test notification** after configuration
4. **Remove invalid Chat IDs** if notifications fail

## Getting Help

If you encounter issues not covered here:

1. Check the error message carefully
2. Look for similar issues in GitHub Issues
3. Provide full error message when reporting
4. Include PowerShell version: `$PSVersionTable.PSVersion`
5. Include OS version: `[System.Environment]::OSVersion`

## Debug Mode

To see more detailed error messages, run with verbose output:

```powershell
$VerbosePreference = "Continue"
.\runner.ps1
```

To see all errors:

```powershell
$ErrorActionPreference = "Continue"
.\runner.ps1
```
