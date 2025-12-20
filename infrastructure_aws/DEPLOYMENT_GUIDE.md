# ========================================
# TERRAFORM CLOUD DEPLOYMENT GUIDE
# ========================================

## Option 1: Deploy via Terraform Cloud (Recommended for your setup)

### Step 1: Update Git Repository
```bash
cd d:\pbl4-terraform\pbl4-aws-terraform-three-tier
git add infrastructure_aws/
git commit -m "Refactor: Modular architecture with Blue/Green deployment"
git push origin main
```

### Step 2: Configure Terraform Cloud Variables
Go to Terraform Cloud workspace "aws-terraform-vcs" and set these variables:

**Terraform Variables:**
- `db_username` = "admin" (sensitive)
- `db_password` = "YourSecurePassword123!" (sensitive, min 8 chars)
- `key_pair_name` = "pbl4-three-tier-key"
- `bastion_allowed_cidrs` = ["YOUR_IP/32"]
- `alarm_email_endpoints` = ["your-email@example.com"]

**Optional Variables (use defaults or customize):**
- `project_name` = "pbl4-three-tier"
- `environment` = "prod"
- `enable_blue_env` = true
- `enable_green_env` = false
- `traffic_distribution_blue` = 100
- `traffic_distribution_green` = 0

### Step 3: Trigger Run
- Terraform Cloud will automatically trigger when you push to Git
- Or manually trigger: Queue Plan → Apply

---

## Option 2: Deploy Locally (For testing)

### Step 1: Create terraform.tfvars
```bash
cd d:\pbl4-terraform\pbl4-aws-terraform-three-tier\infrastructure_aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 2: Initialize and Apply
```bash
terraform init
terraform plan
terraform apply
```

---

## Important Notes

### Module Changes
Old modules have been replaced:
- `module.vpc` → `module.networking`
- `module.alb` → `module.alb` (same name, different path)
- `module.asg` → `module.web_tier` + `module.app_tier`
- `module.rds` → `module.rds` (same name, different path)
- Added: `module.security`, `module.monitoring`, `module.bastion`, `module.nacl`

### Terraform Cloud Considerations
1. **Working Directory**: Should be `infrastructure_aws/`
2. **VCS Trigger**: Will auto-run on Git push
3. **State**: Existing state will be migrated to new module structure
4. **Variables**: Must set sensitive variables in Terraform Cloud UI

### Jenkins Pipeline Compatibility
✅ Your Jenkins pipeline will still work:
- Traffic distribution variables remain the same
- Terraform Cloud API calls unchanged
- Blue/Green deployment logic preserved

### State Migration
When you first apply with new modules:
- Terraform will detect resources have moved
- Use `terraform state mv` if needed (Terraform Cloud handles this automatically)
- Or let Terraform recreate (will cause downtime)

---

## Recommended Workflow

### For Production (Terraform Cloud):
1. ✅ Push refactored code to Git
2. ✅ Configure variables in Terraform Cloud
3. ✅ Review plan in Terraform Cloud
4. ✅ Apply via Terraform Cloud
5. ✅ Test Blue/Green deployment with Jenkins

### For Testing (Local):
1. Create `terraform.tfvars` from example
2. Run `terraform init`
3. Run `terraform plan` to verify
4. Run `terraform apply` when ready
5. After testing, push to Git for Terraform Cloud

---

## Quick Start Commands

### Local Testing:
```powershell
cd d:\pbl4-terraform\pbl4-aws-terraform-three-tier\infrastructure_aws

# Create tfvars from example
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Push to Terraform Cloud:
```bash
git add .
git commit -m "Infrastructure refactoring complete"
git push origin main

# Then check Terraform Cloud workspace for auto-triggered run
```

---

## Troubleshooting

### If modules not found:
```bash
terraform init -upgrade
```

### If state conflicts:
Check Terraform Cloud run logs, may need to:
- Review proposed changes carefully
- Use targeted applies if needed
- Contact me for state migration help

### If variables missing:
Ensure all required variables are set in:
- Terraform Cloud workspace variables (for cloud runs)
- terraform.tfvars (for local runs)
