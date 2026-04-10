# Troubleshooting: Module Directory Not Found

## The Problem

You're seeing this error:
```
Error: Unreadable module directory
Unable to evaluate directory symlink: GetFileAttributesEx ..\..\..\..\modules\services\hello-wadondera-app: The system cannot find the file specified.
```

## Root Cause

The file contents have been updated to reference `hello-wadondera-app`, but the actual directory is still named `hello-world-app`. This creates a mismatch:

- **What the code says**: `source = "../../../../modules/services/hello-wadondera-app"`
- **What actually exists**: `modules/services/hello-world-app/`

## Solution

You need to complete **Phase 2: Rename Directories**. The commands must be executed in this specific order:

### Step 1: Rename the Module Directory FIRST

```bash
# This is the most critical step - rename the source module first
mv modules/services/hello-world-app modules/services/hello-wadondera-app
```

### Step 2: Rename the Environment Directories

```bash
# Rename dev environment
mv live/dev/services/hello-world-app live/dev/services/hello-wadondera-app

# Rename stage environment
mv live/stage/services/hello-world-app live/stage/services/hello-wadondera-app

# Rename prod environment
mv live/prod/services/hello-world-app live/prod/services/hello-wadondera-app
```

### Step 3: Rename the Test File

```bash
# Rename test file
mv tests/integration/hello_world_app_test.go tests/integration/hello_wadondera_app_test.go
```

### Step 4: Navigate to the NEW Directory Path

```bash
# IMPORTANT: The directory has been renamed, so update your path
cd ~/Startups/Terraform-challange/day22_terraform-putting-it-all-together/live/dev/services/hello-wadondera-app
```

### Step 5: Re-initialize Terraform

```bash
# Now that the module directory exists at the correct path, initialize
terraform init -reconfigure

# Then you can plan and apply
terraform plan -out=ci.tfplan
terraform apply ci.tfplan
```

## Quick Fix Commands (Copy & Paste)

```bash
# Navigate to project root
cd ~/Startups/Terraform-challange/day22_terraform-putting-it-all-together

# Rename all directories
mv modules/services/hello-world-app modules/services/hello-wadondera-app
mv live/dev/services/hello-world-app live/dev/services/hello-wadondera-app
mv live/stage/services/hello-world-app live/stage/services/hello-wadondera-app
mv live/prod/services/hello-world-app live/prod/services/hello-wadondera-app
mv tests/integration/hello_world_app_test.go tests/integration/hello_wadondera_app_test.go

# Navigate to the NEW dev environment directory
cd live/dev/services/hello-wadondera-app

# Re-initialize and apply
terraform init -reconfigure
terraform plan -out=ci.tfplan
terraform apply ci.tfplan
```

## Verification

After renaming, verify the directories exist:

```bash
# Check module directory
ls -la modules/services/hello-wadondera-app

# Check environment directories
ls -la live/dev/services/hello-wadondera-app
ls -la live/stage/services/hello-wadondera-app
ls -la live/prod/services/hello-wadondera-app

# Check test file
ls -la tests/integration/hello_wadondera_app_test.go
```

## Why This Happened

The renaming process has two phases:
1. **Phase 1**: Update file contents (references to the directories)
2. **Phase 2**: Rename the actual directories

You completed Phase 1 but not Phase 2. Both phases must be completed for the system to work correctly.

## Prevention

Always execute the commands in the order specified in [`COMMANDS_TO_RUN.md`](COMMANDS_TO_RUN.md):
1. Phase 1: Update file contents
2. Phase 2: Rename directories ← **You are here**
3. Phase 3: Verify changes

## Current Status

✅ Phase 1 Complete: File contents updated
❌ Phase 2 Incomplete: Directories not renamed
❌ Phase 3 Pending: Verification not done

## Next Steps

1. Run the "Quick Fix Commands" above
2. Verify all directories exist with new names
3. Re-run `terraform init -reconfigure` in the new directory path
4. Continue with your Terraform workflow