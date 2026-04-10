# Implementation Checklist: hello-world-app → hello-wadondera-app

## Pre-Execution Verification
- [ ] Backup current state (optional but recommended)
- [ ] Confirm no active Terraform operations
- [ ] Review RENAMING_PLAN.md for complete scope
- [ ] Review RENAMING_DIAGRAM.md for visual understanding

---

## Phase 1: Terraform Configuration Files (10 files)

### Production Environment
- [ ] **live/prod/services/hello-world-app/main.tf**
  - [ ] Line 1: Update comment header
  - [ ] Line 21: Update backend state key
  - [ ] Line 41: Update module name `hello_world_app` → `hello_wadondera_app`
  - [ ] Line 42: Update source path to `hello-wadondera-app`

- [ ] **live/prod/services/hello-world-app/variables.tf**
  - [ ] Line 1: Update comment header

- [ ] **live/prod/services/hello-world-app/outputs.tf**
  - [ ] Line 1: Update comment header

### Module Files
- [ ] **modules/services/hello-world-app/main.tf**
  - [ ] Line 1: Update comment header

- [ ] **modules/services/hello-world-app/variables.tf**
  - [ ] Line 1: Update comment header
  - [ ] Line 6: Update app_name default `"hello-world"` → `"hello-wadondera"`

- [ ] **modules/services/hello-world-app/outputs.tf**
  - [ ] Line 1: Update comment header

### Dev Environment (Verify/Update)
- [ ] **live/dev/services/hello-world-app/variables.tf**
  - [ ] Line 1: Verify comment header is correct

- [ ] **live/dev/services/hello-world-app/outputs.tf**
  - [ ] Line 1: Verify comment header is correct

### Stage Environment (Verify/Update)
- [ ] **live/stage/services/hello-world-app/variables.tf**
  - [ ] Line 1: Verify comment header is correct

- [ ] **live/stage/services/hello-world-app/outputs.tf**
  - [ ] Line 1: Verify comment header is correct

---

## Phase 2: Test Files (1 file)

- [ ] **tests/integration/hello_world_app_test.go**
  - [ ] Line 1: Update comment header
  - [ ] Line 28: Update tfDir path to `hello-wadondera-app`

---

## Phase 3: Shell Scripts (2 files)

- [ ] **scripts/plan-all.sh**
  - [ ] Line 18: Update dev path
  - [ ] Line 19: Update stage path
  - [ ] Line 20: Update prod path

- [ ] **scripts/destroy-all.sh**
  - [ ] Line 30: Update prod path
  - [ ] Line 31: Update stage path
  - [ ] Line 32: Update dev path

---

## Phase 4: Documentation (2 files)

- [ ] **README.md**
  - [ ] Line 56: Update cd command path
  - [ ] Line 110: Update module directory reference
  - [ ] Line 114: Update dev directory reference
  - [ ] Line 116: Update stage directory reference
  - [ ] Line 118: Update prod directory reference
  - [ ] Line 130: Update test file name reference

- [ ] **bootstrap/terraform.tfvars**
  - [ ] Line 95: Update comment reference

---

## Phase 5: Directory Renaming (5 operations)

**CRITICAL**: Execute in this exact order to maintain reference integrity

### Step 1: Rename Module Directory
- [ ] **modules/services/hello-world-app** → **modules/services/hello-wadondera-app**
  - Command: `git mv modules/services/hello-world-app modules/services/hello-wadondera-app`
  - Verify: Module files exist in new location

### Step 2: Rename Dev Environment
- [ ] **live/dev/services/hello-world-app** → **live/dev/services/hello-wadondera-app**
  - Command: `git mv live/dev/services/hello-world-app live/dev/services/hello-wadondera-app`
  - Verify: Environment files exist in new location

### Step 3: Rename Stage Environment
- [ ] **live/stage/services/hello-world-app** → **live/stage/services/hello-wadondera-app**
  - Command: `git mv live/stage/services/hello-world-app live/stage/services/hello-wadondera-app`
  - Verify: Environment files exist in new location

