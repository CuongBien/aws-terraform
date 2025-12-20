# 1. Tạo một Customer Managed Key (CMK) trong KMS
resource "aws_kms_key" "sns_key" {
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 7 # Thời gian chờ trước khi xóa key vĩnh viễn
  enable_key_rotation     = true # Tự động xoay vòng key mỗi năm
}

# 2. Tạo một alias (tên thân thiện) cho key
resource "aws_kms_alias" "sns_key_alias" {
  name          = "alias/${var.project_name}/sns"
  target_key_id = aws_kms_key.sns_key.key_id
}