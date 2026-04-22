output "challenge_complete" {
  description = "Challenge completion confirmation."
  value = {
    status      = "COMPLETE"
    day         = 30
    environment = var.environment
    workspace   = var.workspace
    message     = "30-Day Terraform Challenge complete. Go pass the exam."
  }
}