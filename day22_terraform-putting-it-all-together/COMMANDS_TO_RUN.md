# Commands to Execute: hello-world-app → hello-wadondera-app

## PowerShell Commands (Windows)

Copy and paste these commands in PowerShell to perform the complete renaming:

### Phase 1: Update File Contents

```powershell
# Update prod/main.tf
(Get-Content live/prod/services/hello-world-app/main.tf) -replace '# live/prod/services/hello-world-app/main.tf','# live/prod/services/hello-wadondera-app/main.tf' -replace 'prod/services/hello-world-app/terraform.tfstate','prod/services/hello-wadondera-app/terraform.tfstate' -replace 'module "hello_world_app"','module "hello_wadondera_app"' -replace '../../../../modules/services/hello-world-app','../../../../modules/services/hello-wadondera-app' | Set-Content live/prod/services/hello-world-app/main.tf

# Update prod/variables.tf
(Get-Content live/prod/services/hello-world-app/variables.tf) -replace '# live/prod/services/hello-world-app/','# live/prod/services/hello-wadondera-app/' | Set-Content live/prod/services/hello-world-app/variables.tf

# Update prod/outputs.tf
(Get-Content live/prod/services/hello-world-app/outputs.tf) -replace '# live/prod/services/hello-world-app/','# live/prod/services/hello-wadondera-app/' | Set-Content live/prod/services/hello-world-app/outputs.tf

# Update dev/variables.tf
(Get-Content live/dev/services/hello-world-app/variables.tf) -replace '# live/dev/services/hello-world-app/','# live/dev/services/hello-wadondera-app/' | Set-Content live/dev/services/hello-world-app/variables.tf

# Update dev/outputs.tf
(Get-Content live/dev/services/hello-world-app/outputs.tf) -replace '# live/dev/services/hello-world-app/','# live/dev/services/hello-wadondera-app/' | Set-Content live/dev/services/hello-world-app/outputs.tf

# Update stage/variables.tf
(Get-Content live/stage/services/hello-world-app/variables.tf) -replace '# live/stage/services/hello-world-app/','# live/stage/services/hello-wadondera-app/' | Set-Content live/stage/services/hello-world-app/variables.tf

# Update stage/outputs.tf
(Get-Content live/stage/services/hello-world-app/outputs.tf) -replace '# live/stage/services/hello-world-app/','# live/stage/services/hello-wadondera-app/' | Set-Content live/stage/services/hello-world-app/outputs.tf

# Update module/main.tf
(Get-Content modules/services/hello-world-app/main.tf) -replace '# modules/services/hello-world-app/','# modules/services/hello-wadondera-app/' | Set-Content modules/services/hello-world-app/main.tf

# Update module/variables.tf
(Get-Content modules/services/hello-world-app/variables.tf) -replace '# modules/services/hello-world-app/','# modules/services/hello-wadondera-app/' -replace '"hello-world"','"hello-wadondera"' | Set-Content modules/services/hello-world-app/variables.tf

# Update module/outputs.tf
(Get-Content modules/services/hello-world-app/outputs.tf) -replace '# modules/services/hello-world-app/','# modules/services/hello-wadondera-app/' | Set-Content modules/services/hello-world-app/outputs.tf

# Update test file
(Get-Content tests/integration/hello_world_app_test.go) -replace '// tests/integration/hello_world_app_test.go','// tests/integration/hello_wadondera_app_test.go' -replace '../../live/dev/services/hello-world-app','../../live/dev/services/hello-wadondera-app' | Set-Content tests/integration/hello_world_app_test.go

# Update plan-all.sh
(Get-Content scripts/plan-all.sh) -replace 'live/dev/services/hello-world-app','live/dev/services/hello-wadondera-app' -replace 'live/stage/services/hello-world-app','live/stage/services/hello-wadondera-app' -replace 'live/prod/services/hello-world-app','live/prod/services/hello-wadondera-app' | Set-Content scripts/plan-all.sh

# Update destroy-all.sh
(Get-Content scripts/destroy-all.sh) -replace 'live/dev/services/hello-world-app','live/dev/services/hello-wadondera-app' -replace 'live/stage/services/hello-world-app','live/stage/services/hello-wadondera-app' -replace 'live/prod/services/hello-world-app','live/prod/services/hello-wadondera-app' | Set-Content scripts/destroy-all.sh

# Update README.md
(Get-Content README.md) -replace 'cd live/dev/services/hello-world-app','cd live/dev/services/hello-wadondera-app' -replace 'hello-world-app/','hello-wadondera-app/' -replace 'hello_world_app_test.go','hello_wadondera_app_test.go' | Set-Content README.md

# Update bootstrap/terraform.tfvars
(Get-Content bootstrap/terraform.tfvars) -replace 'live/\*/services/hello-world-app/main.tf','live/*/services/hello-wadondera-app/main.tf' | Set-Content bootstrap/terraform.tfvars
```

