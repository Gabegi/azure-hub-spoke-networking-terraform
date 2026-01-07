# spoke-development/01-foundation.tf
# Resource Group for Development Spoke

# ============================================================================
# Resource Group
# ============================================================================

module "rg_spoke" {
  source = "../modules/resource-group"

  rg_name  = "rg-spoke-development-${var.environment}-${var.location}-001"
  location = var.location
  tags     = var.tags

  # Resource Lock Configuration
  enable_resource_lock = var.enable_resource_lock
  lock_level           = var.lock_level
}
