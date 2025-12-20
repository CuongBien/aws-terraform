# Blue/Green Deployment - Hướng dẫn sử dụng (Terraform Cloud VCS)

> ⚠️ **Lưu ý**: Hướng dẫn này dành cho workflow **Terraform Cloud với VCS (GitHub)**. Variables được quản lý trong Terraform Cloud UI, không dùng `terraform.tfvars` local.

## 📋 Tóm tắt thay đổi

Code đã được cập nhật để hỗ trợ **Blue/Green Deployment** cho Application Layer (Web và App Tier), giúp triển khai ứng dụng với **zero downtime**.

### Những gì đã thay đổi:

#### 1. **ALB Module** - Target Groups Blue/Green
- Tạo 4 Target Groups: 
  - `web-tg-blue` và `web-tg-green` cho Web tier
  - `app-tg-blue` và `app-tg-green` cho App tier
- ALB Listener sử dụng **weighted target groups** để điều khiển traffic
- Có thể chia traffic: 100-0, 90-10, 50-50, hoặc bất kỳ tỷ lệ nào

#### 2. **ASG Module** - Environments Blue/Green
- Mỗi tier có 2 ASG: Blue và Green
- Mỗi ASG có Launch Template riêng
- Có thể bật/tắt từng environment độc lập
- Auto Scaling policies riêng cho từng environment

#### 3. **Variables mới**
- `traffic_distribution_blue/green`: Điều khiển % traffic (0-100)
- `enable_blue_env/green_env`: Bật/tắt environment (true/false)
- `web_ami_id_green/app_ami_id_green`: AMI cho Green (optional, để trống = dùng chung với Blue)

---

## 🔧 Setup ban đầu trong Terraform Cloud

### **Bước 1: Cấu hình Variables trong Terraform Cloud**

1. Truy cập workspace: **`aws-terraform-vcs`**
2. Vào tab **Variables**
3. Thêm các **Terraform Variables**:

| Variable Name | Value | Sensitive | Description |
|--------------|-------|-----------|-------------|
| `db_username` | `admin` | ❌ | Database username |
| `db_password` | `YourSecurePass123!` | ✅ | Database password |
| `enable_blue_env` | `true` | ❌ | Blue environment active |
| `enable_green_env` | `false` | ❌ | Green environment inactive |
| `traffic_distribution_blue` | `100` | ❌ | 100% traffic to Blue |
| `traffic_distribution_green` | `0` | ❌ | 0% traffic to Green |
| `web_ami_id_green` | `""` (trống) | ❌ | Optional: AMI for Green Web |
| `app_ami_id_green` | `""` (trống) | ❌ | Optional: AMI for Green App |

4. Click **Save variables**

### **Bước 2: Trigger deployment đầu tiên**

```bash
# Push code lên GitHub để trigger plan
git add .
git commit -m "Initial Blue/Green infrastructure setup"
git push origin main

# Terraform Cloud sẽ tự động:
# 1. Detect commit mới từ GitHub
# 2. Trigger terraform plan
# 3. Hiển thị plan trong UI

# Bạn cần:
# 4. Review plan trong Terraform Cloud UI
# 5. Click "Confirm & Apply" để deploy
```

**Kết quả**: Hệ thống chạy với Blue environment, 100% traffic đến Blue.


---

## 🚀 Deployment Workflows

### **Scenario 1: Deploy version mới lên Green**

#### Bước 1: Bật Green environment (qua Terraform Cloud UI)

**Cách 1: Quick change qua UI** (Khuyên dùng cho thay đổi variables đơn giản)

1. Terraform Cloud → Workspace → **Variables** tab
2. Edit variables:
   - `enable_green_env` → `true`
   - Giữ nguyên: `traffic_distribution_blue = 100`, `traffic_distribution_green = 0`
3. Click **Save variables**
4. Click **Actions** → **Start new run** → **Plan and apply**
5. Review plan → **Confirm & Apply**

**Cách 2: Qua Git commit** (Cho tracked changes)

```bash
# Tạo empty commit để trigger plan
git commit --allow-empty -m "Enable Green environment for deployment"
git push origin main

# Sau đó vào Terraform Cloud UI:
# 1. Review plan tự động
# 2. Click "Confirm & Apply"
```

**Kết quả**: Green instances được tạo và register vào Green Target Groups, nhưng chưa nhận traffic.

---

#### Bước 2: Test Green environment

