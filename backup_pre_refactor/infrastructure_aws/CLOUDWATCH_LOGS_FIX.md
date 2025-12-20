# CloudWatch Logs - Blue/Green Environment Fix

## 🔧 Thay đổi đã thực hiện

### **Vấn đề:**
- Tất cả instances (Blue và Green) ghi logs vào CÙNG CloudWatch Log Groups
- Không phân biệt được logs từ Blue hay Green environment
- Khó debug và monitor khi triển khai Blue/Green

### **Giải pháp:**
Thêm biến `environment` vào user data templates và cập nhật log group names để có format:
```
${project_name}-${tier}-${environment}-${log_type}
```

---

## 📝 Files đã sửa

### 1. **modules/asg/main.tf**
Thêm `environment = "blue"/"green"` vào 4 Launch Templates:

```terraform
# Web Blue Launch Template
user_data = base64encode(templatefile("${path.module}/user_data_web.sh.tftpl", {
  internal_alb_dns_name = var.internal_alb_dns_name
  project_name          = var.project_name
  environment           = "blue"  # ← ADDED
}))

# Web Green Launch Template
user_data = base64encode(templatefile("${path.module}/user_data_web.sh.tftpl", {
  internal_alb_dns_name = var.internal_alb_dns_name
  project_name          = var.project_name
  environment           = "green"  # ← ADDED
}))

# App Blue Launch Template
user_data = base64encode(templatefile("${path.module}/user_data_app.sh.tftpl", {
  db_host      = var.db_host
  db_username  = var.db_username
  db_password  = var.db_password
  db_name      = var.db_name
  project_name = var.project_name
  shop_url     = "http://${var.alb_dns_name}/"
  environment  = "blue"  # ← ADDED
}))

# App Green Launch Template
user_data = base64encode(templatefile("${path.module}/user_data_app.sh.tftpl", {
  db_host      = var.db_host
  db_username  = var.db_username
  db_password  = var.db_password
  db_name      = var.db_name
  project_name = var.project_name
  shop_url     = "http://${var.alb_dns_name}/"
  environment  = "green"  # ← ADDED
}))
```

---

### 2. **modules/asg/user_data_web.sh.tftpl**

**Thêm environment variable:**
```bash
#!/bin/bash
set -xeuo pipefail

log(){ echo "[web-user-data] $*"; }
ENVIRONMENT="${environment}"  # ← ADDED
```

**Update CloudWatch log group names:**
```bash
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CW
{
  "agent": { "run_as_user": "root" },
  "logs": { "logs_collected": { "files": { "collect_list": [
    { "file_path": "/var/log/nginx/access.log", "log_group_name": "${project_name}-web-$ENVIRONMENT-access", "log_stream_name": "{instance_id}" },
    { "file_path": "/var/log/nginx/error.log",  "log_group_name": "${project_name}-web-$ENVIRONMENT-error",  "log_stream_name": "{instance_id}" }
  ]}}}
}
CW
```

**Before:**
- `${project_name}-web-access`
- `${project_name}-web-error`

**After:**
- `${project_name}-web-blue-access` / `${project_name}-web-green-access`
- `${project_name}-web-blue-error` / `${project_name}-web-green-error`

---

### 3. **modules/asg/user_data_app.sh.tftpl**

**Thêm environment variable:**
```bash
#!/bin/bash
set -xeuo pipefail

# ========= Inputs from Terraform =========
DB_HOST="${db_host}"
DB_USER="${db_username}"
DB_PASS="${db_password}"
DB_NAME="${db_name}"
PROJECT="${project_name}"
SHOP_URL="${shop_url}"
ENVIRONMENT="${environment}"  # ← ADDED
```

**Update CloudWatch log group names:**
```bash
cat >/tmp/cw.json <<JSON
{
  "agent": { "run_as_user": "root" },
  "logs": { "logs_collected": { "files": { "collect_list": [
    { "file_path": "$ACCESS_LOG", "log_group_name": "$PROJECT-app-$ENVIRONMENT-access", "log_stream_name": "{instance_id}" },
    { "file_path": "$ERROR_LOG",  "log_group_name": "$PROJECT-app-$ENVIRONMENT-error",  "log_stream_name": "{instance_id}" }
  ]}}}
}
JSON
```

**Before:**
- `${project_name}-app-access`
- `${project_name}-app-error`

**After:**
- `${project_name}-app-blue-access` / `${project_name}-app-green-access`
- `${project_name}-app-blue-error` / `${project_name}-app-green-error`

---

## 📊 Kết quả

### **CloudWatch Log Groups mới sẽ tạo:**

```
Blue Environment:
✅ pbl4-three-tier-web-blue-access
✅ pbl4-three-tier-web-blue-error
✅ pbl4-three-tier-app-blue-access
✅ pbl4-three-tier-app-blue-error

Green Environment:
✅ pbl4-three-tier-web-green-access
✅ pbl4-three-tier-web-green-error
✅ pbl4-three-tier-app-green-access
✅ pbl4-three-tier-app-green-error
```

### **Log groups cũ (sẽ không còn sử dụng):**
```
⚠️ pbl4-three-tier-web-access
⚠️ pbl4-three-tier-web-error
⚠️ pbl4-three-tier-app-access
⚠️ pbl4-three-tier-app-error
⚠️ pbl4-three-tier-web-tier-access-log
⚠️ pbl4-three-tier-web-tier-error-log
⚠️ pbl4-three-tier-app-tier-access-log
⚠️ pbl4-three-tier-app-tier-error-log
```

---

## 🚀 Deployment Steps

### **1. Commit và push changes**

