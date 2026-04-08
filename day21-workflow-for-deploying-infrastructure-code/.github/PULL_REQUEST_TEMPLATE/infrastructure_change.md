## What this changes

<!-- One paragraph. Explain the WHY, not just the WHAT. Link to ticket or ADR if relevant. -->

## Terraform plan output

<!-- REQUIRED: paste the full `terraform plan` output here.
     Your reviewer must be able to understand all changes from this PR alone.
     Run: terraform plan -no-color 2>&1 | pbcopy  -->

<details>
<summary>Click to expand plan output</summary>

```
PASTE PLAN OUTPUT HERE
```

</details>

## Resources affected

| Change type | Count | Resources |
|-------------|-------|-----------|
| Created     |       |           |
| Modified    |       |           |
| Destroyed   |       |           |

## Blast radius

<!--
Answer: what breaks if this apply fails halfway through?
Consider:
- Which environments does this module power?
- Are there downstream modules that read outputs from this module?
- Does this touch a shared resource (VPC, security group, IAM role, S3 bucket)?
- Will in-flight requests to the ALB/ASG be interrupted?

Example:
  "This adds a CloudWatch alarm and SNS topic. If the apply fails after creating
   the SNS topic but before creating the alarm, we end up with an orphaned SNS
   topic. No production traffic is affected. terraform apply on the next run
   will clean it up safely."
-->

## Rollback plan

<!--
How do you revert if this causes an incident?

Options (pick the one that applies):
1. `terraform apply` the previous plan file (if you saved it)
2. `git revert` the merge commit and re-run the pipeline
3. Manual AWS console action (only if Terraform state is too corrupted to use)
4. S3 state restore: `aws s3api get-object --version-id <previous-version-id> ...`

Always specify which of these you would use and why.
-->

## Pre-merge checklist

- [ ] `terraform fmt` has been run and all files are formatted
- [ ] `terraform validate` passes locally
- [ ] `terraform plan` output is pasted above and reviewed
- [ ] No unexpected resource **destructions** (if yes: second approval required)
- [ ] State bucket versioning confirmed enabled
- [ ] GitHub Actions CI is green (fmt + validate + plan + tests)
- [ ] Blast radius documented above
- [ ] Rollback plan documented above

## Post-apply verification

<!-- What will you check in AWS to confirm the change worked?
     Be specific — include console URLs or CLI commands.

Example:
  1. CloudWatch console → Alarms → confirm "webserver-cluster-cpu-high" exists and is in OK state
  2. `terraform plan` returns "No changes" after apply
  3. SNS → Topics → confirm "webserver-cluster-alerts" is present with KMS encryption
-->
