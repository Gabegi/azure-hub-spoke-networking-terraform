# modules/vnet/main.tf
# Generic Virtual Network module - reusable for hub and spoke VNets

# ============================================================================
# Internal Naming Module
# ============================================================================

module "vnet_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Virtual Network
# ============================================================================

resource "azurerm_virtual_network" "vnet" {
  name                = module.vnet_naming.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = module.vnet_naming.tags

  # Optional DDoS protection plan
  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false  # Set to true for production
    ignore_changes = [tags]
  }
}
