# Module: security

Creates the security foundation: KMS key with auto-rotation, security groups (ALB and web),
IAM role + instance profile for EC2 with least-privilege policies.

## Usage

```hcl
module "security" {
  source = "../../modules/security"

  cluster_name       = "myapp-prod"
  vpc_id             = module.networking.vpc_id
  server_port        = 80
  config_bucket_name = "myapp-config-prod-123456789012"
  common_tags        = local.common_tags
}
```

## Security Design

### KMS Key
- Auto-rotation enabled (annual key rotation, AWS-managed)
- 30-day deletion window (recovery period)
- Used for: S3 encryption, DynamoDB encryption, EBS volume encryption, SNS topic

### Security Groups
- **ALB SG**: Allows 80/443 from `0.0.0.0/0`. Nothing else.
- **Web SG**: Allows `server_port` from ALB SG only. No direct internet access.
- Both use `create_before_destroy` to prevent replacement downtime.

### IAM Role (Least Privilege)
The EC2 role has exactly three capabilities:
1. `AmazonSSMManagedInstanceCore` — Session Manager access (replaces SSH entirely)
2. `CloudWatchAgentServerPolicy` — Publish metrics and logs
3. Custom policy: `s3:GetObject`/`s3:ListBucket` on config bucket + `kms:Decrypt` on cluster key

No `Action: "*"`, no `Resource: "*"`.

## Outputs

| Name | Description |
|------|-------------|
| `alb_security_group_id` | Passed to compute module |
| `web_security_group_id` | Passed to compute module |
| `ec2_instance_profile_name` | Attached to launch template |
| `kms_key_arn` | Used by storage, compute, monitoring |
| `kms_key_id` | Used by monitoring (SNS encryption) |
