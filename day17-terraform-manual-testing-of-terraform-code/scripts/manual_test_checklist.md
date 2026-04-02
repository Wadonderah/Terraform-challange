# Day 17 — Manual Testing Checklist
# Run each command yourself, observe the output, and fill in the results below.
# This is NOT a script to execute — it is a structured guide you follow manually.

================================================
CATEGORY 1: PROVISIONING VERIFICATION
================================================

Step 1: Initialize Terraform
-------------------------------
Command to run:
  terraform init

What to look for:
  - No error messages
  - Line: "Terraform has been successfully initialized!"
  - Providers downloaded to .terraform/

Record your result:
  Command run : terraform init
  Expected    : "Terraform has been successfully initialized!"
  Actual      : ___________________________________________
  Result      : [ ] PASS   [ ] FAIL
  Notes       : ___________________________________________


Step 2: Validate Configuration
-------------------------------
Command to run:
  terraform validate

What to look for:
  - No syntax or type errors
  - Line: "Success! The configuration is valid."

Record your result:
  Command run : terraform validate
  Expected    : "Success! The configuration is valid."
  Actual      : ___________________________________________
  Result      : [ ] PASS   [ ] FAIL
  Notes       : ___________________________________________


Step 3: Review the Plan
-------------------------------
Command to run:
  terraform plan -var-file="environments/dev/terraform.tfvars"

What to look for:
  - Count of resources "to add" (should be ~28)
  - Zero resources "to change" or "to destroy" on first run
  - No unexpected resource types
  - Read through each resource block — do the names, tags, and ports match your config?

Record your result:
  Command run    : terraform plan -var-file="environments/dev/terraform.tfvars"
  Resources to add    : ___
  Resources to change : ___
  Resources to destroy: ___
  Result         : [ ] PASS   [ ] FAIL
  Notes          : ___________________________________________


Step 4: Apply
-------------------------------
Command to run:
  terraform apply -var-file="environments/dev/terraform.tfvars"

  Review the plan output Terraform shows before typing "yes".
  Type: yes

What to look for:
  - "Apply complete! Resources: N added, 0 changed, 0 destroyed."
  - No error messages
  - Outputs are printed at the end (alb_dns_name, asg_name, etc.)

Record your result:
  Command run : terraform apply -var-file="environments/dev/terraform.tfvars"
  Expected    : "Apply complete!"
  Actual      : ___________________________________________
  Result      : [ ] PASS   [ ] FAIL
  Notes       : ___________________________________________


================================================
CATEGORY 2: RESOURCE CORRECTNESS (AWS CONSOLE)
================================================

After apply completes, open the AWS Console and manually verify each item below.

Step 5: Verify VPC
-------------------------------
Navigate to: VPC > Your VPCs
Check:
  [ ] VPC named "webserver-cluster-dev-vpc" exists
  [ ] CIDR is 10.0.0.0/16
  [ ] DNS hostnames: Enabled
  [ ] DNS resolution: Enabled
  [ ] Tag ManagedBy=terraform is present

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


Step 6: Verify Subnets
-------------------------------
Navigate to: VPC > Subnets
Check:
  [ ] 2 public subnets exist (10.0.1.0/24 and 10.0.2.0/24)
  [ ] 2 private subnets exist (10.0.11.0/24 and 10.0.12.0/24)
  [ ] Public subnets have "Auto-assign public IPv4" = Yes
  [ ] Private subnets have "Auto-assign public IPv4" = No
  [ ] Each subnet is in a different AZ
  [ ] All subnets tagged with ManagedBy=terraform

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


Step 7: Verify Security Groups
-------------------------------
Navigate to: EC2 > Security Groups

Check ALB security group (alb-sg):
  [ ] Inbound: TCP port 80 from 0.0.0.0/0 — and NOTHING else
  [ ] Outbound: TCP port 80 to instance-sg — and NOTHING else
  [ ] No extra rules added by accident

Check instance security group (instance-sg):
  [ ] Inbound: TCP port 80 from alb-sg — and NOTHING else
  [ ] Outbound: TCP port 443 to 0.0.0.0/0 — and NOTHING else
  [ ] No SSH rule (port 22) — instances are NOT directly accessible

Command to verify via CLI:
  aws ec2 describe-security-groups \
    --filters "Name=tag:Environment,Values=dev" \
    --query "SecurityGroups[*].{Name:GroupName,Ingress:IpPermissions,Egress:IpPermissionsEgress}"

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


Step 8: Verify ALB
-------------------------------
Navigate to: EC2 > Load Balancers
Check:
  [ ] ALB named "webserver-cluster-dev-alb" exists
  [ ] State: Active (not provisioning)
  [ ] Scheme: internet-facing
  [ ] Availability Zones: both us-east-1a and us-east-1b listed
  [ ] Security group: alb-sg attached
  [ ] Tag ManagedBy=terraform present