```bash
git add modules/asg/main.tf
git add modules/asg/user_data_web.sh.tftpl
git add modules/asg/user_data_app.sh.tftpl
git commit -m "fix: Separate CloudWatch logs for Blue/Green environments"
git push origin main
```

### **2. Terraform Cloud sẽ trigger plan**
- Review plan trong Terraform Cloud UI
- Click **"Confirm & Apply"**

### **3. Recreate instances để apply changes**

**Option A: Rolling restart (Recommended)**
```
# Terraform Cloud UI → Variables

# Bước 1: Tắt Blue
enable_blue_env = false
→ Start new run → Apply

# Bước 2: Bật lại Blue (với config mới)
enable_blue_env = true
→ Start new run → Apply

# Bước 3: Tắt Green (nếu đang chạy)
enable_green_env = false
→ Start new run → Apply

# Bước 4: Bật lại Green (với config mới)
enable_green_env = true
→ Start new run → Apply
```

**Option B: Terminate instances manually**
```bash
# Terminate instances từ AWS Console
# ASG sẽ tự động launch instances mới với Launch Template mới
```

### **4. Verify log groups được tạo**

```bash
# Check CloudWatch Log Groups
aws logs describe-log-groups \
  --log-group-name-prefix "pbl4-three-tier" \
  --query 'logGroups[*].logGroupName' \
  --output table

# Expected output:
# pbl4-three-tier-web-blue-access
# pbl4-three-tier-web-blue-error
# pbl4-three-tier-web-green-access
# pbl4-three-tier-web-green-error
# pbl4-three-tier-app-blue-access
# pbl4-three-tier-app-blue-error
# pbl4-three-tier-app-green-access
# pbl4-three-tier-app-green-error
```

### **5. Test logs streaming**

```bash
# Tail logs từ Blue environment
aws logs tail pbl4-three-tier-web-blue-access --follow

# Tail logs từ Green environment
aws logs tail pbl4-three-tier-web-green-access --follow
```

---

## 🔍 Monitoring & Comparison

### **CloudWatch Logs Insights - Compare Blue vs Green**

```sql
# Compare error counts
fields @timestamp, @message
| filter @logGroup like /pbl4-three-tier-(web|app)-(blue|green)-error/
| stats count() by @logGroup
| sort @timestamp desc

# Compare response times (nếu có trong logs)
fields @timestamp, response_time
| filter @logGroup like /pbl4-three-tier-web-(blue|green)-access/
| stats avg(response_time) by @logGroup, bin(5m)

# Find errors in Green environment
fields @timestamp, @message
| filter @logGroup like /pbl4-three-tier.*-green-error/
| filter @message like /ERROR|FATAL|Exception/
| sort @timestamp desc
| limit 100
```

### **Create CloudWatch Dashboard**

```json
{
  "widgets": [
    {
      "type": "log",
      "properties": {
        "query": "SOURCE 'pbl4-three-tier-web-blue-access' | stats count() by bin(5m)",
        "region": "ap-southeast-2",
        "title": "Web Blue - Request Count"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE 'pbl4-three-tier-web-green-access' | stats count() by bin(5m)",
        "region": "ap-southeast-2",
        "title": "Web Green - Request Count"
      }
    }
  ]
}
```

---

## 🧹 Cleanup (Optional)

### **Xóa log groups cũ không dùng nữa**

```bash
# List log groups cũ
aws logs describe-log-groups \
  --log-group-name-prefix "pbl4-three-tier" \
  --query 'logGroups[?!contains(logGroupName, `blue`) && !contains(logGroupName, `green`)].logGroupName' \
  --output text

# Xóa log groups cũ (cẩn thận!)
aws logs delete-log-group --log-group-name "pbl4-three-tier-web-access"
aws logs delete-log-group --log-group-name "pbl4-three-tier-web-error"
aws logs delete-log-group --log-group-name "pbl4-three-tier-app-access"
aws logs delete-log-group --log-group-name "pbl4-three-tier-app-error"
aws logs delete-log-group --log-group-name "pbl4-three-tier-web-tier-access-log"
aws logs delete-log-group --log-group-name "pbl4-three-tier-web-tier-error-log"
aws logs delete-log-group --log-group-name "pbl4-three-tier-app-tier-access-log"
aws logs delete-log-group --log-group-name "pbl4-three-tier-app-tier-error-log"
```

---

## ⚠️ Troubleshooting

### **Q: Log groups không được tạo?**

**A:** Kiểm tra:
1. IAM role của EC2 có quyền `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
2. CloudWatch Agent đã chạy thành công:
```bash
# SSH vào instance
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a query -m ec2 -c default -s
```

3. Check user data logs:
```bash
sudo cat /var/log/cloud-init-output.log
```

### **Q: Instances vẫn ghi vào log groups cũ?**

**A:** Launch Template chưa được update. Cần:
1. Terraform apply để update Launch Template
2. Terminate instances cũ để ASG launch instances mới
3. Hoặc update ASG để dùng Launch Template version mới

### **Q: Muốn rollback về log groups cũ?**

**A:** Revert changes:
```bash
git revert <commit-hash>
git push origin main
# Terraform Cloud apply
# Recreate instances
```

---

## 📚 Lợi ích

✅ **Dễ dàng debug**: Biết chính xác logs từ environment nào
✅ **Monitor performance**: So sánh Blue vs Green trực tiếp
✅ **Canary analysis**: Xem error rate của Green trước khi full cutover
✅ **Post-mortem**: Khi rollback, vẫn có logs của Green để phân tích
✅ **Compliance**: Audit logs riêng biệt cho từng environment

---

**Date**: December 20, 2025
**Status**: ✅ Completed
