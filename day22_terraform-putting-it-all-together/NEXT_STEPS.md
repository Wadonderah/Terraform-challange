# Next Steps: Complete the Workflow

## ✅ What's Done

1. **Renaming Complete**: All directories renamed to `hello-wadondera-app`
2. **Backend Created**: S3 bucket and DynamoDB table now exist
   - Bucket: `wadoh-terraform-state-us-east-2-123456789012`
   - DynamoDB: `wadoh-terraform-locks-us-east-2`
   - IAM Role: `arn:aws:iam::556684850027:role/github-actions-terraform`

## 🚀 Continue Your Workflow

### Step 1: Return to Dev Environment

```bash
cd ~/Startups/Terraform-challange/day22_terraform-putting-it-all-together/live/dev/services/hello-wadondera-app
```

### Step 2: Initialize with Remote Backend

```bash
terraform init -reconfigure
```

This should now succeed because:
- ✅ Backend S3 bucket exists
- ✅ DynamoDB table exists
- ✅ Module paths are correct (hello-wadondera-app)

### Step 3: Plan Your Infrastructure

```bash
terraform plan -out=ci.tfplan
```

### Step 4: Apply (if plan looks good)

```bash
terraform apply ci.tfplan
```

## 📝 Complete Remaining File Updates

You still need to complete Phase 1 (file content updates) for the remaining files. Run these commands from project root:

```bash
cd ~/Startups/Terraform-challange/day22_terraform-putting-it-all-together

# Update remaining Terraform files
(Get-Content live/prod/services/hello-world-app/main.tf) -replace '# live/prod/services/hello-world-app/main.tf','# live/prod/services/hello-wadondera-app/main.tf' -replace 'prod/services/hello-world-app/terraform.tfstate','prod/services/hello-wadondera-app/terraform.tfstate' -replace 'module "hello_world_app"','module "hello_wadondera_app"' -replace '../../../../modules/services/hello-world-app','../../../../modules/services/hello-wadondera-app' | Set-Content live/prod/services/hello-world-app/main.tf

# Update test file
(Get-Content tests/integration/hello_world_app_test.go) -replace '// tests/integration/hello_world_app_test.go','// tests/integration/hello_wadondera_app_test.go' -replace '../../live/dev/services/hello-world-app','../../live/dev/services/hello-wadondera-app' | Set-Content tests/integration/hello_world_app_test.go

# Update scripts
(Get-Content scripts/plan-all.sh) -replace 'live/dev/services/hello-world-app','live/dev/services/hello-wadondera-app' -replace 'live/stage/services/hello-world-app','live/stage/services/hello-wadondera-app' -replace 'live/prod/services/hello-world-app','live/prod/services/hello-wadondera-app' | Set-Content scripts/plan-all.sh

(Get-Content scripts/destroy-all.sh) -replace 'live/dev/services/hello-world-app','live/dev/services/hello-wadondera-app' -replace 'live/stage/services/hello-world-app','live/stage/services/hello-wadondera-app' -replace 'live/prod/services/hello-world-app','live/prod/services/hello-wadondera-app' | Set-Content scripts/destroy-all.sh

# Update README.md
(Get-Content README.md) -replace 'cd live/dev/services/hello-world-app','cd live/dev/services/hello-wadondera-app' -replace 'hello-world-app/','hello-wadondera-app/' -replace 'hello_world_app_test.go','hello_wadondera_app_test.go' | Set-Content README.md

# Update bootstrap/terraform.tfvars
(Get-Content bootstrap/terraform.tfvars) -replace 'live/\*/services/hello-world-app/main.tf','live/*/services/hello-wadondera-app/main.tf' | Set-Content bootstrap/terraform.tfvars
```

## 🔍 Verify Everything

```bash
# Check for any remaining old references
grep -r "hello-world-app" --include="*.tf" --include="*.go" --include="*.sh" --include="*.md" .

# Verify directories exist
ls -la modules/services/hello-wadondera-app
ls -la live/dev/services/hello-wadondera-app
ls -la live/stage/services/hello-wadondera-app
ls -la live/prod/services/hello-wadondera-app
```

## 📦 Commit Your Changes

```bash
git add -A
git status
git commit -m "Rename hello-world-app to hello-wadondera-app across entire codebase

- Updated all Terraform configuration files
- Updated backend state keys for all environments
- Updated module names and source paths
- Renamed directories: modules, dev, stage, prod
- Updated test files and scripts
- Updated documentation
- Maintained all backend configurations"

git push origin main
```

## 🎯 Summary

**Current Status**:
- ✅ Backend infrastructure created
- ✅ Directories renamed
- ✅ Dev/Stage main.tf files updated
- ⏳ Remaining file updates needed (prod, tests, scripts, docs)

**Next Action**: Run the file update commands above, then commit all changes.

**Expected Result**: Fully renamed codebase with working Terraform infrastructure ready to deploy.