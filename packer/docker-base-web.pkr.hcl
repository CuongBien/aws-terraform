# ========================================
# Docker Base AMI for Web Tier
# Purpose: Base image with Docker + Nginx (no app code)
# ========================================

packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# ===== VARIABLES =====
variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "project_name" {
  type    = string
  default = "pbl4-three-tier"
}

variable "version" {
  type        = string
  description = "Version tag for the AMI"
  default     = "docker-base"
}

variable "color" {
  type        = string
  description = "Deployment color (blue or green)"
  default     = "blue"
}

# ===== SOURCE =====
source "amazon-ebs" "web_base" {
  region        = var.aws_region
  ami_name      = "${var.project_name}-web-${var.color}-${var.version}-{{timestamp}}"
  instance_type = "t2.micro"
  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  ssh_username = "ec2-user"
  
  tags = {
    Name        = "${var.project_name}-web-${var.color}-${var.version}"
    Project     = var.project_name
    Environment = "production"
    Tier        = "web"
    Color       = var.color
    Version     = var.version
    ManagedBy   = "Packer"
    Type        = "docker-base"
  }
}

# ===== BUILD =====
build {
  sources = ["source.amazon-ebs.web_base"]
  
  # Install Docker, Nginx, AWS CLI, utilities
  provisioner "shell" {
    script = "${path.root}/scripts/install-web.sh"
  }
  
  # NO APPLICATION CODE - will be pulled as Docker image at runtime
}
