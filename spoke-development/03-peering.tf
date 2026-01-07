# spoke-development/03-peering.tf
# VNet Peering between Development Spoke and Hub

# ============================================================================
# VNet Peering: Spoke to Hub
# ============================================================================

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-development-to-hub-${var.environment}-${var.location}-001"
  resource_group_name       = module.rg_spoke.rg_name
  virtual_network_name      = module.spoke_vnet.vnet_name
  remote_virtual_network_id = local.hub_vnet_id

  # Spoke Configuration
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true  # Allow traffic forwarded by hub firewall
  allow_gateway_transit        = false # Spoke doesn't provide gateway
  use_remote_gateways          = false # Set to true if hub has VPN/ExpressRoute gateway

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }

  depends_on = [
    module.spoke_vnet
  ]
}

# ============================================================================
# VNet Peering: Hub to Spoke
# ============================================================================

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-development-${var.environment}-${var.location}-001"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = local.hub_vnet_name
  remote_virtual_network_id = module.spoke_vnet.vnet_id

  # Hub Configuration
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true  # Allow hub to forward traffic to spoke
  allow_gateway_transit        = false # Set to true if hub has VPN/ExpressRoute gateway
  use_remote_gateways          = false # Hub provides gateway, doesn't use remote

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }

  depends_on = [
    module.spoke_vnet
  ]
}
