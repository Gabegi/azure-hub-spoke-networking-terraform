# modules/subnet/main.tf
# Generic Subnet module - reusable for any subnet type

# ============================================================================
# Internal Naming Module
# ============================================================================

module "naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Subnet Resource
# ============================================================================

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name != null ? var.subnet_name : module.naming.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.address_prefixes

  # Optional service endpoints
  service_endpoints = var.service_endpoints

  # Optional delegation for specific Azure services
  dynamic "delegation" {
    for_each = var.delegation != null ? [var.delegation] : []
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
    
  }

  # Private endpoint network policies
  private_endpoint_network_policies_enabled     = var.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = var.private_link_service_network_policies_enabled

  lifecycle {
    prevent_destroy = false
  }
}
