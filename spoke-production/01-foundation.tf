# spoke-production/01-foundation.tf
# Resource Group for Production Spoke

# ============================================================================
# Resource Group
# ============================================================================

module "rg_spoke" {
  source = "../modules/resource-group"

  # Naming (module handles naming internally)
  resource_type = "rg"
  workload      = "spoke-production"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Resource Lock Configuration (enabled by default for production)
  enable_resource_lock = var.enable_resource_lock
  lock_level           = var.lock_level
}