```bash
# SSH vào bastion host
ssh -i your-key.pem ec2-user@<bastion-ip>

# Từ bastion, test Green Target Group
# Lấy Green instance IPs từ AWS Console hoặc:
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=green" \
  --query 'Reservations[*].Instances[*].[PrivateIpAddress,State.Name]'

# Curl trực tiếp đến Green instance
curl http://<green-instance-private-ip>
```

**Hoặc check health trong AWS Console:**
- EC2 → Target Groups → `pbl4-three-tier-web-tg-green`
- Xem tab **Targets** → Status phải là **healthy**

---

#### Bước 3: Canary deployment (10% traffic)

**Terraform Cloud UI:**

1. Variables tab → Edit:
   - `traffic_distribution_blue` → `90`
   - `traffic_distribution_green` → `10`
2. Save → Start new run → Confirm & Apply

**Kết quả**: 10% users truy cập Green, 90% vẫn ở Blue.

**Monitor trong 10-15 phút:**
- CloudWatch Metrics: `HTTPCode_Target_5XX_Count`, `TargetResponseTime`
- CloudWatch Logs: `/aws/ec2/web-green`, `/aws/ec2/app-green`
- So sánh performance Blue vs Green

---

#### Bước 4: Tăng dần traffic

**Nếu Green ổn định, tăng dần:**

```
# 50-50 split
traffic_distribution_blue  = 50
traffic_distribution_green = 50

# Monitor 15-30 phút

# 100% Green (full cutover)
traffic_distribution_blue  = 0
traffic_distribution_green = 100
```

Mỗi lần thay đổi: **Terraform Cloud UI → Variables → Edit → Save → Start new run**

---

#### Bước 5: Tắt Blue environment (sau 1-2 ngày)

Sau khi Green ổn định và không có vấn đề:

```
# Terraform Cloud Variables:
enable_blue_env  = false  # Tắt Blue để tiết kiệm chi phí
enable_green_env = true
traffic_distribution_blue  = 0
traffic_distribution_green = 100
```

**Lưu ý**: Blue instances sẽ bị terminate. Không thể rollback nhanh nếu tắt Blue!

---

### **Scenario 2: Rollback khẩn cấp**

Nếu phát hiện lỗi nghiêm trọng ở Green:

#### Emergency Rollback (< 2 phút)

1. **Terraform Cloud UI** → Variables
2. Quick edit:
   - `traffic_distribution_blue` → `100`
   - `traffic_distribution_green` → `0`
3. **Save** → **Start new run**
4. **Confirm & Apply** ngay (không cần đợi plan lâu)

**Thời gian**:
- Plan + Apply: ~1-2 phút
- ALB listener rules update: ~10-20 giây
- Users quay về Blue: ngay lập tức

**Không cần commit Git** cho emergency rollback, dùng UI nhanh hơn!

---

### **Scenario 3: Deploy version tiếp theo (Swap Blue/Green)**

Khi Blue đã tắt và Green đang active (100% traffic):

#### Swap roles: Green → old, Blue → new

**Terraform Cloud Variables:**

```
# Bước 1: Bật Blue với version mới
enable_blue_env  = true    # Enable Blue
enable_green_env = true    # Green vẫn serve traffic
traffic_distribution_blue  = 0    # Blue chưa nhận traffic
traffic_distribution_green = 100  # Green active

# Start new run → Apply

# Bước 2: Test Blue (giống scenario 1 bước 2)

# Bước 3: Canary 10% sang Blue
traffic_distribution_blue  = 10
traffic_distribution_green = 90

# Bước 4: Full cutover to Blue
traffic_distribution_blue  = 100
traffic_distribution_green = 0

# Bước 5: Tắt Green
enable_blue_env  = true
enable_green_env = false
```

---

## 📊 So sánh workflow

| Feature | Terraform Cloud VCS | Local Terraform |
|---------|---------------------|-----------------|
| **Variables** | UI Variables tab | `terraform.tfvars` |
| **Trigger deployment** | Git push / UI "Start new run" | `terraform apply` |
| **Review plan** | Terraform Cloud UI | Terminal output |
| **Apply** | Click "Confirm & Apply" | Auto sau `terraform apply` |
| **State** | Managed by TF Cloud | Local / S3 backend |
| **Rollback speed** | ~1-2 phút (UI edit) | ~1-2 phút (file edit) |
| **Team collaboration** | ✅ Built-in | ❌ Cần setup riêng |
| **Audit log** | ✅ Automatic | ❌ Manual |

---

## ⚙️ Biến cấu hình chi tiết

