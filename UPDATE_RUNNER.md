# Update Docker Runner with Full Stack

## What was fixed:
- Added Node.js 20.x for frontend builds
- Added PHP 8.3 for backend
- Added Composer for PHP dependencies
- Added sshpass and lftp for deployment
- Telegram notifications will now work properly

## Steps to update:

### 1. Stop and remove old container
```powershell
.\runner.ps1
# Select option 16 (Docker Container Management)
# Select option 4 (Stop container)
# Enter container name: avyx-runner-XXXXXXXXXX
# Then select option 5 (Remove container)
# Enter same container name and confirm with 'y'
```

### 2. Remove old image
```powershell
docker rmi github-runner:latest
```

### 3. Build new image with full stack
```powershell
.\runner.ps1
# Select option 16 (Docker Container Management)
# Select option 1 (Build runner image)
# Press Enter to use default tag
# Wait 5-10 minutes for build to complete
```

### 4. Start new runner
```powershell
# Still in Docker menu
# Select option 2 (Start new runner container)
# Press Enter for auto-generated name
# Press Enter for default image tag
```

### 5. Verify runner is online
Go to: https://github.com/ibuildrun/avyx/settings/actions/runners
You should see your runner with status "Idle" (green)

### 6. Test deployment
Make a small change and push to main branch:
```bash
cd /path/to/avyx
echo "# Test" >> README.md
git add README.md
git commit -m "test: trigger deployment"
git push origin main
```

Check Telegram for deployment notifications!

## Quick commands (alternative):

```powershell
# Stop old container
docker stop avyx-runner-XXXXXXXXXX
docker rm avyx-runner-XXXXXXXXXX

# Remove old image
docker rmi github-runner:latest

# Build new image
.\runner.ps1
# Option 16 -> Option 1

# Start new runner
# Option 2
```

## Troubleshooting:

If build fails:
- Check Docker Desktop is running
- Check internet connection
- Try building again (sometimes package downloads fail)

If runner doesn't appear online:
- Check container logs: `docker logs avyx-runner-XXXXXXXXXX`
- Verify GitHub token is valid
- Check repository name is correct: ibuildrun/avyx
