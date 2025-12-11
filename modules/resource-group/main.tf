# modules/resource-group/main.tf
# Resource Group module - Azure resource container

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Optional: Apply resource lock to prevent deletion
resource "azurerm_management_lock" "rg_lock" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "${var.rg_name}-lock"
  scope      = azurerm_resource_group.rg.id
  lock_level = var.lock_level # CanNotDelete or ReadOnly
  notes      = var.lock_notes

  depends_on = [azurerm_resource_group.rg]
}
