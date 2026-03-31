# live/docker/outputs.tf

output "container_id" {
  description = "Full SHA256 container ID assigned by Docker."
  value       = docker_container.nginx.id
}

output "container_name" {
  description = "Docker container name."
  value       = docker_container.nginx.name
}

output "container_url" {
  description = "URL to reach the running nginx container from the host."
  value       = "http://localhost:${var.host_port}"
}

output "image_id" {
  description = "Image ID (SHA256 digest) of the pulled nginx image."
  value       = docker_image.nginx.image_id
}
