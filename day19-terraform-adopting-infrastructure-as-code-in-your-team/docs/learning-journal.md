# Day 19 — Adopting Infrastructure as Code in Your Team
## 30-Day Terraform Challenge | Learning Journal

## A note before the documentation

I want to be upfront about something before writing this journal entry. This is not the kind of day where you sit down, write some Terraform, and feel the satisfaction of watching resources appear in AWS. This is the kind of day where you sit with uncomfortable questions about how your team actually works — not how it's supposed to work, not how it works on a good day, but how it really works when things are moving fast and the pressure is on.

That discomfort is worth paying attention to.

## Current State Assessment

### How infrastructure is currently provisioned

Honestly? A mix of everything, and that's the problem. We have bash scripts from 2021 that provision EC2 instances — nobody is quite sure if they still work, but nobody wants to find out the hard way. We have a handful of CloudFormation stacks from when someone went through an AWS certification and came back enthusiastic. And we have a large percentage of infrastructure that exists because someone clicked around in the console one afternoon and it worked, so it stayed.

There is no single source of truth. If you want to know what's actually running in this AWS account, you go to the console and look. That is the documentation. That is the source of truth. It's a problem.

**Provisioning method:** Manual console (majority) + ad-hoc bash scripts + 3 legacy CloudFormation stacks. No Terraform in production.

### Approval process for infrastructure changes

Two to three people are involved depending on the severity of the change. The process is: tell the lead engineer in Slack, get a thumbs-up emoji, make the change. For larger changes there's a quick call. None of this is written down. New engineers take weeks to figure out who actually needs to approve what.

There is no formal change management for infrastructure. There is no requirement to document what you changed or why. When an incident happens and we're trying to work backwards to find the cause, we're reading Slack logs and asking people to remember what they touched last Tuesday.

### How often infrastructure changes cause incidents

Roughly twice a month something breaks because of an infrastructure change. I tracked this informally for the last quarter. The most common causes:

- A security group rule modified that blocked traffic to something else nobody remembered
- An environment variable added to one service but forgotten in another
- A subnet or availability zone setting changed without considering downstream dependencies

These aren't catastrophic failures. They're the kind of thing that causes 45 minutes of confusion, a roll-back, and a post-mortem that everyone attends and nobody really changes their behaviour after. That pattern should concern us more than it does.

### Infrastructure drift

Significant. The internal wiki has a page titled "Infrastructure Overview" that was last updated eighteen months ago. The AWS account has evolved considerably since then. The wiki is not lying — it's just describing a version of the infrastructure that no longer exists.

The honest version of our current state is: nobody knows exactly what's deployed. We can enumerate resources in the console but we can't easily answer "why does this exist" or "is this still needed" for a large portion of them. That unknown is a security risk, a cost problem, and an operational risk all at once.

### Secrets management

This is the one that's hardest to write down. AWS access keys are shared in Slack DMs. Some exist in `.env` files in private repositories. There is no rotation policy — some of these keys have existed for years. We have been lucky rather than careful.

This is not a criticism of any individual. It's what happens when you grow fast and don't build the habits early. But it's the thing that needs to change first, ahead of everything else, because the blast radius of a leaked long-lived credential is enormous.

### Team familiarity with version control for infrastructure

Comfortable with Git for application code — everyone is. The concept of treating infrastructure the same way is understood but not practiced. When I mention infrastructure pull requests, I don't get confusion, I get a kind of "yeah, we should do that" response that hasn't yet translated into actually doing it.

One engineer on the team has used Terraform in a previous role. That's the person to build the adoption around. Not because everyone else needs to learn from scratch, but because having someone who has already hit the pitfalls saves the team from discovering them the expensive way.

### Executive appetite for change

Cautious, but present. The incident pattern has been noticed. The question from management is always some version of: "Can we do this without disrupting the current sprint?" The honest answer is yes, if we're incremental about it. The wrong answer — which I've seen others give — is to promise a full migration on a timeline that isn't realistic, then lose credibility when it runs over.

