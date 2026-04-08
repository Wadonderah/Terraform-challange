# Running Automated Tests - Command Reference

## Quick Test Commands

### 1. Run Compliance Verification (Recommended First)
```bash
bash scripts/verify-compliance.sh
```
**What it checks:**
- Branch protection status
- Version tags
- Pre-commit hooks
- CODEOWNERS file
- CI pipeline configuration
- Sentinel policies
- Required tools installation
- Documentation completeness

**Expected output:** Compliance score with pass/fail/warning counts

---

### 2. Run Terraform Unit Tests
```bash
# Navigate to module directory
cd modules/webserver-cluster

# Run all tests
terraform test

# Run specific test file
terraform test tests/cloudwatch_alarms.tftest.hcl
```
**What it tests:**
- CloudWatch alarm configurations
- SNS topic setup
- Default threshold values
- Alarm naming conventions
- Missing data handling
- Encryption requirements

**Expected output:** All tests should pass (green checkmarks)

---

### 3. Run Pre-commit Hooks (All Quality Checks)
```bash
# Install pre-commit first (if not already done)
pip install pre-commit
pre-commit install

# Run all hooks on all files
pre-commit run --all-files
```
**What it checks:**
- Terraform formatting (terraform fmt)
- Terraform validation (terraform validate)
- TFLint (provider-aware linting)
- TFSec (security scanning)
- YAML/JSON syntax
- Trailing whitespace
- Large files
- Private keys
- Merge conflicts

**Expected output:** All hooks should pass

---

### 4. Run Individual Quality Checks

#### Format Check
```bash
terraform fmt -check -recursive
```
**Fix formatting:**
```bash
terraform fmt -recursive
```

#### Validation
```bash
cd modules/webserver-cluster
terraform init -backend=false
terraform validate
```

#### Linting (TFLint)
```bash
# Initialize tflint plugins first
tflint --init

# Run linting
tflint --config=.tflint.hcl
```

#### Security Scan (TFSec)
```bash
tfsec .
```

---

### 5. Run Blast Radius Analysis
```bash
# First generate a plan
cd modules/webserver-cluster
terraform init
terraform workspace select dev
terraform plan -out=test.tfplan

# Analyze blast radius
cd ../..
bash scripts/analyze-blast-radius.sh modules/webserver-cluster/test.tfplan
```
**What it shows:**
- Resource change summary
- Shared/critical resources affected
- Stateful resources
- Destructive changes
- Impact assessment
- Rollback complexity

---

### 6. Run GitHub Actions CI Locally (Optional)

If you have `act` installed:
```bash
# Install act: https://github.com/nektos/act
# brew install act (macOS)
# choco install act-cli (Windows)

# Run CI pipeline locally
act pull_request
```

---

## Complete Test Suite (Run All)

```bash
#!/bin/bash
# Save this as run-all-tests.sh

echo "🧪 Running Complete Test Suite"
echo "================================"
echo ""

# 1. Compliance check
echo "1️⃣ Compliance Verification..."
bash scripts/verify-compliance.sh
echo ""

# 2. Pre-commit hooks
echo "2️⃣ Pre-commit Hooks..."
pre-commit run --all-files
echo ""

# 3. Terraform tests
echo "3️⃣ Terraform Unit Tests..."
cd modules/webserver-cluster
terraform test
cd ../..
echo ""

# 4. Format check
echo "4️⃣ Format Check..."
terraform fmt -check -recursive
echo ""

# 5. Validation
echo "5️⃣ Validation..."
cd modules/webserver-cluster
terraform init -backend=false
terraform validate
cd ../..
echo ""

# 6. Linting
echo "6️⃣ TFLint..."
tflint --init
tflint --config=.tflint.hcl
echo ""

# 7. Security scan
echo "7️⃣ Security Scan..."
tfsec .
echo ""

echo "✅ All tests complete!"
```

**Run it:**
```bash
bash run-all-tests.sh
```

---

## Troubleshooting Test Failures

