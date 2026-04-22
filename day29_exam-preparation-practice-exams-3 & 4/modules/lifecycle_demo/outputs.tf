output "random_name" { description = "Generated name." ; value = random_pet.name.id }
output "lifecycle_summary" {
  description = "Lifecycle rules summary."
  value = {
    create_before_destroy = "applied to null_resource.cbd_demo"
    prevent_destroy       = "applied to null_resource.protected -- blocks terraform destroy only, NOT console deletion"
    ignore_changes        = "applied to null_resource.drift_demo -- timestamp trigger ignored"
  }
}