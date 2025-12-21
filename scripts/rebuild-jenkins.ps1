# ========================================
# REBUILD JENKINS CONTAINER (PowerShell)
# ========================================
# Rebuild Jenkins container with updated tools
# ========================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔨 REBUILDING JENKINS CONTAINER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Stop and remove existing container
Write-Host "📦 Stopping existing Jenkins container..." -ForegroundColor Yellow
docker-compose down

Write-Host ""
Write-Host "🔨 Building new image with tfsec and checkov..." -ForegroundColor Yellow
docker-compose build --no-cache

Write-Host ""
Write-Host "🚀 Starting Jenkins container..." -ForegroundColor Yellow
docker-compose up -d

Write-Host ""
Write-Host "⏳ Waiting for Jenkins to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "✅ JENKINS CONTAINER REBUILT" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Jenkins is starting at: http://localhost:8080" -ForegroundColor Green
Write-Host ""
Write-Host "Verify installations:" -ForegroundColor Yellow
Write-Host "  docker exec jenkins-pbl4 tfsec --version" -ForegroundColor White
Write-Host "  docker exec jenkins-pbl4 checkov --version" -ForegroundColor White
Write-Host ""
