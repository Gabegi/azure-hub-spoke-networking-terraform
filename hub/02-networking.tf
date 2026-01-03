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
  address_space       = [local.hub_address_space]

  depends_on = [module.rg_networking]
}

# ============================================================================
# Hub Subnets
# ============================================================================

# AzureFirewallSubnet (REQUIRED - exact name)
module "firewall_subnet" {
  count  = local.deploy_firewall ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "AzureFirewallSubnet"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.firewall_subnet]

  depends_on = [module.hub_vnet]
}

# GatewaySubnet (REQUIRED for VPN/ExpressRoute - exact name)
module "gateway_subnet" {
  count  = local.deploy_gateway ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "GatewaySubnet"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.gateway_subnet]

  depends_on = [module.hub_vnet]
}

# Management Subnet (OPTIONAL - future use)
module "management_subnet" {
  count  = local.deploy_mgmt ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-management-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.management_subnet]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry"
  ]

  depends_on = [module.hub_vnet]
}
