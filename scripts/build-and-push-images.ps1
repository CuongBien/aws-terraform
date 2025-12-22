# Build and Push Docker Images to ECR
# Run this script to build and push ecommerce images to ECR

$ErrorActionPreference = "Stop"

$ECR_REGISTRY = "120915930136.dkr.ecr.ap-southeast-2.amazonaws.com"
$AWS_REGION = "ap-southeast-2"
$BACKEND_REPO = "ecommerce-backend"
$FRONTEND_REPO = "ecommerce-frontend"
$IMAGE_TAG = "latest"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building and Pushing Docker Images to ECR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Login to ECR
Write-Host "`n[1/5] Logging into ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ECR login failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ ECR login successful!" -ForegroundColor Green

# Step 2: Create repositories if they don't exist
Write-Host "`n[2/5] Ensuring ECR repositories exist..." -ForegroundColor Yellow

$repos = @($BACKEND_REPO, $FRONTEND_REPO)
foreach ($repo in $repos) {
    $exists = aws ecr describe-repositories --region $AWS_REGION --repository-names $repo 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Creating repository: $repo" -ForegroundColor Cyan
        aws ecr create-repository --region $AWS_REGION --repository-name $repo --image-scanning-configuration scanOnPush=true
    } else {
        Write-Host "  Repository exists: $repo" -ForegroundColor Gray
    }
}
Write-Host "✅ Repositories ready!" -ForegroundColor Green

# Step 3: Build Backend Image
Write-Host "`n[3/5] Building backend image..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\..\ecommerce-app\backend"

docker build -t ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG} .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Backend build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Backend image built!" -ForegroundColor Green

# Step 4: Build Frontend Image
Write-Host "`n[4/5] Building frontend image..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\..\ecommerce-app\frontend"

docker build -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend image built!" -ForegroundColor Green

# Step 5: Push Images to ECR
Write-Host "`n[5/5] Pushing images to ECR..." -ForegroundColor Yellow

Write-Host "  Pushing backend..." -ForegroundColor Cyan
docker push ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}

Write-Host "  Pushing frontend..." -ForegroundColor Cyan
docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Push failed!" -ForegroundColor Red
    exit 1
}

# Verify images
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ SUCCESS! Images pushed to ECR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nVerifying images in ECR..." -ForegroundColor Yellow
Write-Host "`nBackend images:"
aws ecr list-images --region $AWS_REGION --repository-name $BACKEND_REPO --query 'imageIds[*].imageTag' --output table

Write-Host "`nFrontend images:"
aws ecr list-images --region $AWS_REGION --repository-name $FRONTEND_REPO --query 'imageIds[*].imageTag' --output table

Write-Host "`n🎉 Done! You can now deploy instances and they will pull these images." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Terminate current instances (or let ASG recreate them)"
Write-Host "  2. New instances will pull images from ECR"
Write-Host "  3. Health checks should pass! 🚀"

Set-Location $PSScriptRoot
