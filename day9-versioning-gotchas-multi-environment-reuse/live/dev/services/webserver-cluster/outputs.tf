output "alb_dns_name" {
  description = "Dev ALB endpoint"
  value       = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  description = "Dev ASG name"
  value       = module.webserver_cluster.asg_name
}