### Step 4: Rename Prod Environment
- [ ] **live/prod/services/hello-world-app** → **live/prod/services/hello-wadondera-app**
  - Command: `git mv live/prod/services/hello-world-app live/prod/services/hello-wadondera-app`
  - Verify: Environment files exist in new location

### Step 5: Rename Test File
- [ ] **tests/integration/hello_world_app_test.go** → **tests/integration/hello_wadondera_app_test.go**
  - Command: `git mv tests/integration/hello_world_app_test.go tests/integration/hello_wadondera_app_test.go`
  - Verify: Test file exists in new location

---

## Phase 6: Verification & Validation

### Module Source Path Validation
- [ ] Dev environment module source resolves: `../../../../modules/services/hello-wadondera-app`
- [ ] Stage environment module source resolves: `../../../../modules/services/hello-wadondera-app`
- [ ] Prod environment module source resolves: `../../../../modules/services/hello-wadondera-app`

### Backend State Key Validation
- [ ] Dev backend key: `dev/services/hello-wadondera-app/terraform.tfstate`
- [ ] Stage backend key: `stage/services/hello-wadondera-app/terraform.tfstate`
- [ ] Prod backend key: `prod/services/hello-wadondera-app/terraform.tfstate`

### Backend Configuration Preservation
- [ ] S3 bucket name unchanged: `wadoh-terraform-state-us-east-2-123456789012`
- [ ] DynamoDB table unchanged: `wadoh-terraform-locks-us-east-2`
- [ ] Region unchanged: `us-east-2`
- [ ] Encryption enabled: `true`

### Module Name Validation
- [ ] Dev uses: `module "hello_wadondera_app"`
- [ ] Stage uses: `module "hello_wadondera_app"`
- [ ] Prod uses: `module "hello_wadondera_app"`

### Variable Default Validation
- [ ] Module app_name default: `"hello-wadondera"`

### Cross-Reference Validation
- [ ] Test file points to: `../../live/dev/services/hello-wadondera-app`
- [ ] plan-all.sh references all three new paths
- [ ] destroy-all.sh references all three new paths
- [ ] README.md reflects new structure
- [ ] bootstrap/terraform.tfvars comment updated

### File Existence Check
- [ ] All 10 Terraform config files exist in new locations
- [ ] All 3 module files exist in new location
- [ ] Test file exists with new name
- [ ] Scripts contain updated paths
- [ ] Documentation reflects changes

### Syntax Validation (Optional but Recommended)
- [ ] Run `terraform fmt -recursive` to verify HCL syntax
- [ ] Run `terraform validate` in each environment (requires init)
- [ ] Check for any broken symlinks or references

---

## Post-Execution Tasks

### Git Operations
- [ ] Review all changes: `git status`
- [ ] Stage changes: `git add -A`
- [ ] Commit with descriptive message
- [ ] Push to remote (if applicable)

### Documentation
- [ ] Update CHANGELOG.md (if exists)
- [ ] Update any additional project documentation
- [ ] Notify team members of the change

### Testing (Recommended)
- [ ] Run `terraform init` in dev environment
- [ ] Run `terraform plan` in dev environment
- [ ] Verify no unexpected changes
- [ ] Consider running integration tests

---

## Rollback Plan (If Needed)

If issues arise, reverse the operations:

1. Revert file content changes using git
2. Rename directories back to original names
3. Restore from backup if necessary

Commands:
```bash
git reset --hard HEAD~1  # If committed
git checkout .           # If not committed
```

---

## Success Criteria

✅ All 23 checklist items completed
✅ Zero broken references or paths
✅ All module sources resolve correctly
✅ Backend configurations intact
✅ Infrastructure remains deployable
✅ Documentation up-to-date
✅ Git history clean and descriptive

---

## Notes

- **Estimated Time**: 15-20 minutes for careful execution
- **Risk Level**: Medium (state keys and module paths are critical)
- **Reversibility**: High (git-tracked changes, easy to revert)
- **Testing Required**: Yes (at minimum, terraform init and plan)

---

## Contact & Support

If issues arise during implementation:
1. Review RENAMING_PLAN.md for detailed context
2. Check RENAMING_DIAGRAM.md for visual reference
3. Verify each step was completed in order
4. Use git to review changes: `git diff`