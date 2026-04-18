variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for your domain"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application (e.g. app.example.com)"
  type        = string
}

variable "primary_alb_dns_name" {
  description = "DNS name of the primary region ALB"
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Zone ID of the primary region ALB"
  type        = string
}

variable "secondary_alb_dns_name" {
  description = "DNS name of the secondary region ALB"
  type        = string
}

variable "secondary_alb_zone_id" {
  description = "Zone ID of the secondary region ALB"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region identifier"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region identifier"
  type        = string
}

variable "health_check_path" {
  description = "HTTP path polled by Route53 health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Seconds between Route53 health check polls"
  type        = number
  default     = 30
}

variable "health_check_failure_threshold" {
  description = "Consecutive failures before marking unhealthy"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