### Phase 2: Rename Directories

```powershell
# Rename module directory
Move-Item -Path "modules/services/hello-world-app" -Destination "modules/services/hello-wadondera-app"

# Rename dev directory
Move-Item -Path "live/dev/services/hello-world-app" -Destination "live/dev/services/hello-wadondera-app"

# Rename stage directory
Move-Item -Path "live/stage/services/hello-world-app" -Destination "live/stage/services/hello-wadondera-app"

# Rename prod directory
Move-Item -Path "live/prod/services/hello-world-app" -Destination "live/prod/services/hello-wadondera-app"

# Rename test file
Move-Item -Path "tests/integration/hello_world_app_test.go" -Destination "tests/integration/hello_wadondera_app_test.go"
```

### Phase 3: Verification

```powershell
# Check that directories exist
Test-Path "modules/services/hello-wadondera-app"
Test-Path "live/dev/services/hello-wadondera-app"
Test-Path "live/stage/services/hello-wadondera-app"
Test-Path "live/prod/services/hello-wadondera-app"
Test-Path "tests/integration/hello_wadondera_app_test.go"

# Search for any remaining references
Get-ChildItem -Recurse -Include *.tf,*.go,*.sh,*.md | Select-String "hello-world-app" | Select-Object Path, LineNumber, Line
```

---

## Bash Commands (Linux/Mac/Git Bash)

Copy and paste these commands in Bash to perform the complete renaming:

### Phase 1: Update File Contents

```bash
# Update prod/main.tf
sed -i 's|# live/prod/services/hello-world-app/main.tf|# live/prod/services/hello-wadondera-app/main.tf|g' live/prod/services/hello-world-app/main.tf
sed -i 's|prod/services/hello-world-app/terraform.tfstate|prod/services/hello-wadondera-app/terraform.tfstate|g' live/prod/services/hello-world-app/main.tf
sed -i 's|module "hello_world_app"|module "hello_wadondera_app"|g' live/prod/services/hello-world-app/main.tf
sed -i 's|../../../../modules/services/hello-world-app|../../../../modules/services/hello-wadondera-app|g' live/prod/services/hello-world-app/main.tf

# Update prod/variables.tf and outputs.tf
sed -i 's|# live/prod/services/hello-world-app/|# live/prod/services/hello-wadondera-app/|g' live/prod/services/hello-world-app/variables.tf
sed -i 's|# live/prod/services/hello-world-app/|# live/prod/services/hello-wadondera-app/|g' live/prod/services/hello-world-app/outputs.tf

# Update dev/variables.tf and outputs.tf
sed -i 's|# live/dev/services/hello-world-app/|# live/dev/services/hello-wadondera-app/|g' live/dev/services/hello-world-app/variables.tf
sed -i 's|# live/dev/services/hello-world-app/|# live/dev/services/hello-wadondera-app/|g' live/dev/services/hello-world-app/outputs.tf

# Update stage/variables.tf and outputs.tf
sed -i 's|# live/stage/services/hello-world-app/|# live/stage/services/hello-wadondera-app/|g' live/stage/services/hello-world-app/variables.tf
sed -i 's|# live/stage/services/hello-world-app/|# live/stage/services/hello-wadondera-app/|g' live/stage/services/hello-world-app/outputs.tf

# Update module files
sed -i 's|# modules/services/hello-world-app/|# modules/services/hello-wadondera-app/|g' modules/services/hello-world-app/main.tf
sed -i 's|# modules/services/hello-world-app/|# modules/services/hello-wadondera-app/|g' modules/services/hello-world-app/variables.tf
sed -i 's|"hello-world"|"hello-wadondera"|g' modules/services/hello-world-app/variables.tf
sed -i 's|# modules/services/hello-world-app/|# modules/services/hello-wadondera-app/|g' modules/services/hello-world-app/outputs.tf

# Update test file
sed -i 's|// tests/integration/hello_world_app_test.go|// tests/integration/hello_wadondera_app_test.go|g' tests/integration/hello_world_app_test.go
sed -i 's|../../live/dev/services/hello-world-app|../../live/dev/services/hello-wadondera-app|g' tests/integration/hello_world_app_test.go

# Update scripts
sed -i 's|live/dev/services/hello-world-app|live/dev/services/hello-wadondera-app|g' scripts/plan-all.sh
sed -i 's|live/stage/services/hello-world-app|live/stage/services/hello-wadondera-app|g' scripts/plan-all.sh
sed -i 's|live/prod/services/hello-world-app|live/prod/services/hello-wadondera-app|g' scripts/plan-all.sh
sed -i 's|live/dev/services/hello-world-app|live/dev/services/hello-wadondera-app|g' scripts/destroy-all.sh
sed -i 's|live/stage/services/hello-world-app|live/stage/services/hello-wadondera-app|g' scripts/destroy-all.sh
sed -i 's|live/prod/services/hello-world-app|live/prod/services/hello-wadondera-app|g' scripts/destroy-all.sh

# Update README.md
sed -i 's|cd live/dev/services/hello-world-app|cd live/dev/services/hello-wadondera-app|g' README.md
sed -i 's|hello-world-app/|hello-wadondera-app/|g' README.md
sed -i 's|hello_world_app_test.go|hello_wadondera_app_test.go|g' README.md

# Update bootstrap/terraform.tfvars
sed -i 's|live/\*/services/hello-world-app/main.tf|live/*/services/hello-wadondera-app/main.tf|g' bootstrap/terraform.tfvars
```

