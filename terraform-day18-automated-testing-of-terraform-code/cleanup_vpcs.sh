#!/bin/bash

echo "=== Starting VPC Cleanup ==="

# Get all VPCs with dev environment tag
VPCS=$(aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev" --query 'Vpcs[*].VpcId' --output text)

for VPC_ID in $VPCS; do
    VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].Tags[?Key==`Name`].Value|[0]' --output text)
    echo ""
    echo "=== Cleaning VPC: $VPC_NAME ($VPC_ID) ==="
    
    # 1. Find and delete NAT Gateways
    echo "Step 1: Deleting NAT Gateways..."
    NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].NatGatewayId' --output text)
    if [ -n "$NAT_IDS" ]; then
        for NAT_ID in $NAT_IDS; do
            echo "  Deleting NAT Gateway: $NAT_ID"
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
        done
        echo "  Waiting 90 seconds for NAT Gateway to delete..."
        sleep 90
    else
        echo "  No NAT Gateways found"
    fi
    
    # 2. Release Elastic IPs (NAT Gateway EIPs)
    echo "Step 2: Releasing Elastic IPs..."
    ALLOC_IDS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[?AssociationId==`null`].AllocationId' --output text)
    if [ -n "$ALLOC_IDS" ]; then
        for ALLOC_ID in $ALLOC_IDS; do
            echo "  Releasing EIP: $ALLOC_ID"
            aws ec2 release-address --allocation-id $ALLOC_ID 2>/dev/null
        done
    else
        echo "  No Elastic IPs to release"
    fi
    
    # 3. Delete Load Balancers
    echo "Step 3: Deleting Load Balancers..."
    ALB_ARNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
    if [ -n "$ALB_ARNS" ]; then
        for ALB_ARN in $ALB_ARNS; do
            echo "  Deleting ALB: $ALB_ARN"
            aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
        done
        sleep 30
    else
        echo "  No Load Balancers found"
    fi
    
    # 4. Delete Target Groups
    echo "Step 4: Deleting Target Groups..."
    TG_ARNS=$(aws elbv2 describe-target-groups --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text)
    if [ -n "$TG_ARNS" ]; then
        for TG_ARN in $TG_ARNS; do
            echo "  Deleting Target Group: $TG_ARN"
            aws elbv2 delete-target-group --target-group-arn $TG_ARN 2>/dev/null
        done
    else
        echo "  No Target Groups found"
    fi
    
    # 5. Terminate EC2 instances
    echo "Step 5: Terminating EC2 instances..."
    INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    if [ -n "$INSTANCE_IDS" ]; then
        for INSTANCE_ID in $INSTANCE_IDS; do
            echo "  Terminating instance: $INSTANCE_ID"
            aws ec2 terminate-instances --instance-ids $INSTANCE_ID
        done
        sleep 30
    else
        echo "  No instances found"
    fi
    
    # 6. Delete Security Groups
    echo "Step 6: Deleting Security Groups..."
    SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
    if [ -n "$SG_IDS" ]; then
        for SG_ID in $SG_IDS; do
            echo "  Deleting Security Group: $SG_ID"
            # Remove all rules first
            aws ec2 revoke-security-group-ingress --group-id $SG_ID --protocol all --port all --cidr 0.0.0.0/0 2>/dev/null
            aws ec2 revoke-security-group-egress --group-id $SG_ID --protocol all --port all --cidr 0.0.0.0/0 2>/dev/null
            # Delete the security group
            aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null
        done
    else
        echo "  No non-default security groups found"
    fi
    
    # 7. Delete Subnets
    echo "Step 7: Deleting Subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    if [ -n "$SUBNET_IDS" ]; then
        for SUBNET_ID in $SUBNET_IDS; do
            echo "  Deleting subnet: $SUBNET_ID"
            aws ec2 delete-subnet --subnet-id $SUBNET_ID 2>/dev/null
        done
    else
        echo "  No subnets found"
    fi
    
    # 8. Detach and delete Internet Gateway
    echo "Step 8: Deleting Internet Gateway..."
    IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text)
    if [ -n "$IGW_IDS" ]; then
        for IGW_ID in $IGW_IDS; do
            echo "  Detaching IGW: $IGW_ID"
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 2>/dev/null
            echo "  Deleting IGW: $IGW_ID"
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID 2>/dev/null
        done
    else
        echo "  No Internet Gateway found"
    fi
    
    # 9. Delete Route Tables (non-main)
    echo "Step 9: Deleting Route Tables..."
    RT_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text)
    if [ -n "$RT_IDS" ]; then
        for RT_ID in $RT_IDS; do
            echo "  Deleting route table: $RT_ID"
            aws ec2 delete-route-table --route-table-id $RT_ID 2>/dev/null
        done
    else
        echo "  No non-main route tables found"
    fi
    
    # 10. Finally delete VPC
    echo "Step 10: Deleting VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully deleted VPC: $VPC_NAME ($VPC_ID)"
    else
        echo "✗ Failed to delete VPC: $VPC_NAME ($VPC_ID) - may still have dependencies"
    fi
    
    echo "---"
done

echo ""
echo "=== Cleanup Complete ==="
echo "Remaining VPCs with dev tag:"
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev" --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
