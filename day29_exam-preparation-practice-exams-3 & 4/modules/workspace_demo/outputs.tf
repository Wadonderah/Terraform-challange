output "info" {
  description = "Workspace-aware resource info."
  value = {
    workspace     = var.workspace_name
    resource_name = null_resource.workspace_aware.id
    is_default    = var.workspace_name == "default"
  }
}