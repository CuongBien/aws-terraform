# Security Scanning with tfsec and checkov

## 🎯 Overview

This project uses two security scanning tools to ensure Terraform code follows security best practices:

- **tfsec**: Static analysis security scanner for Terraform
- **checkov**: Policy-as-code security scanner for infrastructure

## 📦 Installation

### Local Installation

**macOS/Linux:**
```bash
# Install tfsec
brew install tfsec

# Install checkov
pip install checkov
```

**Windows:**
```powershell
# Install tfsec
choco install tfsec

# Install checkov
pip install checkov
```

### Jenkins Installation

Ensure Jenkins agent has both tools installed:
```bash
# Add to Jenkins Dockerfile or install on agent
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
pip install checkov
```

## 🚀 Usage

### Quick Scan (Recommended)

**Linux/macOS:**
```bash
chmod +x scripts/security-scan.sh
./scripts/security-scan.sh
```

**Windows:**
```powershell
.\scripts\security-scan.ps1
```

### Manual Scanning

**tfsec only:**
```bash
tfsec infrastructure_aws --config-file .tfsec.yml
```

**checkov only:**
```bash
checkov -d infrastructure_aws --config-file .checkov.yml
```

**Both tools:**
```bash
tfsec infrastructure_aws --config-file .tfsec.yml && \
checkov -d infrastructure_aws --config-file .checkov.yml
```

## ⚙️ Configuration

### tfsec Configuration (`.tfsec.yml`)

Controls:
- Severity levels to report (CRITICAL, HIGH, MEDIUM, LOW)
- Minimum severity to fail build (HIGH)
- Excluded checks (documented exceptions)

### checkov Configuration (`.checkov.yml`)

Controls:
- Directories to scan
- Specific checks to skip
- Output formats (cli, json)
- Soft-fail mode
- External module scanning

## 🔍 CI/CD Integration

### Jenkins Pipeline

Security scan runs automatically after checkout:

```groovy
stage('Security Scan') {
    steps {
        script {
            // Run tfsec with soft-fail
            sh "tfsec infrastructure_aws --config-file .tfsec.yml --soft-fail"
            
            // Run checkov with soft-fail
            sh "checkov -d infrastructure_aws --config-file .checkov.yml --soft-fail"
        }
    }
}
```

**Soft-fail mode**: Scans run and report issues but don't block deployment.

### Local Pre-commit Hook (Optional)

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
./scripts/security-scan.sh || exit 1
```

## 📊 Understanding Results

### tfsec Output

```
Result #1 HIGH Encryption at rest is not enabled
─────────────────────────────────────────────────────────────
  modules/rds/main.tf:45-60
─────────────────────────────────────────────────────────────
   45    resource "aws_db_instance" "main" {
   ..
   60    }
```

### checkov Output

```
Check: CKV_AWS_16: "Ensure RDS database is encrypted"
  FAILED for resource: aws_db_instance.main
  File: /modules/rds/main.tf:45-60
```

## 🛡️ Security Exceptions

Some checks are intentionally ignored with inline comments:

**Public ALB** (Required for public access):
```terraform
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "main" { ... }
```

**HTTP Internal Traffic** (Trusted internal network):
```terraform
#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http" { ... }
```

**RDS IAM Auth** (Not needed for this project):
```terraform
#tfsec:ignore:aws-rds-enable-iam-auth
resource "aws_db_instance" "main" { ... }
```

## 🔧 Customization

### Add More Exclusions

**In `.tfsec.yml`:**
```yaml
exclude:
  - aws-vpc-no-public-ingress-acl
```

**In `.checkov.yml`:**
```yaml
skip-check:
  - CKV_AWS_18
```

### Change Severity Threshold

**In `.tfsec.yml`:**
```yaml
minimum_severity: MEDIUM  # Stricter: fail on MEDIUM and above
```

### Fail Hard Mode (Block on Issues)

**In `.checkov.yml`:**
```yaml
soft-fail: false  # Fail build if issues found
```

**In Jenkinsfile**: Remove `--soft-fail` flags

## 📚 Resources

- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
- [tfsec Checks List](https://aquasecurity.github.io/tfsec/latest/checks/aws/)
- [checkov Documentation](https://www.checkov.io/)
- [checkov AWS Checks](https://www.checkov.io/5.Policy%20Index/terraform.html)

## 🎯 Best Practices

1. **Run scans locally** before committing
2. **Review all findings** - don't blindly skip
3. **Document exceptions** with inline comments
4. **Keep tools updated**: `brew upgrade tfsec` / `pip install --upgrade checkov`
5. **Use in CI/CD** to catch issues early
6. **Balance security vs practicality** - not all findings need fixing

## 🚨 Troubleshooting

**"command not found"**: Install tools (see Installation section)

**"No Terraform files found"**: Run from project root directory

**Too many warnings**: Adjust severity in config files

**False positives**: Add to skip-check lists with justification