### Phase 2: Rename Directories

```bash
# Rename module directory
mv modules/services/hello-world-app modules/services/hello-wadondera-app

# Rename dev directory
mv live/dev/services/hello-world-app live/dev/services/hello-wadondera-app

# Rename stage directory
mv live/stage/services/hello-world-app live/stage/services/hello-wadondera-app

# Rename prod directory
mv live/prod/services/hello-world-app live/prod/services/hello-wadondera-app

# Rename test file
mv tests/integration/hello_world_app_test.go tests/integration/hello_wadondera_app_test.go
```

### Phase 3: Verification

```bash
# Check that directories exist
ls -la modules/services/hello-wadondera-app
ls -la live/dev/services/hello-wadondera-app
ls -la live/stage/services/hello-wadondera-app
ls -la live/prod/services/hello-wadondera-app
ls -la tests/integration/hello_wadondera_app_test.go

# Search for any remaining references
grep -r "hello-world-app" --include="*.tf" --include="*.go" --include="*.sh" --include="*.md" .
```

---

## Git Commands (After Renaming)

```bash
# Stage all changes
git add -A

# Review changes
git status
git diff --cached

# Commit with descriptive message
git commit -m "Rename hello-world-app to hello-wadondera-app across entire codebase

- Updated all Terraform configuration files (.tf)
- Updated backend state keys for all environments
- Updated module names and source paths
- Renamed directories: modules, dev, stage, prod
- Updated test files and scripts
- Updated documentation (README.md, bootstrap/terraform.tfvars)
- Maintained all backend configurations (S3, DynamoDB, encryption)"

# Push to remote (if applicable)
git push origin main
```

---

## Quick One-Liner (PowerShell)

