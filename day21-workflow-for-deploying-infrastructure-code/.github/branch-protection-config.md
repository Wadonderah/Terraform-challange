# Branch Protection Configuration Guide

This document provides instructions for configuring branch protection rules on the `main` branch to enforce the Infrastructure Code Workflow requirements.

## Required Configuration

### Via GitHub Web UI

1. Navigate to: **Settings** → **Branches** → **Add branch protection rule**

2. **Branch name pattern:** `main`

3. **Protect matching branches - Enable the following:**

#### Pull Request Requirements
- ✅ **Require a pull request before merging**
  - Required approvals: **1**
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from Code Owners (requires CODEOWNERS file)
  - ⬜ Restrict who can dismiss pull request reviews (optional)

#### Status Checks
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - **Required status checks:**
    - `Format Check`
    - `Validate`
    - `TFLint`
    - `Security Scan (tfsec)`
    - `Terraform Plan`
    - `Terraform Tests`

#### Additional Restrictions
- ✅ **Require conversation resolution before merging**
- ✅ **Require signed commits** (recommended for compliance)
- ✅ **Require linear history** (prevents merge commits)
- ✅ **Include administrators** (enforce rules for all users)
- ✅ **Restrict who can push to matching branches**
  - Add: `infrastructure-leads` team (optional)
- ✅ **Allow force pushes:** ❌ DISABLED
- ✅ **Allow deletions:** ❌ DISABLED

### Via Terraform (terraform-github-provider)

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  required_status_checks {
    strict = true
    contexts = [
      "Format Check",
      "Validate",
      "TFLint",
      "Security Scan (tfsec)",
      "Terraform Plan",
      "Terraform Tests",
    ]
  }

  enforce_admins                  = true
  require_signed_commits          = true
  require_linear_history          = true
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false
}
```

### Via GitHub CLI

```bash
# Install GitHub CLI: https://cli.github.com/

# Enable branch protection
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews[dismiss_stale_reviews]=true \
  --field required_pull_request_reviews[require_code_owner_reviews]=true \
  --field required_pull_request_reviews[required_approving_review_count]=1 \
  --field required_status_checks[strict]=true \
  --field required_status_checks[contexts][]=Format Check \
  --field required_status_checks[contexts][]=Validate \
  --field required_status_checks[contexts][]=TFLint \
  --field required_status_checks[contexts][]=Security Scan (tfsec) \
  --field required_status_checks[contexts][]=Terraform Plan \
  --field required_status_checks[contexts][]=Terraform Tests \
  --field enforce_admins=true \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

## Verification

After configuration, verify branch protection is active:

```bash
# Check branch protection status
gh api repos/:owner/:repo/branches/main/protection

# Test by attempting direct push to main (should fail)
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "Test direct push"
git push origin main
# Expected: ERROR - protected branch hook declined
```

## Destructive Change Approval Process

For changes that destroy resources (detected in terraform plan output):

1. **First Approval:** Standard PR review by infrastructure team member
2. **Second Approval:** Required from infrastructure-leads team
3. **Confirmation:** Type "DESTROY" in safe-apply.sh script
4. **Terraform Cloud:** Manual apply approval gate (if configured)

### Implementing Secondary Approval

Add to `.github/CODEOWNERS`:

```
# Destructive changes require infrastructure-leads approval
# (Detected by reviewing terraform plan output in PR)
# Reviewer must verify plan shows resource destructions and approve accordingly
```

Add to PR template checklist:

```markdown
- [ ] If plan shows destructions: Secondary approval from @infrastructure-leads obtained
```

## Rollback Procedure

If branch protection blocks legitimate emergency changes:

1. **Preferred:** Create emergency PR with expedited review
2. **Last Resort:** Temporarily disable protection:
   ```bash
   gh api repos/:owner/:repo/branches/main/protection --method DELETE
   # Make emergency change
   # Re-enable protection immediately
   ```
3. **Document:** Create incident report explaining why protection was bypassed

## Monitoring Compliance

Track branch protection compliance:

```bash
# List all branches without protection
gh api repos/:owner/:repo/branches --jq '.[] | select(.protected == false) | .name'

# Audit recent commits to main
git log --oneline --first-parent main -20

# Check for direct commits (should be empty after protection enabled)
git log --oneline main --not --remotes=origin/main
```

## Training Resources

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Infrastructure Code Workflow Guide](./README.md)
- [Pull Request Template](./.github/PULL_REQUEST_TEMPLATE/infrastructure_change.md)

## Support

For questions or issues with branch protection:
- Slack: #infrastructure-team
- Email: infrastructure@example.com
- On-call: PagerDuty escalation policy

---

**Last Updated:** 2026-04-08  
**Owner:** Infrastructure Team  
**Review Frequency:** Quarterly