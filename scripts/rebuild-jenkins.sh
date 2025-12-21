#!/bin/bash
# ========================================
# REBUILD JENKINS CONTAINER
# ========================================
# Rebuild Jenkins container with updated tools
# ========================================

set -e

echo "============================================"
echo "🔨 REBUILDING JENKINS CONTAINER"
echo "============================================"
echo ""

# Stop and remove existing container
echo "📦 Stopping existing Jenkins container..."
docker-compose down

echo ""
echo "🔨 Building new image with tfsec and checkov..."
docker-compose build --no-cache

echo ""
echo "🚀 Starting Jenkins container..."
docker-compose up -d

echo ""
echo "⏳ Waiting for Jenkins to start..."
sleep 10

echo ""
echo "============================================"
echo "✅ JENKINS CONTAINER REBUILT"
echo "============================================"
echo ""
echo "Jenkins is starting at: http://localhost:8080"
echo ""
echo "Verify installations:"
echo "  docker exec jenkins-pbl4 tfsec --version"
echo "  docker exec jenkins-pbl4 checkov --version"
echo ""
