# hub/02-networking.tf
# Hub VNet and Subnets

# ============================================================================
# Hub Virtual Network
# ============================================================================

module "hub_vnet" {
  source = "../modules/vnet"

  # Naming (module handles naming internally)
  resource_type = "vnet"
  workload      = "hub"
  environment   = var.environment
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  address_space       = [var.hub_address_space]

  depends_on = [module.rg_networking]
}

# ============================================================================
# Hub Subnets
# ============================================================================

# AzureFirewallSubnet (REQUIRED - exact name)
module "firewall_subnet" {
  count  = var.deploy_firewall ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "AzureFirewallSubnet"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [var.firewall_subnet]

  depends_on = [module.hub_vnet]
}

# Application Gateway Subnet
module "app_gateway_subnet" {
  count  = var.deploy_app_gateway ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-appgw-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [var.app_gateway_subnet]

  depends_on = [module.hub_vnet]
}
