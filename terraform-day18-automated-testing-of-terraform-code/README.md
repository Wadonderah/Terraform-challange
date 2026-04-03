# Day 18 — Automated Testing of Terraform Code

> **Book:** Terraform: Up & Running by Yevgeniy Brikman  
> **Chapter:** 9 (complete) — How to Test Terraform Code  
> **Today's focus:** Three-layer automated testing: unit tests, integration tests, end-to-end tests, and CI/CD


## Architecture: What Gets Tested

┌─────────────────────────────────────────────────────────────┐
│               TEST PYRAMID — Day 18                         │
│                                                             │
│              ▲  End-to-End Tests                            │
│             ▲▲▲  Full stack: VPC + Webserver                │
│            ▲▲▲▲▲  15-30 min | ~$0.50/run                   │
│           ───────  Terratest (Go)                           │
│                                                             │
│          ▲▲▲▲▲▲▲  Integration Tests                        │
│         ▲▲▲▲▲▲▲▲▲  Module alone, real AWS                  │
│        ▲▲▲▲▲▲▲▲▲▲▲  5-15 min | ~$0.10/run                 │
│       ───────────────  Terratest (Go)                       │
│                                                             │
│      ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲  Unit Tests                          │
│     ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲  Plan-only, no real AWS             │
│    ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲  Seconds | Free                    │
│   ─────────────────────────  terraform test                 │
└─────────────────────────────────────────────────────────────┘


## Project Structure

terraform-day18/
├── main.tf                                    # Root module
├── variables.tf
├── outputs.tf
│
├── modules/
│   └── services/
│       └── webserver-cluster/
│           ├── main.tf                        # Module under test
│           ├── variables.tf
│           ├── outputs.tf
│           └── webserver_cluster_unit_test.tftest.hcl  # Unit tests (10 run blocks)
│
├── test/
│   ├── go.mod                                 # Go module file
│   ├── webserver_cluster_test.go              # Integration tests (2 functions)
│   └── full_stack_e2e_test.go                 # E2E tests (3 functions)
│
├── environments/
│   ├── dev/terraform.tfvars
│   └── prod/terraform.tfvars
│
└── .github/
    └── workflows/
        └── terraform-test.yml                 # CI/CD: unit → integration → E2E


## Layer 1: Unit Tests with `terraform test`

### What they test

Unit tests run against the **plan only** — no real AWS resources are created. They verify:

- Variable values flow through to the correct resource attributes
- Naming conventions are enforced (`name_prefix = "test-cluster-"`)
- Security group ports match the configured variables
- ASG sizes are set correctly
- Required tags are present
- Invalid input values are rejected by validation blocks

### How to run

```bash
cd modules/services/webserver-cluster
terraform init -backend=false
terraform test

### Expected output

modules/services/webserver-cluster/webserver_cluster_unit_test.tftest.hcl...
  run "validate_asg_name_prefix"... pass
  run "validate_instance_type"... pass
  run "validate_instance_sg_ingress_port"... pass
  run "validate_alb_sg_ingress_port"... pass
  run "validate_asg_sizes"... pass
  run "validate_alb_managed_by_tag"... pass
  run "validate_environment_tag"... pass
  run "validate_cluster_name_too_long"... pass
  run "validate_invalid_environment_rejected"... pass
  run "validate_asg_health_check_type"... pass

Success! 10 passed, 0 failed.

### The 10 unit test run blocks explained

| Run block | What it asserts | Why it matters |
|-----------|----------------|----------------|
| `validate_asg_name_prefix` | ASG name_prefix = "test-cluster-" | Wrong name breaks CloudWatch dashboards and cost filters |
| `validate_instance_type` | Launch template instance_type = "t3.micro" | Confirms variable wiring — not hardcoded |
| `validate_instance_sg_ingress_port` | Instance SG allows port 8080 in | Wrong port = 502 errors from ALB health checks |
| `validate_alb_sg_ingress_port` | ALB SG allows port 80 in | Wrong port = all internet traffic dropped |
| `validate_asg_sizes` | min=1, max=2 | Swapped sizes cause AWS API rejection at apply |
| `validate_alb_managed_by_tag` | ALB has ManagedBy=terraform tag | Required for post-destroy cleanup verification |
| `validate_environment_tag` | ASG environment tag = "dev" | Hardcoded "dev" would mistag production |
| `validate_cluster_name_too_long` | Rejects names > 40 chars | ALB names have a 32-char AWS limit |
| `validate_invalid_environment_rejected` | Rejects environment="staging" | Only "dev" and "prod" are valid |
| `validate_asg_health_check_type` | health_check_type = "ELB" | EC2 checks miss crashed applications |

### The `expect_failures` pattern

Run blocks 8 and 9 use `expect_failures` — this is the correct way to test that validation rules work:

run "validate_cluster_name_too_long" {
  command = plan
  variables {
    cluster_name = "this-name-is-way-too-long-for-aws-resources"
  }
  # PASSES if Terraform raises a validation error for var.cluster_name
  expect_failures = [var.cluster_name]
}


The run block **passes** when Terraform raises the expected error. If the validation block were removed from variables.tf, this test would fail — alerting you that the guard is gone.


## Layer 2: Integration Tests with Terratest

### What they test

Integration tests deploy **real AWS infrastructure**, assert the ALB serves HTTP 200 with the correct body, then destroy everything. They verify:

- The user_data script runs and starts the web server
- Security group rules allow ALB → EC2 traffic
- ALB health checks pass against the running application
- The `alb_dns_name` output is non-empty and resolves
- The `hello_world_text` variable actually changes the response body

### How to run

```bash
cd test
go mod download
go test -v -run "TestWebserverClusterIntegration" -timeout 30m


