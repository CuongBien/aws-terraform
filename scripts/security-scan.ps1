# ========================================
# SECURITY SCAN SCRIPT (PowerShell)
# ========================================
# Run tfsec and checkov against Terraform code
# Usage: .\scripts\security-scan.ps1 [path]
# ========================================

param(
    [string]$ScanPath = "infrastructure_aws"
)

$ErrorActionPreference = "Continue"
$ExitCode = 0

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔒 TERRAFORM SECURITY SCANNING" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Scanning: $ScanPath"
Write-Host ""

# Check if tools are installed
Write-Host "📋 Checking dependencies..." -ForegroundColor Yellow
$tfsecInstalled = Get-Command tfsec -ErrorAction SilentlyContinue
$checkovInstalled = Get-Command checkov -ErrorAction SilentlyContinue

if (-not $tfsecInstalled) {
    Write-Host "❌ tfsec not found. Install: https://github.com/aquasecurity/tfsec" -ForegroundColor Red
    Write-Host "   Quick install: choco install tfsec (Windows)" -ForegroundColor Yellow
    $ExitCode = 1
}

if (-not $checkovInstalled) {
    Write-Host "❌ checkov not found. Install: https://www.checkov.io/2.Basics/Installing%20Checkov.html" -ForegroundColor Red
    Write-Host "   Quick install: pip install checkov" -ForegroundColor Yellow
    $ExitCode = 1
}

if ($ExitCode -ne 0) {
    Write-Host ""
    Write-Host "Please install missing tools and try again." -ForegroundColor Red
    exit $ExitCode
}

Write-Host "✅ All tools installed" -ForegroundColor Green
Write-Host ""

# Run tfsec
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔍 Running tfsec..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
tfsec $ScanPath --config-file .tfsec.yml --format default
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ tfsec scan passed" -ForegroundColor Green
} else {
    Write-Host "❌ tfsec scan failed" -ForegroundColor Red
    $ExitCode = 1
}
Write-Host ""

# Run checkov
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔍 Running checkov..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
checkov -d $ScanPath --config-file .checkov.yml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ checkov scan passed" -ForegroundColor Green
} else {
    Write-Host "❌ checkov scan failed" -ForegroundColor Red
    $ExitCode = 1
}
Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "📊 SCAN SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
if ($ExitCode -eq 0) {
    Write-Host "✅ All security scans passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Security scans found issues. Please review and fix." -ForegroundColor Red
}
Write-Host "============================================" -ForegroundColor Cyan

exit $ExitCode
