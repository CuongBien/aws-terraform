#!/bin/bash
# ==================================================
# Packer Build Automation Script
# Build AMIs for Blue/Green deployment
# ==================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-ap-southeast-2}"
PROJECT_NAME="pbl4-three-tier"

print_banner() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "  Packer AMI Builder"
    echo "  Project: ${PROJECT_NAME}"
    echo "========================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

validate_packer() {
    print_step "Validating Packer installation..."
    if ! command -v packer &> /dev/null; then
        print_error "Packer is not installed"
        echo "Install from: https://www.packer.io/downloads"
        exit 1
    fi
    print_success "Packer $(packer version) found"
}

validate_aws() {
    print_step "Validating AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        echo "Run: aws configure"
        exit 1
    fi
    print_success "AWS credentials valid"
}

build_ami() {
    local tier=$1
    local version=$2
    
    print_step "Building ${tier} server AMI - Version ${version}"
    
    # Initialize Packer
    packer init ${tier}-server.pkr.hcl
    
    # Validate template
    print_step "Validating Packer template..."
    packer validate \
        -var "version=${version}" \
        -var "aws_region=${AWS_REGION}" \
        ${tier}-server.pkr.hcl
    
    # Build AMI
    print_step "Building AMI (this may take 10-15 minutes)..."
    packer build \
        -var "version=${version}" \
        -var "aws_region=${AWS_REGION}" \
        -force \
        ${tier}-server.pkr.hcl
    
    cd ..
    
    # Extract AMI ID from manifest
    local ami_id=$(jq -r '.builds[-1].artifact_id' "packer/manifest-${tier}-${version}.json" | cut -d':' -f2)
    
    print_success "${tier} AMI created: ${ami_id}"
    
    echo "${ami_id}"
}

update_terraform_vars() {
    local tier=$1
    local color=$2
    local ami_id=$3
    
    print_step "Updating Terraform Cloud variable: ${tier}_ami_id_${color}"
    
    # Update via terraform CLI or API
    # For now, just print instructions
    echo ""
    echo "Update Terraform Cloud variable:"
    echo "  Variable: ${tier}_ami_id_${color}"
    echo "  Value: ${ami_id}"
    echo ""
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tier TIER        Tier to build (web|app|all)"
    echo "  -v, --version VERSION  Version tag (e.g., v1.0, v2.0)"
    echo "  -c, --color COLOR      Deploy to color (blue|green)"
    echo "  -r, --region REGION    AWS region (default: ap-southeast-2)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --tier web --version v1.0 --color blue"
    echo "  $0 --tier app --version v2.0 --color green"
    echo "  $0 --tier all --version v1.0 --color blue"
}

main() {
    print_banner
    
    # Parse arguments
    TIER=""
    VERSION=""
    COLOR=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tier)
                TIER="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -c|--color)
                COLOR="$2"
                shift 2
                ;;
            -r|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$TIER" ]] || [[ -z "$VERSION" ]] || [[ -z "$COLOR" ]]; then
        print_error "Missing required parameters"
        usage
        exit 1
    fi
    
    if [[ "$TIER" != "web" ]] && [[ "$TIER" != "app" ]] && [[ "$TIER" != "all" ]]; then
        print_error "Invalid tier: $TIER (must be web, app, or all)"
        exit 1
    fi
    
    if [[ "$COLOR" != "blue" ]] && [[ "$COLOR" != "green" ]]; then
        print_error "Invalid color: $COLOR (must be blue or green)"
        exit 1
    fi
    
    # Validate prerequisites
    validate_packer
    validate_aws
    
    # Build AMIs
    if [[ "$TIER" == "all" ]] || [[ "$TIER" == "web" ]]; then
        WEB_AMI=$(build_ami "web" "$VERSION")
        update_terraform_vars "web" "$COLOR" "$WEB_AMI"
        echo "web_ami_id_${COLOR}=${WEB_AMI}" >> ami-ids.txt
    fi
    
    if [[ "$TIER" == "all" ]] || [[ "$TIER" == "app" ]]; then
        APP_AMI=$(build_ami "app" "$VERSION")
        update_terraform_vars "app" "$COLOR" "$APP_AMI"
        echo "app_ami_id_${COLOR}=${APP_AMI}" >> ami-ids.txt
    fi
    
    echo ""
    print_success "Build complete!"
    echo ""
    echo "Next steps:"
    echo "1. Update Terraform Cloud variables with AMI IDs above"
    echo "2. Run Jenkins pipeline to deploy"
    echo "3. Verify instances are using new AMI"
    echo ""
    echo "AMI IDs saved to: ami-ids.txt"
}

main "$@"