### Why `defer terraform.Destroy` is critical

```go
defer terraform.Destroy(t, terraformOptions)
terraform.InitAndApply(t, terraformOptions)


`defer` in Go executes **after the surrounding function returns** — even if:
- An assertion fails (`assert.NotEmpty`)
- A panic occurs
- The test times out

Without `defer terraform.Destroy`, a failed HTTP assertion would leave the ALB, ASG, and EC2 instances running and billing. Across a team running tests daily, this becomes a significant cost and security risk. The defer pattern guarantees cleanup is the last thing that happens, every time.

### The retry pattern for ALB warm-up

```go
http_helper.HttpGetWithRetryWithCustomValidation(
    t, url, nil,
    30,             // 30 retries
    10*time.Second, // 10 seconds between retries = 5 minutes max
    func(statusCode int, body string) bool {
        return statusCode == 200 && strings.Contains(body, "Hello")
    },
)


The ALB takes 1-3 minutes to register instances and pass health checks after apply. A single `curl` immediately after apply would fail every time — not because the infrastructure is wrong, but because AWS needs time. The retry loop absorbs this wait automatically.


## Layer 3: End-to-End Tests

### What they test

E2E tests deploy the **full stack in dependency order**: networking module first, then the webserver module using the networking outputs. They verify the complete end-user traffic path:


internet → IGW → ALB (public subnet) → EC2 (private subnet via NAT)


### The LIFO destroy order

