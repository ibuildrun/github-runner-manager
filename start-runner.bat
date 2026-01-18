@echo off
REM AVYX Deploy Runner - Quick Start
REM Run this to start the GitHub Actions runner

cd /d "%~dp0"

echo.
echo ========================================
echo   AVYX Deploy Runner - Quick Start
echo ========================================
echo.

REM Check if PowerShell is available
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    pwsh -ExecutionPolicy Bypass -File start.ps1
) else (
    powershell -ExecutionPolicy Bypass -File start.ps1
)

pause
