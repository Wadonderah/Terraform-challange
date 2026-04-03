// test/full_stack_e2e_test.go
//
// Day 18: End-to-End Tests with Terratest
//
// WHAT E2E TESTS DO — AND WHY THEY ARE DIFFERENT
// ------------------------------------------------
// Integration tests verify a single module in isolation (the
// webserver module against the default VPC). End-to-end tests
// deploy the COMPLETE stack in dependency order:
//
//   1. Networking module  → VPC, subnets, IGW, NAT GW
//   2. Webserver module   → ALB, ASG, Launch Template (using
//                           the networking module's outputs)
//
// The key difference: integration tests tolerate shortcuts
// (default VPC, default subnets). E2E tests use the production
// networking configuration — the same module and the same
// subnet layout that real traffic flows through.
//
// WHAT E2E TESTS CATCH THAT INTEGRATION TESTS CANNOT
// ---------------------------------------------------
// - Module output/input compatibility: does the vpc_id from
//   the networking module work correctly as the webserver
//   module's input?
// - Private subnet routing: do instances in private subnets
//   actually reach the internet through the NAT Gateway?
// - Cross-module security group references work correctly
// - The full end-user journey: internet → IGW → ALB → EC2
//
// COST AND TIME
// -------------
// E2E tests: ~15-30 minutes, ~$0.30-0.60 USD per run.
// NAT Gateways are the dominant cost ($0.045/hr each).
// This is why E2E tests run on push to main, not every PR.
//
// HOW TO RUN
// ----------
//   cd test
//   go test -v -run TestFullStackEndToEnd -timeout 45m

// test/full_stack_e2e_test.go

package test

import (
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestFullStackEndToEnd deploys the full two-module stack
func TestFullStackEndToEnd(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	uid := strings.ToLower(uniqueID)

	// Use a completely unique VPC name to avoid conflicts
	vpcName := fmt.Sprintf("test-vpc-%s", uid)
	
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/networking/vpc",
		Vars: map[string]interface{}{
			"vpc_name":             vpcName,
			"vpc_cidr":             "10.100.0.0/16",
			"public_subnet_cidrs":  []string{"10.100.1.0/24", "10.100.2.0/24"},
			"private_subnet_cidrs": []string{"10.100.11.0/24", "10.100.12.0/24"},
			"environment":          "dev",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, networkingOptions, "private_subnet_ids")
	publicSubnetIDs := terraform.OutputList(t, networkingOptions, "public_subnet_ids")

	assert.NotEmpty(t, vpcID)
	assert.Equal(t, 2, len(privateSubnetIDs))
	assert.Equal(t, 2, len(publicSubnetIDs))

	appOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/services/webserver-cluster",
		Vars: map[string]interface{}{
			"cluster_name":     fmt.Sprintf("test-app-%s", uid),
			"vpc_id":           vpcID,
			"subnet_ids":       publicSubnetIDs,
			"instance_type":    "t3.micro",
			"min_size":         1,
			"max_size":         2,
			"environment":      "dev",
			"hello_world_text": "Hi Wadondera welcome back!",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, appOptions)
	terraform.InitAndApply(t, appOptions)

	albDnsName := terraform.Output(t, appOptions, "alb_dns_name")
	assert.NotEmpty(t, albDnsName)

	url := fmt.Sprintf("http://%s", albDnsName)

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		60,
		10*time.Second,
		func(statusCode int, body string) bool {
			return statusCode == http.StatusOK && strings.Contains(body, "Hi Wadondera welcome back!")
		},
	)
}

// TestFullStackDestroysCleanly - FIXED: Creates completely isolated resources
func TestFullStackDestroysCleanly(t *testing.T) {
	// DON'T use t.Parallel() for destroy tests to avoid conflicts
	// t.Parallel() - REMOVE or comment out
	
	uniqueID := random.UniqueId()
	uid := strings.ToLower(uniqueID)

	// Create a unique name for this test run
	clusterName := fmt.Sprintf("test-destroy-%s", uid)
	vpcName := fmt.Sprintf("destroy-vpc-%s", uid)
	
	t.Logf("Running destroy test with unique ID: %s", uid)
	t.Logf("VPC Name: %s", vpcName)
	t.Logf("Cluster Name: %s", clusterName)

	// STEP 1: Deploy networking module with unique names
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/networking/vpc",
		Vars: map[string]interface{}{
			"vpc_name":             vpcName,
			"vpc_cidr":             "10.200.0.0/16", // Different CIDR block to avoid conflicts
			"public_subnet_cidrs":  []string{"10.200.1.0/24", "10.200.2.0/24"},
			"private_subnet_cidrs": []string{"10.200.11.0/24", "10.200.12.0/24"},
			"environment":          "dev",
		},
		NoColor: true,
	})

	terraform.InitAndApply(t, networkingOptions)
	
	// Get outputs
	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	publicSubnetIDs := terraform.OutputList(t, networkingOptions, "public_subnet_ids")
	
	t.Logf("Created VPC: %s", vpcID)
	t.Logf("Public Subnets: %v", publicSubnetIDs)

	// STEP 2: Deploy webserver module
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/services/webserver-cluster",
		Vars: map[string]interface{}{
			"cluster_name":     clusterName,
			"vpc_id":           vpcID,
			"subnet_ids":       publicSubnetIDs,
			"instance_type":    "t3.micro",
			"min_size":         1,
			"max_size":         1,
			"environment":      "dev",
			"hello_world_text": "Testing destroy cleanup",
		},
		NoColor: true,
	})

	terraform.InitAndApply(t, terraformOptions)
	
	albDNS := terraform.Output(t, terraformOptions, "alb_dns_name")
	t.Logf("Created ALB: %s", albDNS)

	// STEP 3: Destroy in correct order (webserver first, then networking)
	t.Log("Destroying webserver module...")
	terraform.Destroy(t, terraformOptions)
	t.Log("Webserver module destroyed successfully")
	
	t.Log("Destroying networking module...")
	terraform.Destroy(t, networkingOptions)
	t.Log("Networking module destroyed successfully")
	
	t.Log("All resources destroyed cleanly")
}