```go
defer terraform.Destroy(t, networkingOptions)   // registered first, runs LAST
terraform.InitAndApply(t, networkingOptions)

defer terraform.Destroy(t, appOptions)          // registered second, runs FIRST
terraform.InitAndApply(t, appOptions)


Go's `defer` stack is LIFO (last in, first out). The webserver module (which depends on the VPC) must be destroyed **before** the networking module. If the VPC were destroyed first, the webserver destroy would fail because the security groups and ALB still reference the VPC. The registration order guarantees the correct destroy sequence automatically.

### Integration vs E2E — the key difference

| | Integration Test | End-to-End Test |
|---|---|---|
| **Networking** | Default VPC (shortcut) | Full networking module |
| **Subnets** | Default subnets | Private subnets via NAT GW |
| **What it proves** | Module works in isolation | Modules work together |
| **Unique failures** | Wrong ports, bad user_data | Module output/input mismatch, NAT routing |
| **Time** | 5-15 minutes | 15-30 minutes |
| **Cost** | ~$0.10 | ~$0.50 |


## CI/CD Pipeline

### Job dependency graph

Every PR:
  unit-tests ✓

Push to main:
  unit-tests ✓ → integration-tests ✓ → e2e-tests ✓


### Why unit tests run on every PR

Unit tests are free and take under 60 seconds. There is no reason not to run them on every PR. They catch 80% of configuration mistakes before a reviewer even looks at the code.

### Why integration and E2E tests only run on push to main

1. **Cost**: Integration tests cost ~$0.10 each. With 10 developers pushing 5 PRs/day each, running integration tests on every PR costs ~$5/day or $1,800/year — for the same tests that run once per merge.
2. **Service limits**: AWS has limits on concurrent ALBs, security groups, and NAT Gateways per region. Running integration tests on every PR from every contributor simultaneously will hit these limits.
3. **Feedback speed**: PRs should get feedback in under 2 minutes. A 15-minute integration test makes developers wait idle.

### Why integration tests must pass before E2E runs

If the webserver module fails in isolation (integration), there is no information value in running it inside the full stack (E2E). The job dependency (`needs: integration-tests`) prevents E2E tests from consuming AWS resources when the answer is already known: the module is broken.

### Setting up AWS credentials

Never commit credentials to the workflow file. Store them as repository secrets:

GitHub repo → Settings → Secrets and variables → Actions → New repository secret

Name: AWS_ACCESS_KEY_ID
Value: <your key>

Name: AWS_SECRET_ACCESS_KEY
Value: <your secret>

The IAM user needs these permissions at minimum:
- `ec2:*`
- `elasticloadbalancing:*`
- `autoscaling:*`
- `iam:CreateServiceLinkedRole` (for ALB)


## Test Layer Comparison

| Test Type | Tool | Deploys Real Infra | Time | Cost | What It Catches |
|-----------|------|-------------------|------|------|----------------|
| Unit | `terraform test` | No (plan only) | Seconds | Free | Variable wiring, naming, port config, validation rules, tag contracts |
| Integration | Terratest | Yes (single module) | 5-15 min | ~$0.10 | user_data execution, SG rules working, ALB health checks, DNS resolution |
| End-to-End | Terratest | Yes (full stack) | 15-30 min | ~$0.50 | Module compatibility, private subnet routing, NAT GW, full traffic path |


## Chapter 9 Key Learnings

### Integration test vs end-to-end test

An **integration test** deploys a single module in isolation — typically using the default VPC to avoid setting up networking. It proves the module itself works: the web server starts, the ALB routes correctly, the security groups allow the right traffic. It cannot test module-to-module interactions.

An **end-to-end test** deploys the full dependency chain: networking first, then application, with the application's inputs sourced from the networking module's outputs. It proves the modules work together. If the networking module's `private_subnet_ids` output format changes and the webserver module's `subnet_ids` input expects a different format, an integration test would never catch this — the E2E test will.

### Why unit tests on every PR but E2E tests less frequently

The author's argument is about **cost versus coverage**. Unit tests have effectively zero cost — no AWS resources, no time, no spend. Running them on every PR is pure benefit. E2E tests have real cost in both time (15-30 minutes) and money ($0.50/run). Running E2E tests on every PR would create a 30-minute feedback delay and accumulate significant AWS spend without proportional benefit — because the bugs E2E tests catch (module compatibility, NAT routing) are far rarer than the bugs unit tests catch (wrong port, missing tag, hardcoded value).

The right strategy: **fast and free tests on every change, thorough and costly tests on every merge.**


## Common Issues and Fixes

### Go module errors

cannot find module providing package github.com/gruntwork-io/terratest
```
Fix:
```bash
cd test
go mod tidy
go get github.com/gruntwork-io/terratest/modules/terraform@latest
```

### Terratest timeout

```
--- FAIL: TestWebserverClusterIntegration (timeout)
```
Fix: Increase timeout. ALBs in some regions take longer to warm up.
```bash
go test -v -timeout 45m ./...
```
Or increase `maxRetries` in the `HttpGetWithRetryWithCustomValidation` call.

### AWS IAM permission failure in GitHub Actions

Error: UnauthorizedOperation: You are not authorized to perform this operation
```
Fix: Check the IAM policy attached to the GitHub Actions user. At minimum:
```json
{
  "Effect": "Allow",
  "Action": ["ec2:*", "elasticloadbalancing:*", "autoscaling:*"],
  "Resource": "*"
}

### `terraform test` expect_failures not triggering

If `expect_failures = [var.cluster_name]` does not trigger the validation:
- Confirm the `validation` block exists in `variables.tf`
- Confirm the test variable value actually violates the condition
- Run `terraform validate` with the bad value manually to confirm it fails

## Blog Post Summary

**Title:** Automating Terraform Testing: From Unit Tests to End-to-End Validation

The key insight from Chapter 9 is that no single test layer is sufficient. Unit tests (`terraform test`) are essential because they run in seconds, cost nothing, and catch configuration mistakes before any infrastructure is touched. But they cannot tell you whether the ALB actually routes traffic to a healthy instance — that requires deploying real infrastructure.

Integration tests (Terratest) deploy a single module against real AWS and assert HTTP responses. They catch the gap between "Terraform created the resource" and "the resource works." The `defer terraform.Destroy` pattern is the most important Go pattern in the chapter — without it, a single test failure becomes an ongoing cost and security risk.

End-to-end tests add the final verification: do the modules work together? The LIFO destroy order (register networking defer first so it runs last) is the kind of subtle correctness requirement that experienced engineers learn the hard way.

The CI/CD pipeline ties it together: unit tests on every PR (free, fast), integration and E2E tests on merge to main (real cost, maximum confidence). This is the tradeoff that lets teams move fast without breaking production.


## Estimated CI/CD Costs

| Trigger | Tests that run | AWS cost | Time |
|---------|---------------|----------|------|
| PR opened/updated | Unit tests only | $0 | ~60 sec |
| Push to main | Unit + Integration + E2E | ~$0.60 | ~45 min |
| Per month (20 merges) | All three layers | ~$12 | — |
