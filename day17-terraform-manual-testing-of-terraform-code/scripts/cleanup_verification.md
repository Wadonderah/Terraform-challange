# Day 17 — Cleanup Verification Guide
# Run these commands YOURSELF after terraform destroy.
# Read each output carefully before moving to the next step.

================================================
CATEGORY 1: PROVISIONING
================================================

Test    : Terraform initialises cleanly
Command : terraform init
Expected: "Terraform has been successfully initialized!"
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : Configuration is valid
Command : terraform validate
Expected: "Success! The configuration is valid."
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : Formatting is clean
Command : terraform fmt -check -recursive
Expected: (no output — silence means clean)
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : Run terraform fmt -recursive to auto-fix, then re-check

---

Test    : Plan shows expected resources only
Command : terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan
Expected: ~14-16 resources to add, 0 to change, 0 to destroy
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : Apply completes without errors
Command : terraform apply tfplan
Expected: "Apply complete! Resources: N added, 0 changed, 0 destroyed."
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________


================================================
CATEGORY 2: RESOURCE CORRECTNESS
================================================

Test    : VPC created with correct CIDR
Command : aws ec2 describe-vpcs \
            --filters "Name=tag:Environment,Values=dev" "Name=tag:ManagedBy,Values=terraform" \
            --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}" --output table
Expected: One VPC, CIDR 10.0.0.0/16
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : 4 subnets exist across 2 AZs (2 public, 2 private)
Command : aws ec2 describe-subnets \
            --filters "Name=tag:Environment,Values=dev" "Name=tag:ManagedBy,Values=terraform" \
            --query "Subnets[*].{CIDR:CidrBlock,AZ:AvailabilityZone,Public:MapPublicIpOnLaunch}" \
            --output table
Expected: 2 subnets Public=true, 2 subnets Public=false, spread across 2 AZs
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : Security group rules are exact — no extras, no missing rules
Command : aws ec2 describe-security-groups \
            --filters "Name=tag:Environment,Values=dev" "Name=tag:ManagedBy,Values=terraform" \
            --query "SecurityGroups[*].{Name:GroupName,Ingress:IpPermissions,Egress:IpPermissionsEgress}" \
            --output json
Expected: ALB SG — inbound port 80 from 0.0.0.0/0 only
          Instance SG — inbound port 80 from ALB SG only, outbound port 443 only
          No port 22 (SSH) anywhere
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : ALB is active and internet-facing
Command : aws elbv2 describe-load-balancers \
            --query "LoadBalancers[?contains(LoadBalancerName,'webserver-cluster-dev')].{Name:LoadBalancerName,State:State.Code,Scheme:Scheme}" \
            --output table
Expected: State=active, Scheme=internet-facing
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : ALB listener is HTTP:80 forwarding to target group
Command : aws elbv2 describe-listeners \
            --load-balancer-arn $(terraform output -raw alb_arn) \
            --query "Listeners[*].{Port:Port,Protocol:Protocol,Action:DefaultActions[0].Type}" \
            --output table
Expected: Port=80, Protocol=HTTP, Action=forward
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : Target group configured on port 80 with correct health check
Command : aws elbv2 describe-target-groups \
            --query "TargetGroups[?contains(TargetGroupName,'webserver-cluster-dev')].{Name:TargetGroupName,Port:Port,HCPath:HealthCheckPath,HCInterval:HealthCheckIntervalSeconds}" \
            --output table
Expected: Port=80, HCPath=/, HCInterval=15
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : ASG has correct min/max/desired and ELB health check
Command : aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names $(terraform output -raw asg_name) \
            --query "AutoScalingGroups[*].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,HealthCheck:HealthCheckType,Grace:HealthCheckGracePeriod}" \
            --output table
Expected: Min=2, Max=4, Desired=2, HealthCheck=ELB, Grace=120
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : EC2 instances have no public IPs (private subnets only)
Command : aws ec2 describe-instances \
            --filters "Name=tag:ManagedBy,Values=terraform" "Name=tag:Environment,Values=dev" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].{ID:InstanceId,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,AZ:Placement.AvailabilityZone}" \
            --output table
Expected: 2 instances, PublicIP column empty
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________


================================================
CATEGORY 3: FUNCTIONAL VERIFICATION
================================================
NOTE: Wait 2-3 minutes after apply before running these.

---

Test    : All targets are healthy in the target group
Command : aws elbv2 describe-target-health \
            --target-group-arn $(terraform output -raw target_group_arn) \
            --query "TargetHealthDescriptions[*].{ID:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason}" \
            --output table
Expected: Both instances State=healthy
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : If State=initial, wait 60s and re-run. If unhealthy, check user_data and port config.

---

Test    : ALB DNS resolves and returns expected response
Command : curl -s http://$(terraform output -raw alb_dns_name)
Expected: "Hello World v2"
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : Load balancing distributes traffic across both instances
Command : for i in 1 2 3 4; do curl -s http://$(terraform output -raw alb_dns_name); echo; done
Expected: "Hello World v2" returned 4 times consistently
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : ASG self-heals by replacing a terminated instance
Command : INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names $(terraform output -raw asg_name) \
            --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text) \
          && aws ec2 terminate-instances --instance-ids $INSTANCE_ID
Expected: ASG detects unhealthy instance and launches a replacement (1-3 min)
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

  Verify replacement launched:
  Command : aws autoscaling describe-scaling-activities \
              --auto-scaling-group-name $(terraform output -raw asg_name) \
              --query "Activities[0:3].{Status:StatusCode,Cause:Cause}" \
              --output table
  Expected: StatusCode=Successful, Cause contains "replacing an unhealthy instance"
  Actual  : ___________________________________________
  Result  : [ ] PASS   [ ] FAIL