```powershell
# Execute all commands in sequence
$commands = @(
    '(Get-Content live/prod/services/hello-world-app/main.tf) -replace "# live/prod/services/hello-world-app/main.tf","# live/prod/services/hello-wadondera-app/main.tf" -replace "prod/services/hello-world-app/terraform.tfstate","prod/services/hello-wadondera-app/terraform.tfstate" -replace "module `"hello_world_app`"","module `"hello_wadondera_app`"" -replace "../../../../modules/services/hello-world-app","../../../../modules/services/hello-wadondera-app" | Set-Content live/prod/services/hello-world-app/main.tf',
    '(Get-Content live/prod/services/hello-world-app/variables.tf) -replace "# live/prod/services/hello-world-app/","# live/prod/services/hello-wadondera-app/" | Set-Content live/prod/services/hello-world-app/variables.tf',
    '(Get-Content live/prod/services/hello-world-app/outputs.tf) -replace "# live/prod/services/hello-world-app/","# live/prod/services/hello-wadondera-app/" | Set-Content live/prod/services/hello-world-app/outputs.tf',
    '(Get-Content live/dev/services/hello-world-app/variables.tf) -replace "# live/dev/services/hello-world-app/","# live/dev/services/hello-wadondera-app/" | Set-Content live/dev/services/hello-world-app/variables.tf',
    '(Get-Content live/dev/services/hello-world-app/outputs.tf) -replace "# live/dev/services/hello-world-app/","# live/dev/services/hello-wadondera-app/" | Set-Content live/dev/services/hello-world-app/outputs.tf',
    '(Get-Content live/stage/services/hello-world-app/variables.tf) -replace "# live/stage/services/hello-world-app/","# live/stage/services/hello-wadondera-app/" | Set-Content live/stage/services/hello-world-app/variables.tf',
    '(Get-Content live/stage/services/hello-world-app/outputs.tf) -replace "# live/stage/services/hello-world-app/","# live/stage/services/hello-wadondera-app/" | Set-Content live/stage/services/hello-world-app/outputs.tf',
    '(Get-Content modules/services/hello-world-app/main.tf) -replace "# modules/services/hello-world-app/","# modules/services/hello-wadondera-app/" | Set-Content modules/services/hello-world-app/main.tf',
    '(Get-Content modules/services/hello-world-app/variables.tf) -replace "# modules/services/hello-world-app/","# modules/services/hello-wadondera-app/" -replace "`"hello-world`"","`"hello-wadondera`"" | Set-Content modules/services/hello-world-app/variables.tf',
    '(Get-Content modules/services/hello-world-app/outputs.tf) -replace "# modules/services/hello-world-app/","# modules/services/hello-wadondera-app/" | Set-Content modules/services/hello-world-app/outputs.tf',
    '(Get-Content tests/integration/hello_world_app_test.go) -replace "// tests/integration/hello_world_app_test.go","// tests/integration/hello_wadondera_app_test.go" -replace "../../live/dev/services/hello-world-app","../../live/dev/services/hello-wadondera-app" | Set-Content tests/integration/hello_world_app_test.go',
    '(Get-Content scripts/plan-all.sh) -replace "live/dev/services/hello-world-app","live/dev/services/hello-wadondera-app" -replace "live/stage/services/hello-world-app","live/stage/services/hello-wadondera-app" -replace "live/prod/services/hello-world-app","live/prod/services/hello-wadondera-app" | Set-Content scripts/plan-all.sh',
    '(Get-Content scripts/destroy-all.sh) -replace "live/dev/services/hello-world-app","live/dev/services/hello-wadondera-app" -replace "live/stage/services/hello-world-app","live/stage/services/hello-wadondera-app" -replace "live/prod/services/hello-world-app","live/prod/services/hello-wadondera-app" | Set-Content scripts/destroy-all.sh',
    '(Get-Content README.md) -replace "cd live/dev/services/hello-world-app","cd live/dev/services/hello-wadondera-app" -replace "hello-world-app/","hello-wadondera-app/" -replace "hello_world_app_test.go","hello_wadondera_app_test.go" | Set-Content README.md',
    '(Get-Content bootstrap/terraform.tfvars) -replace "live/\*/services/hello-world-app/main.tf","live/*/services/hello-wadondera-app/main.tf" | Set-Content bootstrap/terraform.tfvars',
    'Move-Item -Path "modules/services/hello-world-app" -Destination "modules/services/hello-wadondera-app"',
    'Move-Item -Path "live/dev/services/hello-world-app" -Destination "live/dev/services/hello-wadondera-app"',
    'Move-Item -Path "live/stage/services/hello-world-app" -Destination "live/stage/services/hello-wadondera-app"',
    'Move-Item -Path "live/prod/services/hello-world-app" -Destination "live/prod/services/hello-wadondera-app"',
    'Move-Item -Path "tests/integration/hello_world_app_test.go" -Destination "tests/integration/hello_wadondera_app_test.go"'
)
foreach ($cmd in $commands) { Invoke-Expression $cmd; Write-Host "✓ Executed: $($cmd.Substring(0, [Math]::Min(60, $cmd.Length)))..." }
```

---

## Recommended Approach

1. **Review the plan**: Check PLAN_SUMMARY.md, RENAMING_PLAN.md, RENAMING_DIAGRAM.md
2. **Choose your shell**: PowerShell (Windows) or Bash (Linux/Mac/Git Bash)
3. **Copy Phase 1 commands**: Update all file contents
4. **Copy Phase 2 commands**: Rename directories
5. **Copy Phase 3 commands**: Verify changes
6. **Copy Git commands**: Stage, commit, and push

**Estimated time**: 2-3 minutes to execute all commands