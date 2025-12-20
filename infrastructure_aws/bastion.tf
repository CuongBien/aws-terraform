# infrastructure_aws/bastion.tf

# --- Tự động tìm AMI Amazon Linux 2023 mới nhất ---
# Data source này sẽ hỏi AWS để lấy ID của AMI AL2023 phù hợp
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"] # AMI chính thức của Amazon

  filter {
    name   = "name"
    # Tên của AMI AL2023 luôn theo mẫu này
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

# --- Tạo EC2 Instance cho Bastion Host ---
resource "aws_instance" "bastion" {
  # Sử dụng AMI ID đã tìm thấy ở trên
  ami           = data.aws_ami.amazon_linux_2023.id
  
  instance_type = "t3.micro" # Free tier eligible
  
  # Đặt Bastion vào một trong các PUBLIC subnets
  subnet_id     = module.vpc.public_subnet_ids[0]

  # Gán Public IP cho nó
  associate_public_ip_address = true

  # Gắn Security Group đã tạo (tham chiếu đến resource trong main.tf)
  vpc_security_group_ids = [aws_security_group.bastion.id]

  # Chỉ định Key Pair để bạn có thể SSH vào
  key_name = var.key_pair_name

  tags = {
    Name = "${var.project_name}-bastion-host"
  }
}

# Output ra địa chỉ IP Public của Bastion Host (không đổi)
output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}