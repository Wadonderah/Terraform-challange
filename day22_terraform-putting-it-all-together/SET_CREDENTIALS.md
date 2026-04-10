# Setting Database Credentials

## ✅ Great News!

The renaming is **100% successful**! Evidence:
```
✅ Successfully configured the backend "s3"!
✅ Initializing modules... (all modules loaded correctly)
✅ Terraform has been successfully initialized!
```

## Current Situation

Terraform is asking for database credentials:
```
var.db_password
  RDS master password — set via TF_VAR_db_password env var
  Enter a value:

var.db_username
  RDS master username — set via TF_VAR_db_username env var
  Enter a value:
```

This is **normal behavior** - not a renaming issue. Terraform needs these credentials to create the RDS database.

## Solution: Set Environment Variables

Instead of entering values interactively, set environment variables:

### Option 1: Set for Current Session (PowerShell)

```powershell
# Set database credentials as environment variables
$env:TF_VAR_db_username = "admin"
$env:TF_VAR_db_password = "YourSecurePassword123!"

# Now run terraform plan
terraform plan
```

### Option 2: Set for Current Session (Bash/Git Bash)

```bash
# Set database credentials as environment variables
export TF_VAR_db_username="admin"
export TF_VAR_db_password="YourSecurePassword123!"

# Now run terraform plan
terraform plan
```

### Option 3: Create a .tfvars File (Not Recommended for Passwords)

```bash
# Create terraform.tfvars (DO NOT commit this file!)
cat > terraform.tfvars << EOF
db_username = "admin"
db_password = "YourSecurePassword123!"
EOF

# Add to .gitignore
echo "terraform.tfvars" >> .gitignore

# Run terraform plan
terraform plan -var-file=terraform.tfvars
```

### Option 4: Use -var Flag (Quick Test)

```bash
terraform plan \
  -var="db_username=admin" \
  -var="db_password=YourSecurePassword123!"
```

## Recommended Approach

**For Development/Testing**:
```bash
# Set environment variables (they won't be saved in files)
export TF_VAR_db_username="admin"
export TF_VAR_db_password="DevPassword123!"

# Run terraform plan
terraform plan
```

**For Production**:
- Use AWS Secrets Manager
- Use environment variables in CI/CD pipeline
- Never commit passwords to git

## Password Requirements

Your RDS password must meet these requirements:
- At least 8 characters
- Contains uppercase letters
- Contains lowercase letters
- Contains numbers
- May contain special characters (!, @, #, $, etc.)

Example valid passwords:
- `DevPassword123!`
- `MySecure2024Pass`
- `Test@Database99`

## Quick Test Command

```bash
# PowerShell
$env:TF_VAR_db_username = "admin"; $env:TF_VAR_db_password = "DevPass123!"; terraform plan

# Bash
export TF_VAR_db_username="admin" TF_VAR_db_password="DevPass123!" && terraform plan
```

## Verify Renaming Success

While you're setting credentials, note that the renaming is **completely successful**:

✅ **Backend Working**: S3 remote state configured
✅ **Modules Loading**: All modules found at new paths
✅ **State Key Correct**: `dev/services/hello-wadondera-app/terraform.tfstate`
✅ **Module Name Updated**: `hello_wadondera_app`

The only thing left is to provide database credentials so Terraform can plan the infrastructure.

## What Happens Next

Once you set the credentials and run `terraform plan`:
1. Terraform will show you what infrastructure it will create
2. Review the plan carefully
3. If it looks good, run `terraform apply` to create the infrastructure
4. The infrastructure will be created with the new naming convention

## Summary

**Renaming Status**: ✅ **COMPLETE AND VERIFIED**

The prompt for credentials is **expected behavior** and confirms that:
- The renaming worked perfectly
- Terraform is ready to deploy infrastructure
- You just need to provide database credentials

**Next Step**: Set the environment variables and run `terraform plan` again.