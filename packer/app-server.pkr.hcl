# ==================================================
# Packer Template - App Server (PHP + Backend API)
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

variable "environment" {
  type        = string
  default     = "production"
}

variable "project_name" {
  type    = string
  default = "pbl4-three-tier"
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
source "amazon-ebs" "app_server" {
  ami_name      = "${var.project_name}-app-${var.version}-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.aws_region
  source_ami    = data.amazon-ami.base.id
  
  ssh_username = "ec2-user"
  
  ami_description = "App server with PHP-FPM - ${var.project_name} ${var.version}"
  
  tags = {
    Name        = "${var.project_name}-app-${var.version}"
    Version     = var.version
    Tier        = "app"
    Project     = var.project_name
    Environment = var.environment
    BuildDate   = "{{timestamp}}"
    Builder     = "packer"
  }
  
  snapshot_tags = {
    Name    = "${var.project_name}-app-${var.version}-snapshot"
    Version = var.version
  }
  
  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 30
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
    delete_on_termination = true
  }
  
  encrypt_boot = true
}

# Build Steps
build {
  name = "app-server-build"
  sources = [
    "source.amazon-ebs.app_server"
  ]
  
  # Update system
  provisioner "shell" {
    inline = [
      "echo '==> Updating system packages'",
      "sudo yum update -y",
      "sudo yum install -y amazon-cloudwatch-agent"
    ]
  }
  
  # Install PHP and dependencies
  provisioner "shell" {
    script = "${path.root}/scripts/install-app.sh"
  }
  
  # Copy backend application
  provisioner "file" {
    source      = "${path.root}/../web_demo/backend/"
    destination = "/tmp/backend"
  }
  
  # Configure application
  provisioner "shell" {
    inline = [
      "echo '==> Deploying backend application'",
      "sudo mkdir -p /var/www/api",
      "sudo cp -r /tmp/backend/* /var/www/api/",
      "sudo chown -R apache:apache /var/www/api",
      "sudo chmod -R 755 /var/www/api",
      
      "echo '==> Creating version info'",
      "echo '${var.version}' | sudo tee /var/www/api/version.txt",
      "echo 'Build Date: $(date)' | sudo tee -a /var/www/api/version.txt",
      
      "echo '==> Enabling services'",
      "sudo systemctl enable httpd",
      "sudo systemctl enable php-fpm",
      
      "echo '==> Cleaning up'",
      "sudo rm -rf /tmp/*",
      "sudo yum clean all"
    ]
  }
  
  post-processor "manifest" {
    output = "manifest-app-${var.version}.json"
    strip_path = true
  }
}
