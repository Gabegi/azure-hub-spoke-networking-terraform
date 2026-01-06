# spoke-production/05-peering.tf
# VNet Peering between Production Spoke and Hub

# ============================================================================
# Naming Modules
# ============================================================================

module "spoke_to_hub_peering_naming" {
  source = "../modules/naming"

  resource_type = "peer"
  workload      = "production-to-hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "hub_to_spoke_peering_naming" {
  source = "../modules/naming"

  resource_type = "peer"
  workload      = "hub-to-production"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# VNet Peering: Spoke to Hub
# ============================================================================

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = module.spoke_to_hub_peering_naming.name
  resource_group_name       = module.rg_spoke.rg_name
  virtual_network_name      = module.spoke_vnet.vnet_name
  remote_virtual_network_id = local.hub_vnet_id

  # Spoke Configuration
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true  # Allow traffic forwarded by hub firewall
  allow_gateway_transit        = false # Spoke doesn't provide gateway
  use_remote_gateways          = false # Set to true if hub has VPN/ExpressRoute gateway

  depends_on = [
    module.spoke_vnet
  ]
}

# ============================================================================
# VNet Peering: Hub to Spoke
# ============================================================================

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = module.hub_to_spoke_peering_naming.name
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = local.hub_vnet_name
  remote_virtual_network_id = module.spoke_vnet.vnet_id

  # Hub Configuration
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true  # Allow hub to forward traffic to spoke
  allow_gateway_transit        = false # Set to true if hub has VPN/ExpressRoute gateway
  use_remote_gateways          = false # Hub provides gateway, doesn't use remote

  depends_on = [
    module.spoke_vnet
  ]
}