### Variables trong Terraform Cloud (phải set trong UI)

| Variable | Type | Default | Mô tả |
|----------|------|---------|-------|
| `db_username` | string | - | ⚠️ **Required** - Username cho RDS |
| `db_password` | string | - | ⚠️ **Required, Sensitive** - Password cho RDS |
| `enable_blue_env` | bool | `true` | Enable/disable Blue environment |
| `enable_green_env` | bool | `false` | Enable/disable Green environment |
| `traffic_distribution_blue` | number | `100` | % traffic đến Blue (0-100) |
| `traffic_distribution_green` | number | `0` | % traffic đến Green (0-100) |
| `web_ami_id_green` | string | `""` | AMI cho Green Web (trống = dùng chung Blue) |
| `app_ami_id_green` | string | `""` | AMI cho Green App (trống = dùng chung Blue) |

### Variables với default values (không cần set, có thể override)

| Variable | Default | Override trong TF Cloud nếu cần |
|----------|---------|----------------------------------|
| `project_name` | `"pbl4-three-tier"` | ✅ Có thể override |
| `availability_zones` | `["ap-southeast-2a", "ap-southeast-2b"]` | ✅ Có thể override |
| `key_pair_name` | `"pbl4-three-tier-key"` | ✅ Có thể override |

---

## 🎯 Decision Tree - Khi nào dùng cách nào?

```
Cần thay đổi variables?
│
├─ YES → Thay đổi nhỏ (traffic %, enable/disable)
│   └─ Terraform Cloud UI Variables → Start new run
│       ⏱️ Nhanh nhất: ~1-2 phút
│
├─ YES → Thay đổi code infrastructure
│   └─ Edit code → Git commit → Push
│       ⏱️ ~3-5 phút (auto trigger)
│
└─ EMERGENCY ROLLBACK?
    └─ Terraform Cloud UI Variables → Edit traffic → Start new run
        ⏱️ Khẩn cấp: ~1-2 phút
```

---

## 💡 Best Practices

### 1. **Variable Management**
- ✅ Set sensitive vars (`db_password`) với flag "Sensitive" trong TF Cloud
- ✅ Dùng UI Variables cho quick changes (traffic distribution)
- ✅ Commit code changes cho tracked history
- ❌ Không commit `terraform.tfvars` chứa secrets lên Git

### 2. **Deployment Strategy**
- ✅ Luôn enable Green trước khi chuyển traffic
- ✅ Canary test với 10% traffic ít nhất 15 phút
- ✅ Monitor metrics trước khi tăng traffic
- ✅ Giữ Blue running ít nhất 24h sau khi full cutover
- ❌ Không tắt Blue ngay sau khi switch traffic

### 3. **Rollback Strategy**
- ✅ Giữ Blue environment cho đến khi Green ổn định
- ✅ Dùng UI Variables cho emergency rollback (nhanh nhất)
- ✅ Document incident và lý do rollback
- ❌ Không panic - rollback chỉ mất 1-2 phút

### 4. **Cost Optimization**
- ✅ Tắt environment cũ sau 1-2 ngày stable
- ✅ Scale down (min_size=0) thay vì xóa hoàn toàn
- ✅ Dùng Spot instances cho non-production testing
- ⚠️ Chi phí tăng 2x khi cả Blue và Green chạy

### 5. **Git Workflow**
```bash
# Feature deployment
git checkout -b deploy/green-v2.0
# Edit code if needed
git commit -m "feat: Deploy version 2.0 to Green"
git push origin deploy/green-v2.0
# Review plan in TF Cloud
# Merge to main when ready

# Quick variable changes
# → Dùng Terraform Cloud UI thay vì commit
```

---

## ⚠️ Lưu ý quan trọng

### 1. **Database Shared**
- RDS được shared giữa Blue và Green
- **Schema migrations**: Phải backward compatible
- Test migrations trước trên staging environment
- Rollback code không tự động rollback database

### 2. **Session Persistence**
- ALB listener có session stickiness (1 giờ)
- User không bị chuyển giữa Blue/Green trong session
- Websocket connections có thể bị disconnect khi switch

### 3. **Chi phí**
- Khi cả Blue và Green chạy: **Chi phí EC2 tăng 2x**
- Khuyến nghị: Tắt environment cũ sau 24-48h stable
- Monitor AWS Cost Explorer trong deployment period

### 4. **AMI Configuration**
- `web_ami_id_green = ""` (trống) → Dùng chung AMI với Blue
- Chỉ set AMI riêng khi test AMI mới
- Code deployment qua user_data script, không cần AMI mới