================================================
CATEGORY 4: STATE CONSISTENCY
================================================

Test    : terraform plan returns clean after apply — no drift
Command : terraform plan -var-file="environments/dev/terraform.tfvars" -detailed-exitcode
Expected: "No changes. Your infrastructure matches the configuration." (exit code 0)
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : If exit code 2, identify drifted resources and re-apply

---

Test    : State list contains all expected module resources
Command : terraform state list
Expected: Entries for module.networking, module.security, module.compute resources
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________

---

Test    : State matches reality — ALB dns_name in state matches Console
Command : terraform state show module.compute.aws_lb.this
Expected: dns_name matches the value from terraform output alb_dns_name
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : ___________________________________________


================================================
CATEGORY 5: REGRESSION CHECK
================================================

Test    : A small deliberate change shows only that change in plan
Command : terraform plan \
            -var-file="environments/dev/terraform.tfvars" \
            -var="hello_world_version=v3" \
            -detailed-exitcode
Expected: Only the launch template resource shows a change — nothing else
Actual  : ___________________________________________
Result  : [ ] PASS   [ ] FAIL
Fix     : If unexpected resources change, investigate before applying


================================================
CLEAN UP
================================================

Always confirm what you are about to destroy before running destroy.

Step 1 — Preview the destroy plan:

  terraform plan -destroy -var-file="environments/dev/terraform.tfvars"

  Look for:
  [ ] Total resources to destroy matches what you applied
  [ ] No resources are being skipped or left behind
  [ ] You recognise every resource listed

  Do NOT proceed until you have read every line.

---

Step 2 — Destroy with explicit approval:

  terraform destroy -var-file="environments/dev/terraform.tfvars"

  Type "yes" only after re-reading the plan.

  If destroy fails partway through:
  - Note which resource failed
  - Check the AWS Console for that resource
  - Re-run terraform destroy — Terraform is idempotent
  - If a resource is stuck (common with NAT Gateways), manually delete it
    in the Console, then run: terraform state rm <resource-address>

---

Step 3 — Post-destroy verification:

Run each command and verify it returns EMPTY. Non-empty = orphan left behind.

Test    : No EC2 instances remain
Command : aws ec2 describe-instances \
            --filters "Name=tag:ManagedBy,Values=terraform" \
                      "Name=instance-state-name,Values=running,stopped,pending" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text
Expected: (empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Orphans found

---

Test    : No load balancers remain
Command : aws elbv2 describe-load-balancers \
            --query "LoadBalancers[?contains(LoadBalancerName,'webserver-cluster-dev')].LoadBalancerArn" \
            --output text
Expected: (empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Orphans found

---

Test    : No target groups remain
Command : aws elbv2 describe-target-groups \
            --query "TargetGroups[?contains(TargetGroupName,'webserver-cluster-dev')].TargetGroupArn" \
            --output text
Expected: (empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Orphans found

---

Test    : No security groups remain
Command : aws ec2 describe-security-groups \
            --filters "Name=tag:ManagedBy,Values=terraform" \
                      "Name=tag:Environment,Values=dev" \
            --query "SecurityGroups[*].GroupId" \
            --output text
Expected: (empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Orphans found

---

Test    : No NAT Gateways remain (wait 60s after destroy before checking)
Command : aws ec2 describe-nat-gateways \
            --filter "Name=tag:ManagedBy,Values=terraform" \
                     "Name=state,Values=available,pending" \
            --query "NatGateways[*].NatGatewayId" \
            --output text
Expected: (empty — wait 60s if not yet empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Still deleting — wait and re-check

---

Test    : No Elastic IPs remain
Command : aws ec2 describe-addresses \
            --filters "Name=tag:ManagedBy,Values=terraform" \
            --query "Addresses[*].AllocationId" \
            --output text
Expected: (empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Orphans found

---

Test    : No VPC remains
Command : aws ec2 describe-vpcs \
            --filters "Name=tag:ManagedBy,Values=terraform" \
                      "Name=tag:Environment,Values=dev" \
            --query "Vpcs[*].VpcId" \
            --output text
Expected: (empty)
Actual  : ___________________________________________
Result  : [ ] Clean   [ ] Orphans found

---

Step 4 — If you find orphans, manually delete in this order:

  1. EC2 instances first:
     aws ec2 terminate-instances --instance-ids <id>

  2. Load balancer:
     aws elbv2 delete-load-balancer --load-balancer-arn <arn>

  3. Target group:
     aws elbv2 delete-target-group --target-group-arn <arn>

  4. Security groups:
     aws ec2 delete-security-group --group-id <sg-id>

  5. NAT gateway (wait for "deleted" state before next step):
     aws ec2 delete-nat-gateway --nat-gateway-id <ngw-id>

  6. Elastic IP (only after NAT gateway is fully deleted):
     aws ec2 release-address --allocation-id <eipalloc-id>

  7. VPC last (only after everything inside it is gone):
     aws ec2 delete-vpc --vpc-id <vpc-id>

  After manually deleting, remove from Terraform state:
     terraform state rm <resource-address>
     Example: terraform state rm module.networking.aws_nat_gateway.this[0]


================================================
CLEANUP SUMMARY
================================================

Date/time destroyed   : ___________________________________________
Environment destroyed : ___________________________________________

Orphans found         : [ ] None   [ ] Yes — listed below:
  ___________________________________________
  ___________________________________________

Manual cleanup needed : [ ] No    [ ] Yes — steps taken:
  ___________________________________________
  ___________________________________________

Final state           : [ ] All clear — AWS Console shows no remaining resources
