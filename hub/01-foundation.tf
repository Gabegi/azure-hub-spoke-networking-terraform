# hub/01-foundation.tf
# Foundation resources: Resource Group

# ============================================================================
# Resource Group
# ============================================================================

module "rg_networking" {
  source = "../modules/resource-group"

  rg_name  = "rg-networking-${var.environment}-${var.location}-001"
  location = var.location
  tags     = var.tags

  # # Enable resource lock for production (only enable when not testing)
  # enable_resource_lock = var.environment == "prod" ? var.enable_resource_lock : false
  # lock_level          = "CanNotDelete"
  # lock_notes          = "Production networking resources - managed by Terraform"
}
