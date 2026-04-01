# Module: storage

Creates durable, encrypted storage: Terraform remote state bucket (versioned, KMS-encrypted,
access-logged), application config bucket, access logs bucket, and DynamoDB state lock table.

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  cluster_name        = "myapp-prod"
  state_bucket_name   = "myapp-terraform-state-prod-123456789012"
  config_bucket_name  = "myapp-config-prod-123456789012"
  dynamodb_table_name = "terraform-state-lock"
  kms_key_arn         = module.security.kms_key_arn
  common_tags         = local.common_tags
}
```

## Critical: `prevent_destroy`

Both the state bucket and the DynamoDB table have `prevent_destroy = true`.
Attempting to destroy either will cause an error:

```
Error: Instance cannot be destroyed
  The resource "aws_s3_bucket.state" has lifecycle.prevent_destroy set,
  but the plan calls for this resource to be destroyed.
```

This is intentional. To actually delete these resources you must first remove the
`lifecycle` block, apply, and then destroy — a deliberate two-step process.

## Outputs

| Name | Description |
|------|-------------|
| `state_bucket_id` | State bucket name |
| `config_bucket_id` | Config bucket name |
| `dynamodb_table_name` | Lock table name |
