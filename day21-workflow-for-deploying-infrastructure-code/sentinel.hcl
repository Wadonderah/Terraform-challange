# sentinel.hcl
# Terraform Cloud reads this file to configure policy enforcement levels.
# Place this alongside your sentinel/ directory at the root of your policy set.
#
# Enforcement levels:
#   advisory       — logs violations, does NOT block apply
#   soft-mandatory — blocks apply, but operators can OVERRIDE with justification
#   hard-mandatory — blocks apply, NO override possible

policy "require-instance-type" {
  source            = "./sentinel/require-instance-type.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "cost-estimation" {
  source            = "./sentinel/cost-estimation.sentinel"
  enforcement_level = "soft-mandatory" # advisory in dev, promote to hard in prod
}

policy "require-tags" {
  source            = "./sentinel/require-tags.sentinel"
  enforcement_level = "soft-mandatory" # allow overrides with justification
}

policy "prevent-public-s3" {
  source            = "./sentinel/prevent-public-s3.sentinel"
  enforcement_level = "hard-mandatory" # no public S3 buckets allowed
}
