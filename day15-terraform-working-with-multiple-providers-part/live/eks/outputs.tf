# live/eks/outputs.tf

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster."
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC created for the EKS cluster."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets where worker nodes run."
  value       = module.vpc.private_subnets
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "nginx_namespace" {
  description = "Kubernetes namespace where the nginx workload is deployed."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "nginx_service_name" {
  description = "Kubernetes Service name for nginx."
  value       = kubernetes_service.nginx.metadata[0].name
}
