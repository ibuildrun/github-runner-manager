@echo off
REM Start Docker Desktop
echo Starting Docker Desktop...
start "" "C:\Program Files\Docker\Docker\Docker.exe"

REM Wait for Docker to start
echo Waiting for Docker to start (30 seconds)...
timeout /t 30 /nobreak

REM Run the PowerShell script
echo Starting runner setup...
powershell -ExecutionPolicy Bypass -File ".\start.ps1"

pause