Navigate to: Listeners tab
  [ ] HTTP:80 listener exists
  [ ] Default action: forward to webserver-cluster-dev-tg

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


Step 9: Verify Target Group
-------------------------------
Navigate to: EC2 > Target Groups
Check:
  [ ] Target group named "webserver-cluster-dev-tg" exists
  [ ] Protocol: HTTP  Port: 80
  [ ] Health check path: /
  [ ] Health check interval: 15s  Timeout: 5s
  [ ] Healthy threshold: 2  Unhealthy threshold: 2

Navigate to: Targets tab
  [ ] At least 2 instances registered
  [ ] Status of each instance: healthy (wait 2-3 minutes after apply)

Command to verify via CLI:
  aws elbv2 describe-target-health \
    --target-group-arn $(terraform output -raw target_group_arn 2>/dev/null || echo "PASTE-ARN-HERE")

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


Step 10: Verify ASG
-------------------------------
Navigate to: EC2 > Auto Scaling Groups
Check:
  [ ] ASG named "webserver-cluster-dev-asg" exists
  [ ] Min: 2  Desired: 2  Max: 6
  [ ] Health check type: ELB
  [ ] Health check grace period: 120 seconds
  [ ] Availability Zones: both us-east-1a and us-east-1b

Navigate to: Instance management tab
  [ ] 2 instances showing as "InService"
  [ ] Both instances in healthy state

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


Step 11: Verify EC2 Instance Tags
-------------------------------
Navigate to: EC2 > Instances
  [ ] Instances tagged Name=webserver-cluster-dev-asg-instance
  [ ] Tag ManagedBy=terraform
  [ ] Tag Environment=dev
  [ ] No public IP addresses (instances are in private subnets)

Command to verify:
  aws ec2 describe-instances \
    --filters "Name=tag:ManagedBy,Values=terraform" \
              "Name=tag:Environment,Values=dev" \
    --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}"

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


================================================
CATEGORY 3: FUNCTIONAL VERIFICATION
================================================

Step 12: ALB DNS Resolves
-------------------------------
Get the DNS name first:
  terraform output alb_dns_name

Then run:
  nslookup <paste-dns-name-here>

What to look for:
  - DNS resolves to one or more IP addresses
  - No "NXDOMAIN" or "can't find" errors

Record your result:
  ALB DNS name: ___________________________________________
  Command run : nslookup <alb-dns>
  Resolved IPs: ___________________________________________
  Result      : [ ] PASS   [ ] FAIL


Step 13: curl Returns Expected Response
-------------------------------
NOTE: Wait 2-3 minutes after apply before running this.
The ALB needs time to register targets and pass health checks.

Command to run:
  curl -s http://<paste-alb-dns-here>

What to look for:
  - HTTP 200 response (not a connection refused or timeout)
  - Response body contains "Hello World v2"

Run it 3-4 times to confirm load balancing across instances:
  curl -s http://<alb-dns>
  curl -s http://<alb-dns>
  curl -s http://<alb-dns>

Record your result:
  Command run : curl -s http://<alb-dns>
  Expected    : Hello World v2
  Actual      : ___________________________________________
  Result      : [ ] PASS   [ ] FAIL
  Notes       : ___________________________________________


Step 14: Self-Healing — ASG Replaces a Terminated Instance
-------------------------------
This test verifies the ASG replaces a failed instance automatically.

1. Go to EC2 > Instances
2. Select ONE of the running instances in your ASG
3. Actions > Instance State > Terminate
4. Confirm termination

Now watch the ASG:
5. Go to EC2 > Auto Scaling Groups > webserver-cluster-dev-asg
6. Click "Activity" tab
7. Watch for a new "Launch" activity to appear (takes 1-3 minutes)
8. Go back to Instances — a new instance should appear and reach "running"

What to look for:
  - ASG Activity shows: "Launching a new EC2 instance to replace an unhealthy instance"
  - Instance count returns to 2 (desired capacity)
  - The new instance passes health checks in the target group

Record your result:
  Terminated instance ID: ___________________________________________
  Time termination noticed by ASG: ___________________________________________
  New instance ID launched: ___________________________________________
  Time new instance became InService: ___________________________________________
  Result: [ ] PASS   [ ] FAIL
  Notes : ___________________________________________


================================================
CATEGORY 4: STATE CONSISTENCY
================================================

Step 15: Plan Returns "No Changes" After Apply
-------------------------------
Run terraform plan again immediately after a fresh apply:

  terraform plan -var-file="environments/dev/terraform.tfvars"

What to look for:
  - "No changes. Your infrastructure matches the configuration."
  - If you see any changes listed, that means there is drift between
    your config and what was actually created. Document it.

Record your result:
  Command run : terraform plan -var-file="environments/dev/terraform.tfvars"
  Expected    : "No changes. Your infrastructure matches the configuration."
  Actual      : ___________________________________________
  Result      : [ ] PASS   [ ] FAIL

  If FAIL — what resources showed drift?
  ___________________________________________
  ___________________________________________


