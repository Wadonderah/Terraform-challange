# How to Convince Your Team to Adopt Infrastructure as Code

*Published as part of the 30-Day Terraform Challenge — Day 19*

I've been in the room for more IaC adoption conversations than I can count. I've seen the pitch go well and I've seen it go nowhere. The single biggest predictor of which outcome you get has nothing to do with the technology.

It's whether you start with the right problem.

## The argument that doesn't work

"We should adopt Terraform because it's the industry standard and our infrastructure isn't version-controlled."

Both of those things might be true. Neither of them is a reason a non-technical manager will care about. "Industry standard" is engineering vanity masquerading as an argument. "Not version-controlled" is a symptom description, not a business problem.

I've made this mistake. I have sat in meetings and talked about state files and HCL syntax and drift detection while a manager nodded politely and then asked how long it would take to migrate everything. I said six weeks. It took six months. The adoption was rocky, the timeline destroyed our credibility, and we spent a year rebuilding trust.

So here's the reframe that actually works.

## Start with what's breaking

Every team that has not adopted IaC has a pattern of recurring pain. It might be incidents caused by manual changes. It might be the inability to reproduce environments consistently. It might be the compliance auditor who asks for an audit trail of infrastructure changes and gets a mix of Slack messages and vibes. It might be the shared AWS credentials that have been rotating through the team since 2019.

Find that pain. Quantify it where you can. If your team has two infrastructure incidents per month and each one costs four engineers 90 minutes of investigation and remediation, that's 12 engineering-hours per month. That's a number. A number is a conversation.

The argument that works sounds like this: "We have a pattern of incidents caused by manual infrastructure changes. Code review would catch these before they reach production. Here's what that would look like, and here's what it would cost us in time to set up."

That is a problem, a solution, and a trade-off. That is a conversation you can have with a manager.

## Why the big-bang migration almost always fails

I want to be specific about this because "migrate everything to Terraform" is such a seductive plan.

It sounds ambitious. It sounds complete. It has a clear end state. It is also extremely difficult to execute and most teams that try it give up somewhere in the middle, leaving themselves in a worse position than where they started.

Here is why it fails:

Your existing infrastructure is more complex than you think it is. The security group that "just allows web traffic" has seventeen rules, half of which nobody remembers adding. The RDS instance that "runs the database" has a parameter group with custom settings that someone tuned in 2021 and which are not documented anywhere. When you try to write Terraform to match existing resources, you discover all of this complexity at once. It is demoralising.

You run out of runway. The migration was supposed to take six weeks. Four weeks in, you have 30% of infrastructure in Terraform and 70% still manual. The sprint is full, there is a feature deadline, and the migration gets deprioritised. Six months later it is still 30% complete. Nobody wants to talk about it.

Trust breaks down. When things go wrong during a migration — and they will — the instinct is to fall back to manual console changes to fix them fast. Each console change creates more drift, which makes the Terraform state less accurate, which makes the next `terraform plan` less trustworthy. The tool stops being the source of truth because it keeps showing changes that don't match expectations.

The incremental approach is not a slower version of the big-bang migration. It is a different strategy entirely.

## The strategy that actually works

**Start with something new.** Not a migration — a green-field resource that doesn't exist yet. Pick something small and genuinely useful: a new S3 bucket for CloudTrail logs, a new monitoring dashboard, a new IAM role for a new service. Provision it entirely in Terraform. Get it reviewed in a PR. Let the team run `terraform plan` and read the output.

The output of this phase is not the resource. The output is: the team has seen Terraform work on something real. They understand the workflow. They have a reference implementation they wrote themselves. The tool is no longer abstract.

This takes two weeks maximum. If it takes longer, something is wrong with the process.

**Import critical existing resources.** Once the workflow is established, start bringing high-risk existing infrastructure under Terraform management. Not all of it — the five or ten resources that cause the most incidents, that change the most frequently, that have the most undocumented configuration.

The import workflow is simple in theory and genuinely tricky in practice. You write a resource block that you believe describes the existing resource, run `terraform import`, then run `terraform plan` and expect to see "No changes." What you actually see, most of the time, is a list of differences between what you wrote and what actually exists. This is not a failure. This is the audit. This is you discovering that the security group has rules nobody knew about. This is valuable information that you would have gotten eventually, probably during an incident.

