# Systematic Renaming Plan: hello-world-app → hello-wadondera-app

## Overview
Complete codebase-wide renaming operation to replace all instances of "hello-world-app" with "hello-wadondera-app" across the entire Terraform infrastructure.

## Scope of Changes

### 1. File Content Updates (23 files)

#### Terraform Configuration Files (.tf)
1. **live/prod/services/hello-world-app/main.tf**
   - Line 1: Comment `# live/prod/services/hello-world-app/main.tf` → `# live/prod/services/hello-wadondera-app/main.tf`
   - Line 21: Backend key `prod/services/hello-world-app/terraform.tfstate` → `prod/services/hello-wadondera-app/terraform.tfstate`
   - Line 41: Module name `module "hello_world_app"` → `module "hello_wadondera_app"`
   - Line 42: Source path `../../../../modules/services/hello-world-app` → `../../../../modules/services/hello-wadondera-app`

2. **modules/services/hello-world-app/main.tf**
   - Line 1: Comment `# modules/services/hello-world-app/main.tf` → `# modules/services/hello-wadondera-app/main.tf`

3. **modules/services/hello-world-app/variables.tf**
   - Line 1: Comment `# modules/services/hello-world-app/variables.tf` → `# modules/services/hello-wadondera-app/variables.tf`
   - Line 6: Default value `"hello-world"` → `"hello-wadondera"`

4. **modules/services/hello-world-app/outputs.tf**
   - Line 1: Comment `# modules/services/hello-world-app/outputs.tf` → `# modules/services/hello-wadondera-app/outputs.tf`

5. **live/dev/services/hello-world-app/variables.tf**
   - Line 1: Comment (already updated but verify)

6. **live/dev/services/hello-world-app/outputs.tf**
   - Line 1: Comment (already updated but verify)

7. **live/stage/services/hello-world-app/variables.tf**
   - Line 1: Comment (already updated but verify)

8. **live/stage/services/hello-world-app/outputs.tf**
   - Line 1: Comment (already updated but verify)

9. **live/prod/services/hello-world-app/variables.tf**
   - Line 1: Comment

10. **live/prod/services/hello-world-app/outputs.tf**
    - Line 1: Comment

#### Test Files (.go)
11. **tests/integration/hello_world_app_test.go**
    - Line 1: Comment `// tests/integration/hello_world_app_test.go` → `// tests/integration/hello_wadondera_app_test.go`
    - Line 28: tfDir path `../../live/dev/services/hello-world-app` → `../../live/dev/services/hello-wadondera-app`

#### Shell Scripts (.sh)
12. **scripts/plan-all.sh**
    - Line 18: `"live/dev/services/hello-world-app"` → `"live/dev/services/hello-wadondera-app"`
    - Line 19: `"live/stage/services/hello-world-app"` → `"live/stage/services/hello-wadondera-app"`
    - Line 20: `"live/prod/services/hello-world-app"` → `"live/prod/services/hello-wadondera-app"`

13. **scripts/destroy-all.sh**
    - Line 30: `"live/prod/services/hello-world-app"` → `"live/prod/services/hello-wadondera-app"`
    - Line 31: `"live/stage/services/hello-world-app"` → `"live/stage/services/hello-wadondera-app"`
    - Line 32: `"live/dev/services/hello-world-app"` → `"live/dev/services/hello-wadondera-app"`

#### Documentation (.md)
14. **README.md**
    - Line 56: `cd live/dev/services/hello-world-app` → `cd live/dev/services/hello-wadondera-app`
    - Line 110: `└── hello-world-app/` → `└── hello-wadondera-app/`
    - Line 114: `└── services/hello-world-app/` → `└── services/hello-wadondera-app/`
    - Line 116: `└── services/hello-world-app/` → `└── services/hello-wadondera-app/`
    - Line 118: `└── services/hello-world-app/` → `└── services/hello-wadondera-app/`
    - Line 130: `├── hello_world_app_test.go` → `├── hello_wadondera_app_test.go`

#### Configuration Files (.tfvars)
15. **bootstrap/terraform.tfvars**
    - Line 95: Comment `# 4. Update backend configurations in live/*/services/hello-world-app/main.tf` → `# 4. Update backend configurations in live/*/services/hello-wadondera-app/main.tf`

### 2. Directory Renaming (5 operations)

**CRITICAL ORDER:** Rename directories AFTER updating file contents to avoid path resolution issues.

1. **modules/services/hello-world-app** → **modules/services/hello-wadondera-app**
   - Contains: main.tf, variables.tf, outputs.tf

2. **live/dev/services/hello-world-app** → **live/dev/services/hello-wadondera-app**
   - Contains: main.tf, variables.tf, outputs.tf

3. **live/stage/services/hello-world-app** → **live/stage/services/hello-wadondera-app**
   - Contains: main.tf, variables.tf, outputs.tf

4. **live/prod/services/hello-world-app** → **live/prod/services/hello-wadondera-app**
   - Contains: main.tf, variables.tf, outputs.tf

5. **tests/integration/hello_world_app_test.go** → **tests/integration/hello_wadondera_app_test.go**

### 3. Verification Checklist

After all changes:

✓ **Module Source Paths**
  - All `source = "../../../../modules/services/hello-wadondera-app"` resolve correctly
  - Relative paths maintain correct depth (4 levels up from live/*/services/*)

✓ **Backend State Keys**
  - Dev: `dev/services/hello-wadondera-app/terraform.tfstate`
  - Stage: `stage/services/hello-wadondera-app/terraform.tfstate`
  - Prod: `prod/services/hello-wadondera-app/terraform.tfstate`

✓ **Backend Configuration Preserved**
  - Bucket: `wadoh-terraform-state-us-east-2-123456789012`
  - DynamoDB: `wadoh-terraform-locks-us-east-2`
  - Region: `us-east-2`
  - Encryption: `true`

✓ **Module Names**
  - All environments use `module "hello_wadondera_app"`

✓ **Variable Defaults**
  - app_name default: `"hello-wadondera"`

✓ **Cross-References**
  - Test file points to correct live environment path
  - Scripts reference correct directory paths
  - Documentation reflects new structure

## Execution Strategy

### Phase 1: Content Updates (Files 1-15)
Update all file contents while directories remain unchanged. This ensures we can track changes accurately.

### Phase 2: Directory Renaming (Operations 1-5)
Rename directories in this specific order:
1. Module directory first (source of truth)
2. Live environment directories (consumers)
3. Test file (references live environments)

### Phase 3: Verification
Run comprehensive checks to ensure all references are intact and functional.

## Risk Mitigation

- **No data loss**: Only renaming, not deleting
- **Preserved configs**: All backend settings remain unchanged
- **Atomic operations**: Each file/directory renamed individually
- **Verification**: Multi-step validation after completion

## Expected Outcome

A fully consistent codebase where:
- All references use "hello-wadondera-app" or "hello_wadondera_app"
- All module paths resolve correctly
- All backend state keys align with directory structure
- All documentation is up-to-date
- Infrastructure remains deployable without modification