## Four-Phase Adoption Plan

Before the phases: a principle. We are not trying to have Terraform deployed everywhere by the end of the quarter. We are trying to build a habit, demonstrate value on something real, and grow the practice from there. Anyone who tells you IaC adoption is a project with a start and end date has never actually done it.

### Phase 1 — Start with something new (Weeks 1–2)

**What gets done:** Provision a new S3 bucket for CloudTrail logs entirely in Terraform. This resource does not exist yet. We are not migrating anything. We are not touching anything that's currently working. We are simply doing something new in a new way.

**Why this specific resource:** CloudTrail logging is something we've been meaning to enable properly for months. It's genuinely useful, security will appreciate it, and it touches nothing that's currently in production. If the Terraform apply fails for some reason, nothing breaks. That's exactly what you want for the first real PR.

**Who does it:** The engineer who has previous Terraform experience leads, but the PR is written collaboratively. The point of Phase 1 is not to provision a bucket. The point is to get every engineer to run `terraform plan`, read the output, and understand what it's telling them. That familiarity is the actual deliverable.

**Success criteria:**
- Terraform configuration is in version control
- Remote state is configured in S3 with DynamoDB locking
- The PR has at least one review with substantive comments (not just "LGTM")
- Every engineer on the team has run `terraform plan` locally at least once
- The bucket is in AWS and it got there without anyone touching the console

**How long:** Two weeks maximum. If it takes longer than two weeks to provision one S3 bucket via Terraform, something is wrong with the process, not the technology.

**What to watch out for:** The temptation to do more. Someone will suggest importing the existing CloudTrail configuration while we're at it. Resist this. Phase 1 is about building the workflow, not about coverage.

### Phase 2 — Import existing infrastructure (Weeks 3–5)

**What gets done:** Bring critical existing resources under Terraform state management using `terraform import`. Start with the production application security group and the ALB security group — these are the resources that have caused the most incidents and that change most frequently.

**Why these resources first:** Security group changes are the single biggest source of our infrastructure incidents. Getting them into Terraform doesn't prevent anyone from changing them, but it means changes happen via PR, which means there's a plan output showing the change, which means someone reviews it before it hits production. That alone would have prevented at least three of our incidents in the last quarter.

**Who does it:** Same lead engineer writes the resource blocks. The entire team participates in the import review. The import PR is a teaching moment — it shows everyone what the current resource looks like in code, and often reveals configuration that nobody knew existed.

**The actual import commands:**

```bash
# Import the existing security groups
terraform import aws_security_group.alb    sg-0loadbalancer1234
terraform import aws_security_group.prod_app sg-0abc123def456789

# After import — the most important command you'll run in Phase 2
terraform plan
# Expected output:
# No changes. Your infrastructure matches the configuration.
```

That "No changes" output is the goal. It means your resource block is an accurate description of reality. Any drift between the code and AWS needs to be resolved — either update the code to match reality, or make the deliberate decision to change AWS to match the code.

**Success criteria:**
- Five critical resources imported into Terraform state
- All `terraform plan` outputs show no changes post-import
- Each import done as a separate PR with its own review
- No existing resources recreated or modified during import

**What to watch out for:** The import process can be humbling. You write a resource block that you think matches the existing resource, run `terraform plan`, and discover seventeen differences you didn't know about. This is not failure — this is the audit. Document the differences and resolve them deliberately.

### Phase 3 — Establish team practices (Weeks 5–8)

**What gets done:** Multiple engineers are now writing Terraform. Without shared conventions, this quickly becomes five different styles, inconsistent module structures, and state files scattered across S3 with no naming convention. Phase 3 is about establishing the practices that prevent that chaos.

**Specific practices to implement:**
1. `terraform fmt` and `terraform validate` run on every PR via GitHub Actions — not optional, not advisory, blocking
2. `terraform plan` output posted as a PR comment — reviewers should not need to run the plan themselves to understand what's changing
3. First shared internal module created: the VPC module. It should be opinionated. It should make choices so engineers don't make different choices in different environments.
4. Written rule, communicated clearly: no manual changes to any resource that is managed by Terraform. If you make a change in the console, you own the drift, you own fixing it, and you explain it in the next team retrospective.
5. State locking verified — run concurrent `terraform apply` attempts in a test environment and confirm only one proceeds

