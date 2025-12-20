# RDS Module Configuration

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

#tfsec:ignore:aws-rds-enable-iam-auth # IAM auth is not required for this project
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  storage_encrypted    = true # Bật mã hóa
  deletion_protection  = false # Bật chống xóa nhầm
  skip_final_snapshot  = true # Nên là false cho an toàn

  # For production, set multi_az = true
  multi_az = false
  publicly_accessible = false

  backup_retention_period = 7

  tags = {
    Name = "${var.project_name}-db"
  }
}
