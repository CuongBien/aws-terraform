# ==================================================
# Packer Template - Web Server (Nginx + Frontend)
# ==================================================

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variables
variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "version" {
  type        = string
  description = "Version tag for AMI (e.g., v1.0, v2.0)"
}

variable "color" {
  type        = string
  description = "Deployment color (blue or green)"
  validation {
    condition     = contains(["blue", "green"], var.color)
    error_message = "Color must be 'blue' or 'green'."
  }
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}

variable "project_name" {
  type    = string
  default = "pbl4-three-tier"
}

# Locals for conditional frontend path
locals {
  frontend_source = var.version == "v1.0" ? "${path.root}/../web_demo/frontend-v1.0" : "${path.root}/../web_demo/frontend-v2.0"
}

# Source AMI - Amazon Linux 2
data "amazon-ami" "base" {
  filters = {
    name                = "amzn2-ami-hvm-*-x86_64-gp2"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.aws_region
}

# Build Configuration
source "amazon-ebs" "web_server" {
  ami_name      = "${var.project_name}-web-${var.version}-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.aws_region
  source_ami    = data.amazon-ami.base.id
  
  ssh_username = "ec2-user"
  
  # AMI Configuration
  ami_description = "Web server with Nginx - ${var.project_name} ${var.version}"
  
  tags = {
    Name        = "${var.project_name}-web-${var.version}"
    Version     = var.version
    Tier        = "web"
    Project     = var.project_name
    Environment = var.environment
    BuildDate   = "{{timestamp}}"
    Builder     = "packer"
  }
  
  # Snapshot tags
  snapshot_tags = {
    Name    = "${var.project_name}-web-${var.version}-snapshot"
    Version = var.version
  }
  
  # Launch configuration
  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 30
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
    delete_on_termination = true
  }
  
  # Security
  encrypt_boot = true
}

# Build Steps
build {
  name = "web-server-build"
  sources = [
    "source.amazon-ebs.web_server"
  ]
  
  # Update system
  provisioner "shell" {
    inline = [
      "echo '==> Updating system packages'",
      "sudo yum update -y",
      "sudo yum install -y amazon-cloudwatch-agent"
    ]
  }
  
  # Install Nginx and dependencies
  provisioner "shell" {
    script = "${path.root}/scripts/install-web.sh"
  }
  
  # Copy application files
  provisioner "file" {
    source      = local.frontend_source
    destination = "/tmp/frontend"
  }
  
  # Configure application
  provisioner "shell" {
    inline = [
      "echo '==> Deploying web application'",
      "sudo mkdir -p /var/www/html",
      "sudo cp -r /tmp/frontend/* /var/www/html/",
      "sudo chown -R nginx:nginx /var/www/html",
      "sudo chmod -R 755 /var/www/html",
      
      "echo '==> Creating version info file'",
      "echo '${var.version}' | sudo tee /var/www/html/version.txt",
      "echo 'Build Date: $(date)' | sudo tee -a /var/www/html/version.txt",
      
      "echo '==> Configuring nginx'",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      
      "echo '==> Cleaning up'",
      "sudo rm -rf /tmp/*",
      "sudo yum clean all"
    ]
  }
  
  # Post-processor: Create manifest
  post-processor "manifest" {
    output = "manifest-web-${var.version}.json"
    strip_path = true
  }
}