**Who does it:** This phase requires the whole team, not just the lead. The module registry and CI configuration should be written by different engineers if possible — it builds ownership.

**Success criteria:**
- CI pipeline catches format failures on PRs
- First shared module merged and used by at least two engineers independently
- Everyone has read the "no console changes" policy and signed off on it
- State locking demonstrated and understood

**The cultural piece:** The technical practices in Phase 3 are straightforward. The hard part is the cultural norm around console changes. People will slip. When they do, the response shouldn't be punitive — it should be educational. "What was the pressure that made the console feel faster than a PR? How do we reduce that pressure?"

### Phase 4 — Automate deployments (Weeks 9–12)

**What gets done:** Infrastructure changes go through the same pipeline as application code. Merge to main triggers `terraform apply`. No one manually applies changes in production.

**The OIDC authentication setup:** Do not store AWS access keys in GitHub Secrets. This is the moment to implement OIDC. Your CI runner authenticates to AWS by presenting a signed JWT from GitHub — no long-lived credentials, no rotation policy to forget, no credential to leak. The setup takes a few hours and the security improvement is substantial.

```yaml
# GitHub Actions OIDC authentication
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform
    aws-region: af-south-1

**The deployment model:**
- Pull requests: `terraform plan` only. Output posted as PR comment.
- Merge to main: `terraform apply` against the saved plan from the PR.

**Who does it:** Platform team owns the GitHub Actions configuration. All engineers own understanding how it works — they should be able to read the workflow file and explain what happens when they open a PR.

**Success criteria:**
- First fully automated apply successfully deploys a real infrastructure change
- No one has manually run `terraform apply` against production in the previous two weeks
- OIDC authentication in place — zero stored AWS credentials in CI
- Slack notifications fire on apply success and failure

**The milestone:** When a developer opens a PR, sees the plan, gets it reviewed, merges it, and watches Slack for the apply confirmation — without ever logging into the AWS console — that's the moment. That's when you know the adoption has actually happened.

## The Business Case

I want to be honest about something: most engineering teams don't need a business case to adopt better practices. They need permission, time, and a clear path. The business case is for leadership conversations, not engineering conversations.

That said, here it is — built around real numbers from our context:

| Business problem | IaC solution | Measurable outcome |
|---|---|---|
| ~2 infrastructure incidents per month from manual console changes; each incident costs 45–90 min of engineering time across 3–4 people | All changes go through `terraform plan` → PR review → automated apply. The console becomes read-only for managed resources. | Target: zero console-caused incidents within 90 days of Phase 4. Recovery time savings: estimated 6–8 engineering hours per month. |
| New environments take 2–3 days to provision manually, blocking feature development | Reusable modules provision a complete environment (VPC, subnets, security groups, RDS, ECS cluster) in under 20 minutes | Reduce environment setup from 2–3 days to under 1 hour. This unblocks roughly one sprint cycle per quarter that is currently blocked on infra setup. |
| No audit trail for infrastructure changes — who changed what and when is a Slack archaeology exercise | Every change is a Git commit with author, timestamp, PR link, and a diff showing exactly what changed | Full, queryable audit trail. This directly addresses the evidence requirement for SOC 2 Type II. It reduces compliance review prep from an estimated 2 days to 2 hours. |
| AWS access keys shared over Slack DMs and stored in .env files | OIDC authentication from CI eliminates long-lived access keys entirely. Secrets Manager for application credentials. | Zero shared credentials. Closes the highest-severity finding from our last security review. This is arguably the most important outcome on this list. |
| Staging and production have diverged — bugs appear in production that don't reproduce in staging | Identical Terraform configurations with environment-specific variable files ensure structural parity between environments | Estimated 15–20% reduction in "production only" bug reports, based on the frequency we've attributed to environment differences in post-mortems over the last year. |
| New engineers spend 2+ weeks understanding infrastructure before contributing safely | Version-controlled configurations are the documentation. Reading the code tells you what exists and why. | Reduce infrastructure onboarding from 2 weeks to 3 days. Measured by time-to-first-infra-PR for new hires. |

## terraform import Practice

**Resource: Production application security group**

The security group `sg-0abc123def456789` was created manually in early 2022. It has nine rules. Nobody is sure who added all of them or why. That uncertainty is exactly why it needs to come under version control.

**Step 1 — Write the resource block:**

resource "aws_security_group" "prod_app" {
  name        = "acme-prod-app-sg"
  description = "Allow inbound HTTPS and app port from ALB"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "App port from load balancer only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "acme-prod-app-sg"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

**Step 2 — Import:**

```bash
terraform import aws_security_group.prod_app sg-0abc123def456789

