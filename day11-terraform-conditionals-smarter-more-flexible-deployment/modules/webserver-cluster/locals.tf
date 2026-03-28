###############################################################################
# modules/webserver-cluster/locals.tf
#
# ALL conditional decisions live here — never scatter ternary operators
# directly in resource arguments.  Resources simply reference local values.
#
# Why centralise?
#   • One place to read, one place to change, one place to test.
#   • Resource blocks stay declarative and readable.
#   • You can add a new environment tier (e.g. "staging") by editing
#     locals only — every resource picks up the change automatically.
###############################################################################

locals {
  # ─── Environment shorthand ──────────────────────────────────────────────
  is_production = var.environment == "production"
  is_staging    = var.environment == "staging"
  is_dev        = var.environment == "dev"

  # ─── Compute sizing ─────────────────────────────────────────────────────
  # Production: right-sized instances and enough capacity for HA.
  # Non-production: smallest possible to keep costs low.
  instance_type = local.is_production ? "t3.micro" : "t3.micro"
  min_size      = local.is_production ? 3 : 1
  max_size      = local.is_production ? 10 : 3

  # ─── Monitoring & observability ─────────────────────────────────────────
  # Detailed monitoring is always on in production; in staging/dev it is
  # controlled by the explicit feature flag so engineers can opt in cheaply.
  enable_monitoring = local.is_production ? true : var.enable_detailed_monitoring

  # ─── Storage lifecycle ──────────────────────────────────────────────────
  # Retain production state to guard against accidental destroy; delete in
  # lower environments to avoid zombie resources and cost.
  deletion_policy = local.is_production ? "Retain" : "Delete"

  # ─── Tagging ────────────────────────────────────────────────────────────
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Cluster     = var.cluster_name
  }

  # ─── Networking — brownfield vs greenfield ──────────────────────────────
  # Resolves to the correct VPC id regardless of whether we created it or
  # re-used an existing one.  Both branches are evaluated at plan time;
  # the one that isn't active returns null (the conditional prevents the
  # reference from being followed).
  # Resolves to the correct VPC id regardless of brownfield or greenfield mode
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id

  # ─── DNS ────────────────────────────────────────────────────────────────
  # Only referenced when create_dns_record = true; kept here for symmetry.
  alb_fqdn = var.create_dns_record ? var.domain_name : ""
}
