# ========================================
# COMPUTE - BASTION MODULE
# ========================================
# Bastion host for SSH access
# ========================================

# ===== AMI DATA SOURCE =====

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ===== BASTION EC2 INSTANCE =====

resource "aws_instance" "bastion" {
  ami           = var.bastion_ami_id != "" ? var.bastion_ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[0]

  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_pair_name

  iam_instance_profile = var.ec2_instance_profile_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data_bastion.sh.tftpl", {
    project_name = var.project_name
  }))

  tags = {
    Name = "${var.project_name}-bastion-host"
  }

  lifecycle {
    ignore_changes = [
      ami # Prevent recreation when AMI updates
    ]
  }
}
