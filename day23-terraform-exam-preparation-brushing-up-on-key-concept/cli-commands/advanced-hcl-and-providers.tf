# Provider Aliases + Advanced HCL Patterns
## Exam Reference File


## Provider Aliases — Multi-Region Deployments

# Default provider — no alias required for resources that use it
provider "aws" {
  region = "us-east-2"
}

# Aliased provider — referenced explicitly in resources
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

# Resource using the default provider — no provider argument needed
resource "aws_s3_bucket" "primary" {
  bucket = "my-primary-bucket"
}

# Resource using an aliased provider — provider argument is required
resource "aws_s3_bucket" "west_backup" {
  provider = aws.west   # dot notation: <type>.<alias>
  bucket   = "my-west-backup-bucket"
}

# Module using an aliased provider — pass it as a module argument
module "west_vpc" {
  source = "./modules/networking/vpc"
  providers = {
    aws = aws.west   # map of provider type to aliased instance
  }
}

**Exam trap:** Resources that don't specify a `provider` argument use the default
(un-aliased) provider. Resources that need to use an aliased provider MUST specify it.

---

## Variable Types — Complete Reference
# Simple types
variable "name"        { type = string  }
variable "count"       { type = number  }
variable "enabled"     { type = bool    }

# Collection types
variable "cidr_blocks" { type = list(string)   }
variable "port_map"    { type = map(number)     }
variable "unique_ids"  { type = set(string)     }

# Structural types
variable "instance_config" {
  type = object({
    instance_type = string
    ami           = string
    count         = number
    tags          = map(string)
  })
}

variable "subnets" {
  type = list(object({
    cidr = string
    az   = string
    public = bool
  }))
}

# Tuple — fixed-length, mixed types (less common)
variable "settings" {
  type = tuple([string, number, bool])
}

# Any type — use sparingly
variable "anything" { type = any }
```

---

## for Expressions — Complete Examples

```hcl
# List comprehension — transform each element
locals {
  upper_names = [for name in var.names : upper(name)]
  # ["ALICE", "BOB", "CAROL"]

  # With conditional filter
  long_names = [for name in var.names : name if length(name) > 4]
  # ["carol"] (if names = ["ali", "bob", "carol"])
}

# Map comprehension — transform key-value pairs
locals {
  instance_ids = { for k, v in aws_instance.web : k => v.id }
  # { "web-0" = "i-abc123", "web-1" = "i-def456" }

  # Flip keys and values
  id_to_name = { for k, v in var.name_map : v => k }
}

# for with for_each resources
resource "aws_iam_user" "team" {
  for_each = toset(var.usernames)
  name     = each.key
}

# Referencing for_each resources
output "user_arns" {
  value = { for k, v in aws_iam_user.team : k => v.arn }
}
```

---

## Dynamic Blocks — Security Group Example

```hcl
variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    { port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP"  },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" },
    { port = 8080, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"], description = "App"  },
  ]
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## Built-in Functions Quick Reference

```hcl
# String functions
format("Hello, %s!", "world")        # "Hello, world!"
lower("HELLO")                        # "hello"
upper("hello")                        # "HELLO"
trimspace("  hello  ")               # "hello"
split(",", "a,b,c")                  # ["a", "b", "c"]
join("-", ["a", "b", "c"])           # "a-b-c"
replace("hello world", " ", "_")     # "hello_world"
substr("hello", 0, 3)                # "hel"
length("hello")                       # 5
startswith("hello", "he")            # true
endswith("hello", "lo")              # true

# Collection functions
length([1, 2, 3])                    # 3
concat([1, 2], [3, 4])               # [1, 2, 3, 4]
flatten([[1, 2], [3, [4]]])          # [1, 2, 3, 4]
distinct([1, 2, 2, 3])               # [1, 2, 3]
toset([1, 2, 2, 3])                  # {1, 2, 3}
tolist({a=1, b=2})                   # error — tolist works on sets/tuples
sort(["b", "a", "c"])                # ["a", "b", "c"]
reverse([1, 2, 3])                   # [3, 2, 1]
contains([1, 2, 3], 2)               # true
index([1, 2, 3], 2)                  # 1 (zero-based)
keys({a=1, b=2})                     # ["a", "b"]
values({a=1, b=2})                   # [1, 2]
lookup({a=1, b=2}, "a", 0)           # 1 (with default)
merge({a=1}, {b=2})                  # {a=1, b=2}
zipmap(["a","b"], [1, 2])            # {a=1, b=2}

# Numeric functions
max(1, 5, 3)                         # 5
min(1, 5, 3)                         # 1
abs(-5)                              # 5
ceil(1.2)                            # 2
floor(1.9)                           # 1

# IP functions
cidrsubnet("10.0.0.0/16", 8, 1)     # "10.0.1.0/24"
cidrhost("10.0.1.0/24", 5)          # "10.0.1.5"
cidrnetmask("10.0.0.0/16")          # "255.255.0.0"

# Encoding functions
base64encode("hello")                # "aGVsbG8="
base64decode("aGVsbG8=")            # "hello"
jsonencode({a = 1})                  # "{\"a\":1}"
jsondecode("{\"a\":1}")              # {a = 1}
yamldecode("a: 1\nb: 2")            # {a = "1", b = "2"}

# Filesystem functions (in modules)
file("${path.module}/script.sh")     # read file contents as string
templatefile("${path.module}/tmpl.tpl", { var = value })
filebase64("${path.module}/cert.pem") # file contents as base64
```
