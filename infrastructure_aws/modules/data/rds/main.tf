# ========================================
# DATA - RDS MODULE
# ========================================
# RDS Database with Multi-AZ support
# ========================================

# ===== DB SUBNET GROUP =====

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ===== RDS INSTANCE =====
# Using existing RDS instance instead of creating new one
data "aws_db_instance" "main" {
  db_instance_identifier = "${var.project_name}-db"
}

# Commented out resource - RDS already exists
/*
#tfsec:ignore:aws-rds-enable-iam-auth # IAM auth is not required for this project
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  # Security settings
  storage_encrypted   = true
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # High availability
  multi_az            = var.multi_az
  publicly_accessible = false

  # Backup settings
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Performance Insights
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-db"
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }
}
*/
