# Day 21 - Quick Reference Card

## 📍 Path
```
c:/Users/wadon/Startups/Terraform-challange/day21-workflow-for-deploying-infrastructure-code
```

## 🚀 Essential Commands (Copy & Paste)

### Initial Setup (One-Time)
```powershell
# Navigate to directory
cd c:/Users/wadon/Startups/Terraform-challange/day21-workflow-for-deploying-infrastructure-code

# Install pre-commit hooks
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Configure git
git config commit.template .gitmessage

# Initialize Terraform
terraform init
```

### Daily Workflow (Most Common)
```powershell
# 1. Create feature branch
git checkout main
git pull origin main
git checkout -b add-feature-name

# 2. Select workspace (create if doesn't exist)
terraform workspace select dev || terraform workspace new dev

# 3. Format and validate
terraform fmt -recursive
terraform validate

# 4. Generate plan
terraform plan -out=feature.tfplan

# 5. Review plan
terraform show feature.tfplan

# 6. Commit changes
git add .
git commit  # Template will open

# 7. Push branch
git push origin add-feature-name

# 8. After PR approval and merge
git checkout main
git pull origin main

# 9. Tag release
git tag -a "v1.x.x" -m "Description"
git push origin v1.x.x

# 10. Deploy
terraform workspace select dev
terraform plan -out=deploy.tfplan
bash scripts/safe-apply.sh deploy.tfplan my-terraform-state-bucket dev

# 11. Verify
terraform plan  # Should show "No changes"
```

### Quick Checks
```powershell
# Check current workspace
terraform workspace show

# List all resources
terraform state list

# Check for drift
terraform plan

# View state versions
bash scripts/list-state-versions.sh my-terraform-state-bucket dev 10

# Run tests
terraform test
pre-commit run --all-files
```

### Emergency Commands
```powershell
# Force unlock (if stuck)
terraform force-unlock <LOCK_ID>

# Restore state from backup
aws s3api get-object `
  --bucket my-terraform-state-bucket `
  --key dev/terraform.tfstate `
  --version-id <VERSION_ID> `
  terraform.tfstate.restored
terraform state push terraform.tfstate.restored

# Rollback deployment
git revert <COMMIT_SHA>
git push origin main
```

## 📋 Pre-Flight Checklist

Before every apply:
- [ ] On correct workspace (`terraform workspace show`)
- [ ] Plan saved to file (`-out=file.tfplan`)
- [ ] Plan reviewed (`terraform show file.tfplan`)
- [ ] Blast radius documented
- [ ] S3 versioning enabled
- [ ] Backup plan ready

## 🔗 Quick Links

- **Full Commands:** `COMMANDS_TO_RUN.md`
- **Quick Start:** `QUICK_START.md`
- **State Recovery:** `STATE_RESTORATION_PROCEDURES.md`
- **Infrastructure vs App:** `INFRASTRUCTURE_VS_APPLICATION_DEPLOYMENT.md`

## 📞 Support

- **Slack:** #infrastructure-team
- **Emergency:** PagerDuty escalation
- **Documentation:** See README.md

---

**Keep this card handy for daily operations!**