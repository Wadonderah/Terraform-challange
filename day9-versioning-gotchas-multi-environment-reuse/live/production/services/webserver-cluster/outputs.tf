output "alb_dns_name" {
  description = "Production ALB endpoint"
  value       = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  description = "Production ASG name"
  value       = module.webserver_cluster.asg_name
}