### Pre-commit Hook Failures

**Error:** `terraform fmt` fails
```bash
# Fix: Auto-format all files
terraform fmt -recursive
git add .
```

**Error:** `terraform validate` fails
```bash
# Fix: Check error message and fix syntax
cd modules/webserver-cluster
terraform init -backend=false
terraform validate
# Fix reported issues
```

**Error:** `tflint` not found
```bash
# Install tflint
# macOS: brew install tflint
# Linux: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
# Windows: Download from https://github.com/terraform-linters/tflint/releases

# Initialize plugins
tflint --init
```

**Error:** `tfsec` not found
```bash
# Install tfsec
# macOS: brew install tfsec
# Linux: curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
# Windows: Download from https://github.com/aquasecurity/tfsec/releases
```

### Terraform Test Failures

**Error:** Provider not configured
```bash
# Tests use mock providers, no AWS credentials needed
# If error persists, check test file syntax
```

**Error:** Module not found
```bash
# Ensure you're in the correct directory
cd modules/webserver-cluster
terraform test
```

### Compliance Check Failures

**Error:** Branch protection not enabled
```bash
# This requires manual GitHub configuration
# See: .github/branch-protection-config.md
```

**Error:** No version tags
```bash
# Create initial tag
git tag -a "v1.0.0" -m "Initial release"
git push origin v1.0.0
```

---

## CI/CD Pipeline Tests

The GitHub Actions pipeline runs automatically on every PR. To see what it tests:

```bash
# View workflow file
cat .github/workflows/terraform-ci.yml
```

**Pipeline includes:**
1. Format Check (`terraform fmt --check`)
2. Validation (`terraform validate`)
3. TFLint (provider-aware linting)
4. TFSec (security scanning)
5. Terraform Plan (with PR comment)
6. Terraform Tests (unit tests)

**View pipeline status:**
- Go to GitHub repository
- Click "Actions" tab
- View recent workflow runs

---

## Test Coverage Summary

| Test Type | Command | What It Checks | Required |
|-----------|---------|----------------|----------|
| Compliance | `bash scripts/verify-compliance.sh` | Workflow compliance | ✅ Yes |
| Unit Tests | `terraform test` | Module functionality | ✅ Yes |
| Format | `terraform fmt -check` | Code formatting | ✅ Yes |
| Validation | `terraform validate` | Syntax correctness | ✅ Yes |
| Linting | `tflint` | Best practices | ✅ Yes |
| Security | `tfsec` | Security issues | ✅ Yes |
| Pre-commit | `pre-commit run --all-files` | All quality checks | ✅ Yes |
| Blast Radius | `bash scripts/analyze-blast-radius.sh` | Impact analysis | ⚠️ Recommended |

---

## Continuous Testing

### Before Every Commit
```bash
# Pre-commit hooks run automatically
git commit -m "Your message"

# Or run manually
pre-commit run --all-files
```

### Before Every PR
```bash
# Run full test suite
bash run-all-tests.sh

# Generate and review plan
terraform plan -out=pr.tfplan
bash scripts/analyze-blast-radius.sh pr.tfplan
```

### Before Every Deployment
```bash
# Compliance check
bash scripts/verify-compliance.sh

# Fresh plan
terraform plan -out=deploy.tfplan

# Blast radius analysis
bash scripts/analyze-blast-radius.sh deploy.tfplan

# Safe apply
bash scripts/safe-apply.sh deploy.tfplan my-state-bucket dev
```

---

## Quick Reference Card

```bash
# Essential commands to run before committing:

# 1. Format
terraform fmt -recursive

# 2. Validate
terraform validate

# 3. Test
terraform test

# 4. Pre-commit
pre-commit run --all-files

# 5. Compliance
bash scripts/verify-compliance.sh
```

---

**Need Help?**
- Check QUICK_START.md for workflow guide
- See IMPLEMENTATION_GUIDE.md for detailed setup
- Review test output for specific error messages
- Ask in #infrastructure-team Slack channel