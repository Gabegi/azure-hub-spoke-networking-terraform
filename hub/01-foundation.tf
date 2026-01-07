# hub/01-foundation.tf
# Foundation resources: Resource Group

# ============================================================================
# Resource Group
# ============================================================================

module "rg_networking" {
  source = "../modules/resource-group"

  # Naming (module handles naming internally)
  resource_type = "rg"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # # Enable resource lock for production (only enable when not testing)
  # enable_resource_lock = var.environment == "prod" ? var.enable_resource_lock : false
  # lock_level          = "CanNotDelete"
  # lock_notes          = "Production networking resources - managed by Terraform"
}
