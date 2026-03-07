# Run all Pester tests
# Usage: .\tests\Run-AllTests.ps1

$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Octopus Runner Manager - Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testFiles = Get-ChildItem "$here\*.Tests.ps1"
Write-Host "Found $($testFiles.Count) test files" -ForegroundColor Yellow
Write-Host ""

$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0

foreach ($file in $testFiles) {
    Write-Host "Running: $($file.Name)" -ForegroundColor Cyan
    $result = Invoke-Pester -Path $file.FullName -PassThru
    $totalPassed += $result.PassedCount
    $totalFailed += $result.FailedCount
    $totalSkipped += $result.SkippedCount
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TOTAL RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Passed:  $totalPassed" -ForegroundColor Green
Write-Host "  Failed:  $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "Green" })
Write-Host "  Skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if ($totalFailed -gt 0) {
    exit 1
}
