# iam.tf

# Định nghĩa một vai trò (Role) mà EC2 có thể "đảm nhận" (assume)
resource "aws_iam_role" "ec2_cloudwatch_agent_role" {
  name = "${var.project_name}-ec2-cloudwatch-agent-role"

  # Đây là chính sách tin cậy, cho phép dịch vụ EC2 đảm nhận vai trò này
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Gắn chính sách (Policy) được quản lý bởi AWS vào vai trò vừa tạo
# Policy này chứa tất cả các quyền cần thiết cho CloudWatch Agent
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_policy_attachment" {
  role       = aws_iam_role.ec2_cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Tạo một "Instance Profile", đây là cách để gán một IAM Role cho một EC2 instance
resource "aws_iam_instance_profile" "ec2_cloudwatch_agent_instance_profile" {
  name = "${var.project_name}-ec2-cloudwatch-agent-profile"
  role = aws_iam_role.ec2_cloudwatch_agent_role.name
}

# Tạo output để các module khác có thể sử dụng
output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_cloudwatch_agent_instance_profile.name
}

# --- IAM Role for VPC Flow Logs ---

# 1. Tạo IAM Role mà dịch vụ VPC Flow Logs có thể đảm nhận
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.project_name}-vpc-flow-logs-role"

  # Chính sách tin cậy, cho phép dịch vụ vpc-flow-logs.amazonaws.com đảm nhận vai trò này
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Tạo một IAM Policy định nghĩa các quyền cần thiết
resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name        = "${var.project_name}-vpc-flow-logs-policy"
  description = "Allows VPC Flow Logs to publish to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# 3. Gắn Policy vào Role
resource "aws_iam_role_policy_attachment" "vpc_flow_logs_attachment" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.vpc_flow_logs_policy.arn
}

resource "aws_iam_policy" "ec2_s3_read_policy" {
  name        = "${var.project_name}-ec2-s3-read-policy"
  description = "Allows EC2 instances to read from a specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::pbl4-opencart-install-files-cunbien/*" # <-- THAY ĐÚNG TÊN BUCKET CỦA BẠN
      },
      {
        Effect   = "Allow",
        Action   = [
            "s3:ListBucket"
        ],
        # Resource áp dụng cho chính cái bucket (không có /*)
        Resource = "arn:aws:s3:::pbl4-opencart-install-files-cunbien" # <-- THAY ĐÚNG TÊN BUCKET CỦA BẠN
      }
    ]
  })
}

# Gắn policy này vào Role của EC2
resource "aws_iam_role_policy_attachment" "ec2_s3_read_attachment" {
  role       = aws_iam_role.ec2_cloudwatch_agent_role.name
  policy_arn = aws_iam_policy.ec2_s3_read_policy.arn
}

# --- Gắn thêm policy cho phép EC2 kết nối AWS Systems Manager (SSM) ---
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_core" {
  role       = aws_iam_role.ec2_cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}