Step 16: State File Reflects Reality
-------------------------------
Check that the state file accurately lists your resources:

  terraform state list

You should see entries for:
  module.networking.aws_vpc.this
  module.networking.aws_subnet.public[0]
  module.networking.aws_subnet.public[1]
  module.networking.aws_subnet.private[0]
  module.networking.aws_subnet.private[1]
  module.networking.aws_nat_gateway.this[0]
  module.networking.aws_nat_gateway.this[1]
  module.security.aws_security_group.alb
  module.security.aws_security_group.instance
  module.compute.aws_lb.this
  module.compute.aws_lb_target_group.this
  module.compute.aws_lb_listener.http
  module.compute.aws_autoscaling_group.this
  module.compute.aws_launch_template.this
  (and more...)

Pick one resource and inspect it:
  terraform state show module.compute.aws_lb.this

What to look for:
  - The dns_name matches what you see in the Console
  - The security_groups list matches what you attached
  - No phantom resources (resources in state that no longer exist in AWS)

Result: [ ] PASS   [ ] FAIL
Notes : ___________________________________________


================================================
CATEGORY 5: REGRESSION CHECK
================================================

Step 17: A Small Change Shows Only That Change in Plan
-------------------------------
Make a deliberate small change to your configuration.

Option A — Edit variables.tf or terraform.tfvars:
  Change the hello_world_version from "v2" to "v3"
  (This will trigger a Launch Template update and ASG refresh)

Option B — Add a tag to the dev tfvars:
  Open environments/dev/terraform.tfvars
  Add a line:  TestTag = "regression-check"
  (inside the tags map)

Then run:
  terraform plan -var-file="environments/dev/terraform.tfvars"

What to look for:
  - Plan shows ONLY the change you made
  - No unexpected resource replacements
  - No unrelated resources showing changes

Record your result:
  Change made     : ___________________________________________
  Resources changed in plan: ___________________________________________
  Any unexpected changes   : ___________________________________________
  Result: [ ] PASS   [ ] FAIL

Now apply it:
  terraform apply -var-file="environments/dev/terraform.tfvars"

Then plan again to confirm clean state:
  terraform plan -var-file="environments/dev/terraform.tfvars"

  Expected: "No changes."
  Actual  : ___________________________________________
  Result  : [ ] PASS   [ ] FAIL


================================================
SUMMARY TABLE — fill in after completing all steps
================================================

| # | Test                                  | Result        |
|---|---------------------------------------|---------------|
| 1 | terraform init                        | PASS / FAIL   |
| 2 | terraform validate                    | PASS / FAIL   |
| 3 | terraform plan (expected resources)   | PASS / FAIL   |
| 4 | terraform apply (no errors)           | PASS / FAIL   |
| 5 | VPC visible and correct in Console    | PASS / FAIL   |
| 6 | Subnets correct (public/private/AZ)   | PASS / FAIL   |
| 7 | Security group rules exact            | PASS / FAIL   |
| 8 | ALB active and internet-facing        | PASS / FAIL   |
| 9 | Target group healthy                  | PASS / FAIL   |
|10 | ASG min/desired/max correct           | PASS / FAIL   |
|11 | EC2 instance tags correct             | PASS / FAIL   |
|12 | ALB DNS resolves                      | PASS / FAIL   |
|13 | curl returns "Hello World v2"         | PASS / FAIL   |
|14 | ASG self-heals after termination      | PASS / FAIL   |
|15 | Plan clean after apply (no drift)     | PASS / FAIL   |
|16 | State file reflects reality           | PASS / FAIL   |
|17 | Regression: only expected change      | PASS / FAIL   |

Total PASS: ___ / 17
Total FAIL: ___ / 17

================================================
FAILURES LOG — document every failure here
================================================

Failure #1:
  Test     : ___________________________________________
  Command  : ___________________________________________
  Expected : ___________________________________________
  Actual   : ___________________________________________
  Root cause: ___________________________________________
  Fix applied: ___________________________________________
  Re-test result: [ ] PASS   [ ] FAIL

Failure #2:
  Test     : ___________________________________________
  Command  : ___________________________________________
  Expected : ___________________________________________
  Actual   : ___________________________________________
  Root cause: ___________________________________________
  Fix applied: ___________________________________________
  Re-test result: [ ] PASS   [ ] FAIL

(Add more blocks as needed)

================================================
ENVIRONMENT COMPARISON (dev vs prod)
================================================

After completing all tests against dev, repeat steps 1-17 against prod:
  terraform apply -var-file="environments/prod/terraform.tfvars"

Document any differences in behaviour between environments:

  Instance type difference (t3.micro vs t3.small):
  ___________________________________________

  CIDR difference (10.0.x vs 10.1.x) — any conflicts?
  ___________________________________________

  ASG max difference (4 vs 6) — any behaviour difference?
  ___________________________________________

  Any test that passed in dev but failed in prod?
  ___________________________________________

