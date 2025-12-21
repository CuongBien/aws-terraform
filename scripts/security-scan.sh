#!/bin/bash
# ========================================
# SECURITY SCAN SCRIPT
# ========================================
# Run tfsec and checkov against Terraform code
# Usage: ./scripts/security-scan.sh [path]
# ========================================

set -e

# Configuration
SCAN_PATH="${1:-infrastructure_aws}"
EXIT_CODE=0

echo "============================================"
echo "🔒 TERRAFORM SECURITY SCANNING"
echo "============================================"
echo "Scanning: $SCAN_PATH"
echo ""

# Check if tools are installed
echo "📋 Checking dependencies..."
if ! command -v tfsec &> /dev/null; then
    echo "❌ tfsec not found. Install: https://github.com/aquasecurity/tfsec"
    echo "   Quick install: brew install tfsec (macOS) or choco install tfsec (Windows)"
    EXIT_CODE=1
fi

if ! command -v checkov &> /dev/null; then
    echo "❌ checkov not found. Install: https://www.checkov.io/2.Basics/Installing%20Checkov.html"
    echo "   Quick install: pip install checkov"
    EXIT_CODE=1
fi

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "Please install missing tools and try again."
    exit $EXIT_CODE
fi

echo "✅ All tools installed"
echo ""

# Run tfsec
echo "============================================"
echo "🔍 Running tfsec..."
echo "============================================"
if tfsec "$SCAN_PATH" --config-file .tfsec.yml --format default; then
    echo "✅ tfsec scan passed"
else
    echo "❌ tfsec scan failed"
    EXIT_CODE=1
fi
echo ""

# Run checkov
echo "============================================"
echo "🔍 Running checkov..."
echo "============================================"
if checkov -d "$SCAN_PATH" --config-file .checkov.yml; then
    echo "✅ checkov scan passed"
else
    echo "❌ checkov scan failed"
    EXIT_CODE=1
fi
echo ""

# Summary
echo "============================================"
echo "📊 SCAN SUMMARY"
echo "============================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All security scans passed!"
else
    echo "❌ Security scans found issues. Please review and fix."
fi
echo "============================================"

exit $EXIT_CODE