Get to "No changes." Merge the PR. Now any future change to that resource goes through code review. That is the whole point.

**Build the team practices before you need them.** Once multiple engineers are writing Terraform, you need shared conventions. Not optional conventions that some people follow — automated enforcement in CI. Format check, validate, plan output posted on PRs. A shared module library. A written, explicit norm that nobody makes manual changes to resources managed by Terraform.

The norm around console changes is the one that requires the most attention. People will slip. The pressure of an incident makes the console feel faster than a PR. When someone slips, the response should be educational, not punitive. "What made the console feel like the right call? How do we reduce that pressure?" If you respond to slippage with blame, you build a culture where people hide their console changes rather than surfacing them.

**Automate deployments last.** Not first. After the team trusts the plan output, after the practices are established, after multiple engineers have been through the review-and-apply workflow manually. Automation applied to a process you don't trust yet is not automation — it's automated chaos.

When you do automate, do it with OIDC authentication. Do not store AWS access keys in CI secrets. The setup takes half a day and eliminates an entire category of credential risk that you otherwise have to manage forever.

## The cultural shift is the actual work

Terraform is not complicated to learn. The HCL syntax is readable. The provider documentation is good. An engineer who has never seen Terraform before can write a functional S3 bucket resource in an afternoon.

The hard part is not the tool. The hard part is building a team norm that says: infrastructure changes go through code review, always, without exception, even when it feels slower. That norm has to be maintained through its first real test, which will come during an incident when someone is under pressure and the console is right there.

I have seen teams maintain the norm. They do it by making the PR workflow fast enough that it doesn't feel like a bottleneck, by running `terraform plan` in CI so reviewers can see the impact without running anything themselves, and by being the kind of team where a engineer feels safe saying "I made a console change during the incident and I need help getting it back into Terraform" rather than hiding it.

The teams that fail maintain the norm until the first incident and then abandon it. After that, every subsequent incident becomes an excuse for another console change. The drift compounds. The Terraform state stops being trusted. Eventually someone says "Terraform isn't really working for us" — but that's not what happened. What happened is the cultural practice broke down and the tool got blamed for it.

## The failure modes I've watched up close

**Migrating everything at once.** Already covered. The outcome is a half-finished migration and a team that is skeptical about whether IaC was worth the effort. The skepticism is the lasting damage.

**Underestimating the learning curve.** Not the Terraform learning curve — the operational maturity curve. Writing Terraform is quick to learn. Knowing when to use `prevent_destroy`. Understanding when a `terraform plan` output with changes is surprising versus expected. Debugging a state corruption. Knowing which parts of an import might fail and why. That knowledge takes months of working with real infrastructure to build. Teams that don't give themselves that time make mistakes that erode confidence in the tool.

**Getting the tooling right and skipping the culture.** I have seen teams with beautiful Terraform configurations, proper remote state, a shared module registry — and engineers still making console changes because they felt faster. The tooling is necessary. It's not sufficient. The culture has to be built explicitly and maintained deliberately.

**Starting without an internal champion.** Every successful IaC adoption I've seen had one engineer who genuinely cared about it. Who ran the demos. Who answered the questions at 9pm in Slack. Who reviewed the PRs quickly enough that the process didn't feel like a bottleneck. Without that person, the initiative drifts. You can't substitute external enthusiasm for internal ownership.

**Skipping secrets management.** The IaC adoption is the moment to fix credential hygiene. Not because it's required for Terraform to work — it isn't — but because you have the team's attention, you're already changing workflows, and you have a natural opportunity. OIDC for CI authentication, Secrets Manager or Parameter Store for application credentials, no long-lived keys anywhere. This should be part of Phase 1, not an afterthought.

## The thing I'd tell myself ten years ago

IaC adoption is not a project. It doesn't have a start date and an end date and a done state. It's a practice — like code review, like on-call rotations, like documentation. You build it incrementally, you maintain it actively, and it degrades if you let it.

The teams that treat it as a project fail. They run out of time, declare victory prematurely, and watch the practice erode until the next "we should really adopt Terraform properly" conversation.

The teams that treat it as a practice succeed. They start small, demonstrate value, grow deliberately, and build the habits that survive long after the original champions have moved on.

Start with one resource. Get the workflow right. Then grow from there.



*Part of the 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | Meru HashiCorp User Group | EveOps*