aws_security_group.prod_app: Importing from ID "sg-0abc123def456789"...
aws_security_group.prod_app: Import prepared!
  Prepared aws_security_group for import
aws_security_group.prod_app: Refreshing state... [id=sg-0abc123def456789]

Import successful!


**Step 3 — Confirm no changes:**

```bash
$ terraform plan

aws_security_group.prod_app: Refreshing state... [id=sg-0abc123def456789]

──────────────────────────────────────────────────────────────────────

No changes. Your infrastructure matches the configuration.


That output is the milestone. It means the code is an accurate description of the real world. From this point forward, any change to this security group goes through a PR.


## Terraform Cloud Lab Takeaways

**What Terraform Cloud provides that S3 backend does not:**

A plain S3 backend gives you a place to store state and DynamoDB gives you locking. That's functional, and for a small team it's sufficient to start. But it's the minimum viable setup, not the mature one.

Terraform Cloud adds the operational layer that the S3 approach leaves to you:

**Remote execution environment.** Plans and applies run on HashiCorp's infrastructure, not your laptop or your CI runner. This matters because "it worked on my laptop" is a real problem with Terraform — different versions, different provider caches, different environment variables. Remote execution standardises all of that.

**Workspace-level access controls.** With S3 you're managing access through IAM. It works, but it's coarse-grained. Terraform Cloud lets you grant read-only state access to one team and apply access to another within the same workspace. This matters at scale.

**Sentinel — policy as code.** This is the feature that justifies Terraform Cloud at the enterprise level. Sentinel lets you write policies in code that run before every apply: no public S3 buckets, no unencrypted RDS instances, no resources in unapproved regions. These policies are enforced centrally, consistently, across every workspace and every engineer. Trying to do this with custom scripts and CI checks is a maintenance problem. Sentinel is the right tool.

**Cost estimation.** Every plan shows you what the proposed change will cost per month before you apply it. Adding an RDS Multi-AZ instance? You'll see the projected cost in the plan output. For teams that have been surprised by AWS bills, this is genuinely useful.

**Built-in variable management.** Sensitive variables — database passwords, API keys, credentials — are stored in Terraform Cloud, encrypted, workspace-scoped, and never exposed in plan output. With an S3 backend you're solving this problem yourself with something like SSM Parameter Store or Secrets Manager and a lot of custom glue code.

The honest take: for a small team (under 10 engineers, under 50 Terraform workspaces), a well-structured S3 backend is fine and the cost savings over Terraform Cloud's paid tier are real. For larger teams, or teams with compliance requirements, the operational overhead of managing what Terraform Cloud provides for free is significant.

## Chapter 10 Learnings

Brikman's central argument in this chapter — that IaC adoption fails most often because of people and process rather than technology — matches everything I've seen in practice.

The specific failure mode he identifies as most common: attempting a big-bang migration. The team decides to "move everything to Terraform" by a deadline, encounters the reality of how complex their existing infrastructure is, runs out of time and energy, and ends up in a worse state than before: some things in Terraform, some things still manual, nobody sure which is the source of truth, and a team that is now skeptical about whether IaC was worth the effort.

I agree completely, and I'd add one thing Brikman doesn't emphasise enough: **the importance of psychological safety around the first apply.**

The first time a new engineer runs `terraform apply` against infrastructure that matters, there is a real moment of anxiety. What if it breaks something? What if `plan` missed something? What if I made an error in the resource block? That anxiety is rational — Terraform can and does cause real changes. If the team culture punishes mistakes harshly, engineers will be reluctant to use automated tooling and will default to manual console changes because they feel more "controllable."

The antidote is to make Phase 1 genuinely low-stakes. Not artificially low-stakes, but actually low-stakes — a new resource that doesn't exist yet, where the worst-case outcome of a failed apply is "the resource doesn't get created." That first successful apply builds confidence. It shows the team that the plan output was accurate, that what Terraform said it would do is what it actually did. That predictability is what makes the tool trustworthy.

Trust in tooling is built the same way trust in people is built: incrementally, through demonstrated reliability, over time. You can't mandate it and you can't rush it.

## Challenges

**The hardest part in our specific context is not technical.**

The technical challenges of adopting Terraform are real but finite. State management, the import workflow, writing modules — these have documentation, community knowledge, and clear solutions. If something breaks, you can debug it.

The hard part is the cultural one: getting a team that is already moving fast, already delivering, already meeting their commitments — to slow down enough to build the habit. The pace of feature delivery creates constant pressure that makes "do it properly with a PR" feel slower than "fix it in the console." And sometimes it genuinely is slower, at least in the short term.

The other hard part is the conversation about secrets. People know, somewhere in the back of their minds, that sharing credentials in Slack is bad practice. But the alternative requires new tooling, new workflows, new habits — and there's always something more urgent to work on. The risk has been abstract for long enough that it doesn't feel urgent. Making it feel urgent, without manufacturing a crisis, is a leadership challenge more than an engineering one.

The most honest version of the challenge: **IaC adoption is asking a team to invest time now for safety and velocity later.** That's a hard sell in a culture that optimises for now.


## Blog Post Summary

**Title:** How to Convince Your Team to Adopt Infrastructure as Code

**URL:** [to be published]

The post covers:
- Why the technical argument for IaC is the wrong starting point for leadership conversations
- The incremental adoption strategy in four phases, and why big-bang migrations fail almost every time
- The cultural practices that need to accompany the technical change — particularly the "no console changes" norm and what to do when people slip
- Four common failure modes that I've either experienced directly or watched other teams hit
- An honest assessment of what makes IaC adoption hard in practice, as opposed to on paper

The central argument: IaC adoption is a discipline and a culture change that happens to involve a tool. Teams that approach it as primarily a tooling problem — "we'll install Terraform and migrate everything" — almost always fail. Teams that approach it as a practice to build incrementally, with patience and demonstrated wins, almost always succeed.

## Social Media Post

**Platform:** LinkedIn / X (Twitter)

🚀 Day 19 of the 30-Day Terraform Challenge — and today was the day that felt most real.

Not because of the code. The code is the easy part.

Today was about the hard questions: How do you get a team to trust automated deployments? How do you import infrastructure that's been running for two years without anyone knowing exactly what it does? How do you make the business case for slowing down to go faster?

After working with AWS infrastructure for years, the lesson I keep coming back to is this: the teams that succeed with IaC adoption don't start by migrating everything. They start with one small thing, do it right, let the team see it work, and grow from there. Incrementally. Patiently. With demonstrated value at every step.

The big-bang migration is a myth. It sounds ambitious. It almost never finishes.

What I built today: a four-phase adoption plan, a business case grounded in real incident numbers, and imported an existing production security group into Terraform state. The "No changes" plan output after a successful import is one of the most satisfying things in this whole workflow.

#30DayTerraformChallenge #TerraformChallenge #Terraform #IaC #DevOps #PlatformEngineering #AWSUserGroupKenya #EveOps


*Day 19 complete. Tomorrow: modules and module versioning.*
