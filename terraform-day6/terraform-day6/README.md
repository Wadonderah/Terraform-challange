# Day 6 — Terraform Remote State with S3 + DynamoDB

## Folder Structure

```
terraform-day6/
├── backend-bootstrap/
│   ├── main.tf        ← Creates S3 bucket + DynamoDB table
│   └── outputs.tf     ← Prints bucket name and table name
├── main-project/
│   ├── main.tf        ← Backend config + example resource
│   └── outputs.tf     ← Example resource outputs
├── iam-policy.json    ← Minimum IAM permissions needed
├── .gitignore         ← Blocks state files from Git
└── README.md
```

---

## Step-by-Step Deployment

### Before you start — replace placeholders

Search for `YOUR-ACCOUNT-ID` in all files and replace with your actual AWS account ID.
You can find it by running:
```bash
aws sts get-caller-identity --query Account --output text
```

Your bucket names will be:
- State bucket: `wadondera-terraform-state-YOUR-ACCOUNT-ID`
- Example bucket: `wadondera-example-bucket-YOUR-ACCOUNT-ID`

---

### Step 1 — Bootstrap the backend infrastructure

```bash
cd backend-bootstrap/
terraform init
terraform plan
terraform apply
```

This creates:
- S3 bucket (versioned + encrypted + private)
- DynamoDB table for locking

State for this step is stored **locally**. That is intentional and correct.

---

### Step 2 — Migrate to remote state

```bash
cd ../main-project/
terraform init        # Terraform detects the backend block and prompts to migrate
# Type: yes
```

Expected output:
```
Initializing the backend...
Do you want to copy existing state to the new backend?
Enter a value: yes

Successfully configured the backend "s3"!
```

---

### Step 3 — Deploy example infrastructure

```bash
terraform plan
terraform apply
```

After apply, verify in the AWS Console:
- S3 bucket → Objects → `global/s3/terraform.tfstate` should exist
- Check the Versions tab — you should see at least one version

---

### Step 4 — Inspect the state

```bash
# List all tracked resources
terraform state list

# Inspect a specific resource
terraform state show aws_s3_bucket.example

# View raw state file (optional)
cat terraform.tfstate     # Only exists locally if you haven't migrated yet
```

---

### Step 5 — Test state locking

Open two terminals in the `main-project/` directory:

**Terminal 1:**
```bash
terraform apply
```

**Terminal 2** (while Terminal 1 is running):
```bash
terraform plan
```

Terminal 2 should show:
```
Error: Error acquiring the state lock
  Lock Info:
    ID:        <uuid>
    Operation: OperationTypeApply
    Who:       user@hostname
```

---

### Step 6 — Clean up (optional)

```bash
# Destroy example resources
terraform destroy

# To destroy the backend bootstrap resources, you must first
# remove prevent_destroy from backend-bootstrap/main.tf, then:
cd ../backend-bootstrap/
terraform destroy
```

---

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `BucketAlreadyExists` | S3 names are globally unique | Add your account ID to the bucket name |
| `AccessDeniedException` on DynamoDB | Missing IAM permissions | Attach `iam-policy.json` to your IAM user/role |
| `Variables not allowed` in backend block | Backend block doesn't support `var.*` | Use `-backend-config=file.hcl` for dynamic values |
| State migration prompt not shown | Backend already initialized | Delete `.terraform/` folder and run `terraform init` again |
