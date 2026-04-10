// tests/integration/hello_wadondera_app_test.go
// Terratest integration test — deploys the full stack into a real AWS sandbox account,
// verifies the ALB responds correctly, then destroys everything.
//
// Run with:
//   export TF_VAR_db_username=testuser
//   export TF_VAR_db_password=TestPass123!
//   go test -v -timeout 60m ./tests/integration/

package integration

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	awsRegion      = "us-east-2"
	tfDir          = "../../live/dev/services/hello-wadondera-app"
	maxRetries     = 30
	sleepBetween   = 10 * time.Second
)

func TestHelloWorldAppDev(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tfDir,
		Vars: map[string]interface{}{
			"db_username": "testuser",
			"db_password": "TestPass123!",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Always destroy at the end — even if tests fail
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the full stack
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	albDNSName := terraform.Output(t, terraformOptions, "alb_dns_name")
	require.NotEmpty(t, albDNSName, "ALB DNS name should not be empty")

	// Test 1: ALB root endpoint returns 200 with expected body
	url := fmt.Sprintf("http://%s", albDNSName)
	testALBResponse(t, url, 200, "Hello, World")

	// Test 2: Health check endpoint returns 200
	healthURL := fmt.Sprintf("http://%s/health", albDNSName)
	testALBResponse(t, healthURL, 200, "OK")
}

// testALBResponse retries the HTTP request until the ALB is healthy and
// the response matches expected status code and body substring.
func testALBResponse(t *testing.T, url string, expectedStatus int, expectedBody string) {
	t.Helper()

	httpClient := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: false},
		},
	}

	description := fmt.Sprintf("GET %s — expecting %d with body containing '%s'", url, expectedStatus, expectedBody)

	retry.DoWithRetry(t, description, maxRetries, sleepBetween, func() (string, error) {
		resp, err := httpClient.Get(url)
		if err != nil {
			return "", fmt.Errorf("HTTP GET failed: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != expectedStatus {
			return "", fmt.Errorf("expected status %d, got %d", expectedStatus, resp.StatusCode)
		}

		body := make([]byte, 1024)
		n, _ := resp.Body.Read(body)
		bodyStr := string(body[:n])

		if expectedBody != "" {
			assert.Contains(t, bodyStr, expectedBody)
		}

		return bodyStr, nil
	})
}

// TestHelloWorldAppASGScaling verifies that the ASG has the correct
// min/max/desired settings after deployment.
func TestHelloWorldAppASGScaling(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tfDir,
		Vars: map[string]interface{}{
			"db_username": "testuser",
			"db_password": "TestPass123!",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	asgName := terraform.Output(t, terraformOptions, "asg_name")
	require.NotEmpty(t, asgName)

	asg := aws.GetAsgByName(t, asgName, awsRegion)

	assert.Equal(t, int64(1), aws.Int64Value(asg.MinSize),
		"Dev min_size should be 1")
	assert.Equal(t, int64(2), aws.Int64Value(asg.MaxSize),
		"Dev max_size should be 2")
}
