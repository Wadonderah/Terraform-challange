# envs/staging/outputs.tf
output "website_url"                { value = module.static_website.website_url }
output "cloudfront_domain_name"     { value = module.static_website.cloudfront_domain_name }
output "cloudfront_distribution_id" { value = module.static_website.cloudfront_distribution_id }
output "deployment_summary"         { value = module.static_website.deployment_summary }
output "cache_invalidation_command" { value = module.static_website.cache_invalidation_command }