### 5. **Terraform Cloud State**
- State được managed tự động bởi Terraform Cloud
- Không cần backup manual
- Xem state history: Workspace → States tab
- Rollback state nếu cần: States → Version → Actions

### 6. **VCS Integration**
- Mỗi commit trigger auto plan
- Dùng `.gitignore` để exclude `terraform.tfvars`
- PR workflow: Branch → Plan preview → Merge → Apply

---

## 🔍 Monitoring và Debugging

### 1. **Terraform Cloud Monitoring**

**Check run status:**
- Workspace → **Runs** tab
- Xem plan output, apply logs
- Download plan/apply logs nếu cần debug

**Variables audit:**
- Workspace → **Variables** tab → View history
- Xem ai thay đổi variables và khi nào

### 2. **AWS Target Group Health**

```bash
# List all target groups
aws elbv2 describe-target-groups \
  --query 'TargetGroups[*].[TargetGroupName,TargetGroupArn]' \
  --output table

# Check health của Blue target group
aws elbv2 describe-target-health \
  --target-group-arn <web-tg-blue-arn>

# Check health của Green target group
aws elbv2 describe-target-health \
  --target-group-arn <web-tg-green-arn>
```

### 3. **Traffic Distribution Verification**

```bash
# Xem listener rules và weight
aws elbv2 describe-rules \
  --listener-arn <listener-arn> \
  --query 'Rules[*].Actions[*].ForwardConfig'

# Expected output:
# {
#   "TargetGroups": [
#     { "TargetGroupArn": "...-blue", "Weight": 90 },
#     { "TargetGroupArn": "...-green", "Weight": 10 }
#   ]
# }
```

### 4. **CloudWatch Metrics Dashboard**

Key metrics để monitor:

**Target Response Time:**
```
Namespace: AWS/ApplicationELB
Metric: TargetResponseTime
Dimensions: TargetGroup = web-tg-blue vs web-tg-green
```

**Healthy Host Count:**
```
Namespace: AWS/ApplicationELB  
Metric: HealthyHostCount
Dimensions: TargetGroup, AvailabilityZone
```

**Request Count:**
```
Namespace: AWS/ApplicationELB
Metric: RequestCount
Dimensions: TargetGroup = blue vs green
→ Verify traffic split percentage
```

**5XX Errors:**
```
Namespace: AWS/ApplicationELB
Metric: HTTPCode_Target_5XX_Count
Dimensions: TargetGroup
→ Alert if Green has more errors than Blue
```

### 5. **Logs**

```bash
# CloudWatch Logs Insights query
# Logs > Log groups > /aws/ec2/web-green

# Query: Count errors by status code
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)

# Query: Compare response times
fields @timestamp, response_time
| stats avg(response_time) by bin(5m)
```

---

## 🛠️ Troubleshooting

### Q: Green instances không healthy?
**A**: Kiểm tra theo thứ tự:

1. **Security Group rules:**
   ```bash
   # Check inbound rules của Web/App SG
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```

2. **Health check path:**
   - Web tier: `/health` phải return 200-399
   - App tier: `/health.txt` phải return 200-399
   - SSH vào instance và test local: `curl localhost/health`

3. **User data script:**
   ```bash
   # SSH vào Green instance
   ssh -i key.pem ec2-user@<green-instance-ip>
   
   # Check user data logs
   sudo cat /var/log/cloud-init-output.log
   
   # Check application logs
   sudo journalctl -u httpd -f
   ```

4. **CloudWatch Logs:**
   - Terraform Cloud → Plan output → Check for errors
   - AWS Console → CloudWatch → Log groups → `/aws/ec2/web-green`

### Q: Traffic không chuyển sang Green trong Terraform Cloud?
**A**: 

1. **Verify variables đã save:**
   - Terraform Cloud UI → Variables tab
   - Check `traffic_distribution_*` values

2. **Check run status:**
   - Workspace → Runs tab → Latest run
   - Xem plan có update listener rules không

3. **Verify trong AWS:**
   ```bash
   aws elbv2 describe-rules --listener-arn <arn> \
     --query 'Rules[*].Actions[*].ForwardConfig.TargetGroups'
   ```

4. **Wait time:**
   - Sau apply, đợi 1-2 phút để ALB update rules
   - Test bằng nhiều requests: `for i in {1..100}; do curl -s <alb-dns>; done`

