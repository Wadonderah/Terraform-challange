# live/dev/services/hello-wadondera-app/outputs.tf
output "alb_dns_name" {
  value = module.hello_wadondera_app.alb_dns_name
}
output "db_endpoint" {
  value = module.hello_wadondera_app.db_endpoint
}
