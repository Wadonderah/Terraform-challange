# Module: data-stores/mysql

## What it does

Deploys an RDS MySQL instance with:
- Encrypted storage (AES-256)
- Private subnet placement (not publicly accessible)
- Security group allowing MySQL only from specified security groups
- Automated backups with 7-day retention
- Multi-AZ standby in production (`multi_az = true`)
- Deletion protection in production (`deletion_protection = true`)

## Usage

```hcl
module "mysql" {
  source = "github.com/YOUR-ORG/modules//data-stores/mysql?ref=v1.0.0"

  db_name     = "prod-hello-world-db"
  environment = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.asg.instance_security_group_id]

  db_username         = var.db_username   # via TF_VAR_db_username
  db_password         = var.db_password   # via TF_VAR_db_password
  db_instance_class   = "db.t3.medium"
  multi_az            = true
  skip_final_snapshot = false
  deletion_protection = true
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `db_name` | string | — | Identifier for the RDS instance |
| `environment` | string | — | dev / stage / prod |
| `vpc_id` | string | — | VPC ID |
| `subnet_ids` | list(string) | — | Private subnet IDs for DB subnet group |
| `allowed_security_group_ids` | list(string) | `[]` | SGs allowed to connect on 3306 |
| `db_username` | string | — | Master username (sensitive) |
| `db_password` | string | — | Master password (sensitive) |
| `db_instance_class` | string | `db.t3.micro` | RDS instance class |
| `allocated_storage` | number | `20` | Storage in GB |
| `multi_az` | bool | `false` | Enable Multi-AZ standby |
| `skip_final_snapshot` | bool | `true` | Set `false` in prod |
| `deletion_protection` | bool | `false` | Set `true` in prod |

## Outputs

| Name | Description |
|------|-------------|
| `db_endpoint` | Connection endpoint (host:port) |
| `db_port` | MySQL port (3306) |
| `db_name` | Database name |
| `rds_security_group_id` | Security group ID on the RDS instance |

## Security notes

- Passwords are marked `sensitive = true` — never appear in plan or apply output
- Pass credentials via environment variables: `TF_VAR_db_username`, `TF_VAR_db_password`
- In production, rotate credentials using AWS Secrets Manager with automatic rotation
- The RDS instance is in private subnets with `publicly_accessible = false`
