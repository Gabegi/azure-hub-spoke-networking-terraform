# hub/01-foundation.tf
# Foundation resources: Resource Group

# ============================================================================
# Naming Modules
# ============================================================================

module "rg_naming" {
  source = "../modules/naming"

  resource_type = "rg"
  workload      = "networking"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Resource Group
# ============================================================================

module "rg_networking" {
  source = "../modules/resource-group"

  rg_name  = module.rg_naming.name
  location = var.location
  tags     = module.rg_naming.tags

  # # Enable resource lock for production
  # enable_resource_lock = var.environment == "prod" ? var.enable_resource_lock : false
  # lock_level          = "CanNotDelete"
  # lock_notes          = "Production networking resources - managed by Terraform"
}
