# live/eks/variables.tf

variable "aws_region" {
  description = "AWS region where the EKS cluster will be created."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (dev | staging | prod)."
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy the nginx workload into."
  type        = string
  default     = "demo"
}

variable "nginx_replicas" {
  description = "Number of nginx pod replicas in the Deployment."
  type        = number
  default     = 2

  validation {
    condition     = var.nginx_replicas >= 1 && var.nginx_replicas <= 10
    error_message = "nginx_replicas must be between 1 and 10."
  }
}

variable "nginx_image_tag" {
  description = "nginx Docker image tag."
  type        = string
  default     = "latest"
}
