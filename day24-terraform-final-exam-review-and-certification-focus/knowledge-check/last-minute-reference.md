# Final Knowledge Check — Last-Minute Reference
## The Most Tested Facts on the Terraform Associate Exam

---

## CLI Commands — Three Columns (Most Important Table)

| Command | State file | Real infra | AWS creds |
|---------|-----------|-----------|-----------|
| `terraform init` | Configures backend | None | No |
| `terraform validate` | None | None | No |
| `terraform fmt` | None | None | No |
| `terraform plan` | Reads + refreshes | Reads (refresh) | Yes |
| `terraform apply` | Writes | Creates/updates | Yes |
| `terraform destroy` | Writes | Destroys | Yes |
| `terraform output` | Reads | None | No |
| `terraform state list` | Reads | None | No |
| `terraform state show` | Reads | None | No |
| `terraform state mv` | Writes (moves entry) | **NOTHING** | No |
| `terraform state rm` | Writes (removes entry) | **NOTHING** | No |
| `terraform import` | Writes (adds entry) | Reads | Yes |
| `terraform workspace` | Switches state | None | No |
| `terraform graph` | None | None | No |
| `terraform login` | None (credentials) | None | No |
| `terraform providers` | None | None | No |
| `terraform refresh` | Writes (deprecated) | Reads | Yes |

---

## Plan Output Symbols

| Symbol | Meaning |
|--------|---------|
| `+` | Create |
| `-` | Destroy |
| `~` | Update in-place |
| `-/+` | Destroy and recreate (replacement) |
| `<=` | Data source read |
| `(known after apply)` | Computed attribute |

---

## Version Constraint Operators

| Constraint | Meaning |
|-----------|---------|
| `= 5.1.0` | Exactly 5.1.0 only |
| `>= 5.0` | 5.0 or higher, no upper limit |
| `<= 5.0` | 5.0 or lower |
| `~> 5.0` | >= 5.0, < 6.0 |
| `~> 5.1` | >= 5.1, < 6.0 |
| `~> 5.1.0` | >= 5.1.0, < 5.2.0 |
| `~> 5.1.2` | >= 5.1.2, < 5.2.0 |

**Rule:** `~>` allows the rightmost component and everything to its right to change.

---

## Sentinel Policy Tiers

| Tier | Can be overridden? | Effect when violated |
|------|-------------------|---------------------|
| `advisory` | N/A — never blocks | Logs violation, apply proceeds |
| `soft-mandatory` | Yes — with authorised approval | Blocks apply; override recorded in audit log |
| `hard-mandatory` | No | Blocks apply with no way to proceed |

---

## Key Terraform Facts

| Fact | Answer |
|------|--------|
| Passing score | 70% (40/57 questions) |
| Exam duration | 60 minutes |
| Number of questions | 57 |
| State file name | `terraform.tfstate` |
| Backup state file | `terraform.tfstate.backup` (local backend only) |
| Lock file name | `.terraform.lock.hcl` |
| Default workspace | `default` |
| workspace expression | `terraform.workspace` |
| Max resources per terraform import | 1 (CLI); multiple with HCL import block (1.5+) |
| terraform destroy equivalent | `terraform apply -destroy` |
| taint replacement | `terraform apply -replace=<address>` |
| taint deprecated since | Terraform 0.15.2 |
| terraform refresh deprecated | Yes — use `terraform apply -refresh-only` |

---

## The Four Most Important Exam Traps

1. **`terraform state rm`** = nothing happens to real infrastructure. EVER.
2. **`sensitive = true`** = masks terminal output only. State file still stores in plaintext.
3. **`prevent_destroy`** = defeated by removing the resource block from config.
4. **`terraform import`** = write config FIRST. Import generates no configuration.

---

## The Golden Rule (Brikman, Ch. 10)

> The main branch of the live repository should be a 1:1 representation
> of what is actually deployed in production.

---

## count vs for_each (Most Tested Basics Topic)

```
count = 5 → instances: [0], [1], [2], [3], [4]
Remove middle item → count = 4 → [3] becomes [2], [4] becomes [3]
Terraform: modifies resources at shifted positions → potential disruption

for_each = toset(["a","b","c","d","e"])
Remove "c" → only the "c" resource is destroyed
"a", "b", "d", "e" resources are completely unaffected
```

**Rule:** Use `for_each` when collection might have items removed from the middle.
Use `count` only for "create N identical resources" where removal is always from the end.
