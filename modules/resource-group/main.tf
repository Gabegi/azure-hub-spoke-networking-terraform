# modules/resource-group/main.tf
# Resource Group module - Azure resource container

# ============================================================================
# Internal Naming Module
# ============================================================================

module "rg_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "rg" {
  name     = module.rg_naming.name
  location = var.location
  tags     = module.rg_naming.tags

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Optional: Apply resource lock to prevent deletion
resource "azurerm_management_lock" "rg_lock" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "${module.rg_naming.name}-lock"
  scope      = azurerm_resource_group.rg.id
  lock_level = var.lock_level # CanNotDelete or ReadOnly
  notes      = var.lock_notes

  depends_on = [azurerm_resource_group.rg]
}
