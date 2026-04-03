// test/webserver_cluster_test.go
//
// Day 18: Integration Tests with Terratest
//
// WHAT INTEGRATION TESTS DO
// -------------------------
// Integration tests deploy REAL AWS infrastructure, run HTTP
// assertions against it, and then destroy everything — even
// if assertions fail. This tests that all components work
// together: the Launch Template boots correctly, the ASG
// registers with the ALB, the security groups allow traffic,
// and the health checks pass within the grace period.
//
// WHAT INTEGRATION TESTS CATCH THAT UNIT TESTS CANNOT
// ----------------------------------------------------
// - The user_data script actually runs and starts the web server
// - The security group rules actually allow ALB -> EC2 traffic
// - The ALB health check succeeds against the running application
// - The real AWS DNS name resolves and serves HTTP 200
//
// COST AND TIME
// -------------
// Each integration test run: ~5-15 minutes, ~$0.05-0.20 USD
// Costs come from: NAT Gateway minutes, ALB hours, EC2 hours
// The defer terraform.Destroy call guarantees cleanup even on panic.
//
// HOW TO RUN
// ----------
//   cd test
//   go test -v -run TestWebserverClusterIntegration -timeout 30m
//
// REQUIRED ENVIRONMENT VARIABLES
// --------------------------------
//   AWS_ACCESS_KEY_ID
//   AWS_SECRET_ACCESS_KEY
//   AWS_DEFAULT_REGION (defaults to us-east-1)

// test/webserver_cluster_test.go

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
	"github.com/stretchr/testify/require"
)

// TestWebserverClusterIntegration - FIXED to include VPC dependency
func TestWebserverClusterIntegration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	uid := strings.ToLower(uniqueID)
	clusterName := fmt.Sprintf("test-cluster-%s", uid)
	vpcName := fmt.Sprintf("test-vpc-%s", uid)

	// Deploy networking module first
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
	publicSubnetIDs := terraform.OutputList(t, networkingOptions, "public_subnet_ids")

	// Deploy webserver module
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/services/webserver-cluster",
		Vars: map[string]interface{}{
			"cluster_name":     clusterName,
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

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	assert.NotEmpty(t, albDnsName)

	url := fmt.Sprintf("http://%s", albDnsName)

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		30,
		10*time.Second,
		func(statusCode int, body string) bool {
			return statusCode == http.StatusOK && strings.Contains(body, "Hi Wadondera welcome back!")
		},
	)

	serverPort := terraform.Output(t, terraformOptions, "server_port")
	assert.Equal(t, "8080", serverPort)
}

// TestWebserverClusterWithCustomText - FIXED
func TestWebserverClusterWithCustomText(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	uid := strings.ToLower(uniqueID)
	clusterName := fmt.Sprintf("test-custom-%s", uid)
	vpcName := fmt.Sprintf("custom-vpc-%s", uid)
	customText := fmt.Sprintf("Hello from cluster %s", clusterName)

	// Deploy networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/networking/vpc",
		Vars: map[string]interface{}{
			"vpc_name":             vpcName,
			"vpc_cidr":             "10.101.0.0/16",
			"public_subnet_cidrs":  []string{"10.101.1.0/24", "10.101.2.0/24"},
			"private_subnet_cidrs": []string{"10.101.11.0/24", "10.101.12.0/24"},
			"environment":          "dev",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	publicSubnetIDs := terraform.OutputList(t, networkingOptions, "public_subnet_ids")

	// Deploy webserver module
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
			"hello_world_text": customText,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	require.NotEmpty(t, albDnsName)

	url := fmt.Sprintf("http://%s", albDnsName)

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		30,
		10*time.Second,
		func(statusCode int, body string) bool {
			return statusCode == http.StatusOK && strings.Contains(body, customText)
		},
	)
}