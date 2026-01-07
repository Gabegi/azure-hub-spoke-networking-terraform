# modules/subnet/main.tf
# Generic Subnet module - reusable for any subnet type

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
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
    ignore_changes = [tags]
  }
}