### Q: Terraform Cloud plan bị stuck?
**A**: 

1. **Check workspace lock:**
   - Settings → Locking → Unlock if needed
   
2. **Cancel stuck run:**
   - Runs tab → Running run → Force cancel

3. **Check GitHub webhook:**
   - GitHub repo → Settings → Webhooks
   - Verify Terraform Cloud webhook active

### Q: Muốn deploy chỉ Web tier hoặc App tier riêng?
**A**: 

Blue/Green hiện tại deploy cả 2 tiers cùng lúc. Nếu cần deploy riêng:

**Option 1: Module targeting (không khuyến khích cho TF Cloud)**
```bash
# Local workaround (không khả dụng với TF Cloud VCS)
terraform apply -target=module.asg.aws_autoscaling_group.web_green
```

**Option 2: Tách module (khuyên dùng)**
- Tách `modules/asg` thành `modules/asg_web` và `modules/asg_app`
- Deploy riêng biệt qua separate workspaces

### Q: Rollback không hoạt động?
**A**: 

1. **Check Blue environment còn chạy không:**
   ```bash
   # Terraform Cloud Variables
   enable_blue_env = true (phải)
   ```

2. **Nếu Blue đã bị terminate:**
   - Set `enable_blue_env = true`
   - Apply để re-create Blue instances
   - Đợi instances healthy (~5-10 phút)
   - Sau đó mới chuyển traffic về Blue

3. **Emergency: Nếu không còn Blue:**
   - Rollback code changes trên Git
   - Push lên GitHub
   - Terraform Cloud sẽ re-create infrastructure

### Q: Plan/Apply trong Terraform Cloud lâu hơn local?
**A**: 

**Bình thường** - Terraform Cloud có thêm overhead:
- Queue time: 0-30 giây
- Plan/Apply: tương tự local
- Total: thêm ~30-60 giây

**Nếu quá lâu (>5 phút):**
- Check workspace queue: Settings → General
- Upgrade plan nếu cần (Free tier có giới hạn concurrency)

### Q: Variables trong TF Cloud bị override?
**A**: 

**Variable precedence** (cao → thấp):
1. Workspace UI variables (✅ Dùng cái này)
2. `*.auto.tfvars` (committed)
3. `default` trong `variables.tf`

**Fix:**
- Xóa `*.auto.tfvars` nếu conflict
- Hoặc rename thành `*.tfvars.example` (không load)

### Q: Chi phí tăng đột ngột?
**A**: 

**Check:**
```bash
# Xem số instances đang chạy
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*pbl4*" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Environment`].Value]'
```

**Action:**
- Tắt environment không dùng: `enable_*_env = false`
- Scale down ASG: Edit variables `desired_capacity`
- Check CloudWatch billing alarm

---

## 📚 Tham khảo thêm

- [AWS Blue/Green Deployment Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/welcome.html)
- [ALB Weighted Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-routing-configuration)
- [Terraform Cloud VCS Integration](https://developer.hashicorp.com/terraform/cloud-docs/vcs)
- [Terraform Lifecycle Meta-Arguments](https://www.terraform.io/language/meta-arguments/lifecycle)

---

## 📞 Quick Reference

### Variables cho Terraform Cloud

```hcl
# Copy-paste vào Terraform Cloud UI → Variables tab

# Required
db_username                = "admin"
db_password                = "YourSecurePass123!"  # Mark as Sensitive

# Blue/Green Control
enable_blue_env            = true / false
enable_green_env           = false / true
traffic_distribution_blue  = 0 - 100
traffic_distribution_green = 0 - 100

# Optional
web_ami_id_green          = ""  # Để trống = dùng chung Blue
app_ami_id_green          = ""  # Để trống = dùng chung Blue
```

### Common Workflows

```bash
# 1. Enable Green
# TF Cloud UI: enable_green_env = true → Start new run

# 2. Canary test
# TF Cloud UI: traffic_*_blue=90, traffic_*_green=10 → Apply

# 3. Full cutover
# TF Cloud UI: traffic_*_blue=0, traffic_*_green=100 → Apply

# 4. Cleanup
# TF Cloud UI: enable_blue_env=false → Apply

# 5. Emergency rollback
# TF Cloud UI: traffic_*_blue=100, traffic_*_green=0 → Apply NOW
```

---

**Workflow**: Terraform Cloud VCS (GitHub)  
**Người tạo**: GitHub Copilot  
**Ngày**: December 20, 2025  
**Version**: 2.0 - Updated for Terraform Cloud
