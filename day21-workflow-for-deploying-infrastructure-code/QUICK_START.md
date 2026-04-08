# Quick Start Guide - Infrastructure Code Workflow

This guide gets you up and running with the infrastructure code workflow in 5 minutes.

## Prerequisites

- Git installed
- Terraform 1.6+ installed
- AWS CLI configured
- Python 3.7+ (for pre-commit)

## Setup (One-Time)

### 1. Install Development Tools

**On macOS/Linux:**
```bash
# Run automated setup
bash scripts/setup-dev-environment.sh
```

**On Windows:**
```powershell
# Install pre-commit
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Configure git
git config commit.template .gitmessage

# Install tflint (download from https://github.com/terraform-linters/tflint/releases)
# Install tfsec (download from https://github.com/aquasecurity/tfsec/releases)
```

### 2. Verify Setup

```bash
# Check compliance
bash scripts/verify-compliance.sh
```

## Daily Workflow

### Making Infrastructure Changes

```bash
# 1. Create feature branch
git checkout -b feat-add-monitoring

# 2. Make your changes
# Edit .tf files...

# 3. Format and validate
terraform fmt -recursive
terraform validate

# 4. Generate plan
terraform workspace select dev
terraform plan -out=my-change.tfplan

# 5. Review plan output
terraform show my-change.tfplan

# 6. Analyze blast radius
bash scripts/analyze-blast-radius.sh my-change.tfplan

# 7. Commit changes (template will open)
git add .
git commit
# Fill in the template with:
# - What changed
# - Plan summary (created/modified/destroyed counts)
# - Blast radius
# - Testing performed

# 8. Push and create PR
git push origin feat-add-monitoring
# Create PR on GitHub using infrastructure_change.md template
```

### Pull Request Checklist

When creating a PR, ensure:

- [ ] Terraform plan output included in PR description
- [ ] Resource counts documented (created/modified/destroyed)
- [ ] Blast radius analyzed and documented
- [ ] Rollback plan described
- [ ] All CI checks passing (fmt, validate, tflint, tfsec, plan, test)
- [ ] At least 1 approval from infrastructure team
- [ ] If destructive changes: 2nd approval from infrastructure-leads

### Deploying Changes

```bash
# After PR is merged to main:

# 1. Pull latest
git checkout main
git pull

# 2. Select workspace
terraform workspace select dev

# 3. Generate fresh plan
terraform plan -out=deploy.tfplan

# 4. Review plan one more time
terraform show deploy.tfplan

# 5. Apply using safe-apply script
bash scripts/safe-apply.sh deploy.tfplan my-state-bucket dev

# 6. Verify deployment
terraform plan  # Should show "No changes"

# 7. Check AWS resources
# Verify in AWS console that resources are as expected
```

## Common Commands

### Pre-commit Hooks
```bash
# Run all hooks manually
pre-commit run --all-files

# Update hooks to latest versions
pre-commit autoupdate

# Skip hooks temporarily (emergency only)
git commit --no-verify
```

### Terraform Operations
```bash
# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate

# Run unit tests
terraform test

# Generate plan
terraform plan -out=plan.tfplan

# Apply saved plan
terraform apply plan.tfplan

# Show plan in human-readable format
terraform show plan.tfplan

# Show plan in JSON format
terraform show -json plan.tfplan | jq
```

### Linting and Security
```bash
# Run tflint
tflint --config=.tflint.hcl

# Run tfsec
tfsec .

# Run both
pre-commit run --all-files
```

### State Management
```bash
# List state versions
bash scripts/list-state-versions.sh my-state-bucket dev 10

# Restore previous state version
aws s3api get-object \
  --bucket my-state-bucket \
  --key dev/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.restored

terraform state push terraform.tfstate.restored
```

### Release Management
```bash
# Create a new release
bash scripts/create-release.sh v1.1.0 "Add monitoring and alerting"

# List all releases
git tag -l

# View release details
git show v1.1.0
```

## Troubleshooting

### Pre-commit Hooks Failing

**Problem:** Hooks fail on commit

**Solution:**
```bash
# Run hooks manually to see detailed errors
pre-commit run --all-files

# Fix issues and try again
terraform fmt -recursive
git add .
git commit
```

### Plan Shows Unexpected Changes

**Problem:** `terraform plan` shows changes you didn't make

**Solution:**
```bash
# Check for state drift
terraform refresh

# Review what changed
terraform show

# If drift is expected, document in PR
# If drift is unexpected, investigate before applying
```

### CI Pipeline Failing

**Problem:** GitHub Actions checks fail

**Solution:**
1. Check the specific failing job in GitHub Actions
2. Run the same command locally:
   ```bash
   terraform fmt -check -recursive  # Format check
   terraform validate               # Validation
   tflint                          # Linting
   tfsec .                         # Security
   terraform test                  # Tests
   ```
3. Fix issues and push again

### Branch Protection Blocking Push

**Problem:** Cannot push to main branch

**Solution:**
This is expected! All changes must go through pull requests:
```bash
# Create feature branch instead
git checkout -b feat-my-change
git push origin feat-my-change
# Then create PR on GitHub
```

### Destructive Changes Blocked

**Problem:** safe-apply.sh requires "DESTROY" confirmation

**Solution:**
This is a safety feature for destructive changes:
1. Verify you have backups/snapshots
2. Get secondary approval from infrastructure-leads
3. Document rollback plan
4. Type "DESTROY" when prompted

## Getting Help

- **Documentation:** See README.md and IMPLEMENTATION_GUIDE.md
- **Compliance:** Run `bash scripts/verify-compliance.sh`
- **Team Chat:** #infrastructure-team Slack channel
- **On-call:** PagerDuty escalation for emergencies

## Best Practices

### DO ✅
- Always work in feature branches
- Include terraform plan output in PRs
- Document blast radius for all changes
- Run pre-commit hooks before pushing
- Use semantic version tags for releases
- Test in dev before production
- Keep commits focused and atomic

### DON'T ❌
- Never commit directly to main
- Never skip CI checks (except emergencies)
- Never apply without a saved plan file
- Never destroy resources without backups
- Never bypass branch protection
- Never commit secrets or credentials
- Never make changes without a PR

## Next Steps

1. **Read the full workflow:** See README.md for detailed explanation
2. **Review compliance:** Check COMPLIANCE_AUDIT_REPORT.md
3. **Follow implementation guide:** See IMPLEMENTATION_GUIDE.md for setup
4. **Practice:** Make a test change in dev environment
5. **Get certified:** Complete infrastructure workflow training

---

**Last Updated:** 2026-04-08  
**Version:** 1.0.0  
**Maintained by:** Infrastructure Team