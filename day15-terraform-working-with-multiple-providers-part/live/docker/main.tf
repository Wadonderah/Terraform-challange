# live/docker/main.tf
# -----------------------------------------------------------------------------
# Docker Provider — Local Container Deployment
#
# This configuration uses the kreuzwerker Docker provider to manage containers
# directly on the local Docker daemon. It is an ideal way to validate container
# configurations before promoting them to ECS/EKS.
#
# Prerequisites:
#   - Docker Desktop (macOS/Windows) or Docker Engine (Linux) must be running.
#   - The Docker provider communicates over the local Unix socket by default.
#
# Usage:
#   terraform init
#   terraform apply       → pulls nginx:latest and starts the container
#   curl http://localhost:8080   → should return the nginx welcome page
#   terraform destroy     → stops and removes the container
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# No additional configuration is needed when Docker is running locally.
# For remote Docker hosts use: host = "tcp://remote-host:2376"
provider "docker" {}

# ---------------------------------------------------------------------------
# Pull the nginx image
# keep_locally = false means Terraform will remove the image on destroy.
# Set to true in CI environments where image caching matters.
# ---------------------------------------------------------------------------

resource "docker_image" "nginx" {
  name         = "nginx:${var.nginx_version}"
  keep_locally = false
}

# ---------------------------------------------------------------------------
# Run the container
# ---------------------------------------------------------------------------

resource "docker_container" "nginx" {
  image   = docker_image.nginx.image_id
  name    = "terraform-nginx"
  restart = "unless-stopped"

  # Map host port 8080 → container port 80

  ports {
    internal = 80
    external = var.host_port
  }

  # Healthcheck so Terraform can confirm the container is actually serving

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost/"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "5s"
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }

  labels {
    label = "day"
    value = "15"
  }

  labels {
    label = "challenge"
    value = "30DayTerraformChallenge"
  }
}
