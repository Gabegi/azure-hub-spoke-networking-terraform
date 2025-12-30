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
  source = "../modules/subnet"

  subnet_name          = "AzureFirewallSubnet"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.firewall_subnet]

  depends_on = [module.hub_vnet]
}

# AzureFirewallManagementSubnet (REQUIRED for Basic SKU - exact name)
module "firewall_management_subnet" {
  count  = local.deploy_firewall ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "AzureFirewallManagementSubnet"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.firewall_management_subnet]

  depends_on = [module.hub_vnet]
}

# AzureBastionSubnet (REQUIRED only if deploying Bastion)
module "bastion_subnet" {
  count  = local.deploy_bastion ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "AzureBastionSubnet"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.bastion_subnet]

  depends_on = [module.hub_vnet]
}

# Management Subnet (OPTIONAL)
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

# Application Gateway Subnet (REQUIRED only if deploying App Gateway)
module "app_gateway_subnet" {
  count  = local.deploy_app_gateway ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-appgw-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = [local.app_gateway_subnet]

  depends_on = [module.hub_vnet]
}
