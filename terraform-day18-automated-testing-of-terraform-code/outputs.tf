##############################################################
# outputs.tf — Root module (Day 18)
##############################################################

output "alb_dns_name" {
  description = "ALB DNS name — paste into curl for manual verification"
  value       = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.webserver_cluster.asg_name
}

output "cluster_name" {
  description = "Cluster name used as resource prefix"
  value       = module.webserver_cluster.cluster_name
}
