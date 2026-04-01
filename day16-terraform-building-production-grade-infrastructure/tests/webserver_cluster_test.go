// tests/webserver_cluster_test.go
// Terratest integration test for the webserver cluster.
// Run with: go test -v -timeout 30m ./tests/
//
// Prerequisites:
//   - Go 1.21+
//   - AWS credentials configured (IAM role or env vars)
//   - go get github.com/gruntwork-io/terratest/modules/terraform
//   - go get github.com/gruntwork-io/terratest/modules/http-helper

package test

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestWebserverClusterDeploysAndResponds is a full integration test.
// It deploys real AWS infrastructure into the dev environment, asserts the
// ALB returns HTTP 200, and then tears everything down.
//
// defer terraform.Destroy is CRITICAL — it guarantees cleanup even if the
// test panics, preventing orphaned resources and unexpected AWS bills.
func TestWebserverClusterDeploysAndResponds(t *testing.T) {
	t.Parallel()

	// Generate a unique cluster name so parallel test runs don't collide
	uniqueID := random.UniqueId()
	clusterName := fmt.Sprintf("test-cluster-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Point at the dev environment (smallest, cheapest)
		TerraformDir: "../environments/dev",

		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"instance_type":      "t3.micro",
			"min_size":           1,
			"max_size":           2,
			"desired_capacity":   1,
			"environment":        "dev",
			"project_name":       "terratest",
			"team_name":          "ci",
			"cost_center":        "CC-TEST",
			"state_bucket_name":  fmt.Sprintf("terratest-state-%s", uniqueID),
			"config_bucket_name": fmt.Sprintf("terratest-config-%s", uniqueID),
		},

		// Retry logic for eventual-consistency issues
		RetryableTerraformErrors: map[string]string{
			"RequestError: send request failed": "Transient AWS API error",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	})

	// CRITICAL: defer ensures Destroy runs even if assertions panic or fail.
	// Without this, a failed test leaves real AWS resources running and accruing cost.
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Retrieve outputs
	albDNSName := terraform.Output(t, terraformOptions, "alb_dns_name")
	asgName := terraform.Output(t, terraformOptions, "asg_name")

	require.NotEmpty(t, albDNSName, "alb_dns_name output must not be empty")
	require.NotEmpty(t, asgName, "asg_name output must not be empty")

	url := fmt.Sprintf("http://%s", albDNSName)

	// Assert: ALB returns HTTP 200 with "Hello" in the body.
	// HttpGetWithRetry polls every 10s for up to 5 minutes —
	// necessary because the ASG needs time to launch instances and pass health checks.
	http_helper.HttpGetWithRetry(
		t,
		url,
		&tls.Config{},
		200,      // expected status code
		"Hello",  // expected body substring
		30,       // max retries
		10*time.Second, // sleep between retries
	)

	// Assert: ASG has at least 1 healthy instance
	awsRegion := "us-east-1"
	asgSize := aws.GetAsgSize(t, asgName, awsRegion)
	assert.GreaterOrEqual(t, asgSize, 1, "ASG should have at least 1 instance in service")

	// Assert: Health endpoint responds correctly
	healthURL := fmt.Sprintf("http://%s/health", albDNSName)
	resp, err := http.Get(healthURL)
	require.NoError(t, err)
	assert.Equal(t, 200, resp.StatusCode, "/health endpoint should return 200")
}

// TestWebserverClusterValidation tests that invalid variable values are rejected
// before any infrastructure is created. This is fast and cheap — no AWS calls.
func TestWebserverClusterValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../environments/dev",
		Vars: map[string]interface{}{
			"cluster_name":  "myapp-dev",
			"environment":   "invalid-env", // Should fail validation
			"instance_type": "m5.large",    // Should fail validation (not t2/t3)
		},
	}

	// InitAndPlan should fail because of validation errors — this is the expected outcome
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Terraform plan should fail when invalid variable values are provided")
}
