# ========================================
# LOCALS - COMMON VALUES AND TAGS
# ========================================

locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Derived subnet CIDRs for each tier
  web_subnet_cidrs = slice(var.private_subnet_cidrs, 0, 2)
  app_subnet_cidrs = slice(var.private_subnet_cidrs, 2, 4)
  db_subnet_cidrs  = slice(var.private_subnet_cidrs, 4, 6)

  # Blue/Green deployment state
  deployment_state = var.enable_blue_env && !var.enable_green_env ? "blue-only" : (
    !var.enable_blue_env && var.enable_green_env ? "green-only" : (
      var.enable_blue_env && var.enable_green_env ? "blue-green" : "none"
    )
  )

  # Traffic distribution validation
  traffic_total = var.traffic_distribution_blue + var.traffic_distribution_green
}
