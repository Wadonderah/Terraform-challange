# Fix: Terminal Not Accepting Input

## The Problem

When Terraform prompts for `db_username` and `db_password`, you can't type anything or the input isn't visible.

## Quick Solutions

### Solution 1: Use Environment Variables (RECOMMENDED)

**Stop the current terraform command** (Ctrl+C if it's still running), then:

#### For Git Bash (MINGW64):
```bash
# Set environment variables
export TF_VAR_db_username="admin"
export TF_VAR_db_password="DevPass123!"

# Verify they're set
echo $TF_VAR_db_username
echo $TF_VAR_db_password

# Now run terraform plan (it won't prompt anymore)
terraform plan
```

#### For PowerShell:
```powershell
# Set environment variables
$env:TF_VAR_db_username = "admin"
$env:TF_VAR_db_password = "DevPass123!"

# Verify they're set
echo $env:TF_VAR_db_username
echo $env:TF_VAR_db_password

# Now run terraform plan (it won't prompt anymore)
terraform plan
```

### Solution 2: Use Command Line Variables

```bash
# Run terraform plan with variables directly
terraform plan \
  -var="db_username=admin" \
  -var="db_password=DevPass123!"
```

### Solution 3: Create a Variables File

```bash
# Create a terraform.tfvars file
cat > terraform.tfvars << 'EOF'
db_username = "admin"
db_password = "DevPass123!"
EOF

# Make sure it's in .gitignore
echo "terraform.tfvars" >> .gitignore

# Run terraform plan (it will automatically use terraform.tfvars)
terraform plan
```

### Solution 4: Use -auto-approve with Apply (Skip Plan)

If you just want to apply without interactive prompts:

```bash
# Set environment variables first
export TF_VAR_db_username="admin"
export TF_VAR_db_password="DevPass123!"

# Apply directly (skips plan file)
terraform apply -auto-approve
```

## Why This Happens

Common causes:
1. **Terminal buffering**: Git Bash/MINGW64 sometimes has input buffering issues
2. **Password fields**: Terraform hides password input (you're typing but can't see it)
3. **Terminal mode**: The terminal might be in the wrong input mode

## Recommended Workflow

**Best practice for your situation**:

```bash
# 1. Cancel any running terraform command
# Press Ctrl+C

# 2. Set environment variables (Git Bash/MINGW64)
export TF_VAR_db_username="admin"
export TF_VAR_db_password="DevPass123!"

# 3. Verify they're set
echo "Username: $TF_VAR_db_username"
echo "Password is set: $([ -n "$TF_VAR_db_password" ] && echo 'Yes' || echo 'No')"

# 4. Run terraform plan (no prompts!)
terraform plan

# 5. If plan looks good, apply
terraform apply
```

## Alternative: Skip Interactive Mode Entirely

```bash
# One-liner that sets variables and runs plan
TF_VAR_db_username="admin" TF_VAR_db_password="DevPass123!" terraform plan

# Or for apply:
TF_VAR_db_username="admin" TF_VAR_db_password="DevPass123!" terraform apply -auto-approve
```

## Troubleshooting

### If you're stuck at the prompt:
1. Press `Ctrl+C` to cancel
2. Close and reopen your terminal
3. Navigate back to the directory
4. Use environment variables method

### If environment variables don't work:
```bash
# Check if they're set
env | grep TF_VAR

# If not showing, try setting them again
export TF_VAR_db_username="admin"
export TF_VAR_db_password="DevPass123!"

# Run in the same terminal session
terraform plan
```

### If nothing works:
```bash
# Use the variables file method
echo 'db_username = "admin"' > terraform.tfvars
echo 'db_password = "DevPass123!"' >> terraform.tfvars
terraform plan -var-file=terraform.tfvars
```

## Important Notes

1. **Password visibility**: When typing passwords at Terraform prompts, the text is hidden for security. You're typing, but you can't see it. This is normal.

2. **Environment variables are better**: They avoid the interactive prompt entirely and are more secure than files.

3. **Don't commit passwords**: Never commit `terraform.tfvars` with passwords to git.

## Quick Copy-Paste Solution

**For Git Bash (your current shell)**:
```bash
# Copy and paste this entire block
export TF_VAR_db_username="admin"
export TF_VAR_db_password="DevPass123!"
terraform plan
```

That's it! The environment variables will provide the values automatically, and you won't see any prompts.

## Verification

After setting environment variables, you should see:
```
Terraform will perform the following actions:
  # (plan output showing resources to create)
```

Instead of:
```
var.db_password
  Enter a value: ← (stuck here)
```

## Summary

**Problem**: Terminal not accepting input at Terraform prompts
**Solution**: Use environment variables to bypass interactive prompts
**Command**: `export TF_VAR_db_username="admin" && export TF_VAR_db_password="DevPass123!" && terraform plan`