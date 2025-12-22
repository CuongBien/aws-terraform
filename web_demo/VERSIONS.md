# 🎨 Blue/Green Frontend Versions

## Visual Differences

### **v1.0 (Blue - Stable Production)**
- 🟣 **Purple gradient theme** (#667eea → #764ba2)
- Classic clean design
- Standard message board
- Badge: "v1.0 (Blue)"
- Purpose: Represents current stable production

### **v2.0 (Green - New Features)**  
- 🟢 **Green/Teal gradient theme** (#11998e → #38ef7d)
- Modern enhanced UI
- Real-time statistics dashboard
- Delete message functionality
- "NEW VERSION" banner
- Badge: "v2.0 (Green)"
- Purpose: Represents new version with enhanced features

---

## Quick Build Commands

### Build Blue Environment (v1.0)
```bash
cd packer
./build.sh --tier web --version v1.0 --color blue
./build.sh --tier app --version v1.0 --color blue
```

### Build Green Environment (v2.0)
```bash
cd packer
./build.sh --tier web --version v2.0 --color green
./build.sh --tier app --version v2.0 --color green
```

---

## How It Works

1. **Packer templates** use conditional logic:
   ```hcl
   locals {
     frontend_source = var.version == "v1.0" ? 
                      "frontend-v1.0" : "frontend-v2.0"
   }
   ```

2. **v1.0 build** → Copies `frontend-v1.0/` → Bakes into AMI
3. **v2.0 build** → Copies `frontend-v2.0/` → Bakes into AMI

4. **Result**: Two distinct AMIs with different UI baked in

---

## Deployment Demo Flow

### Phase 1: Canary (10% Green)
```bash
# Jenkins: TRAFFIC_SPLIT=canary-10
# Result: 90% see Purple UI (v1.0), 10% see Green UI (v2.0)
```

### Phase 2: Half Rollout (50% Green)
```bash
# Jenkins: TRAFFIC_SPLIT=half-50
# Result: 50% Purple, 50% Green
```

### Phase 3: Full Rollout (100% Green)
```bash
# Jenkins: TRAFFIC_SPLIT=full-100
# Result: 100% Green UI (v2.0)
```

### Rollback
```bash
# Jenkins: Rollback stage
# Result: Returns to previous distribution
```

---

## Verification Commands

### Check which version you're hitting:
```bash
curl http://<ALB-DNS>/version.txt

# v1.0 = Purple UI
# v2.0 = Green UI
```

### Refresh browser 10 times during canary:
- ~9 times: Purple UI (v1.0)
- ~1 time: Green UI (v2.0)

Visual confirmation of Blue/Green deployment working!

---

## Files Structure

```
web_demo/
├── frontend-v1.0/
│   └── index.html      # Purple theme (Blue)
├── frontend-v2.0/
│   └── index.html      # Green theme (Green)
└── backend/
    └── api/            # Shared backend (both versions)
```

**Note**: Backend API is the same for both versions - only frontend differs.
