# spoke-development/01-foundation.tf
# Resource Group for Development Spoke

# ============================================================================
# Naming Modules
# ============================================================================

module "rg_naming" {
  source = "../modules/naming"

  resource_type = "rg"
  workload      = "spoke-development"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Resource Group
# ============================================================================

module "rg_spoke" {
  source = "../modules/resource-group"

  rg_name  = module.rg_naming.name
  location = var.location
  tags     = module.rg_naming.tags

  # Resource Lock Configuration
  enable_resource_lock = var.enable_resource_lock
  lock_level           = var.lock_level
}
