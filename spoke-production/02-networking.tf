# spoke-production/02-networking.tf
# Production Spoke VNet and Subnets

# ============================================================================
# Spoke Virtual Network
# ============================================================================

module "spoke_vnet" {
  source = "../modules/vnet"

  # Naming (module handles naming internally)
  resource_type = "vnet"
  workload      = "spoke"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name
  address_space       = [local.spoke_address_space]

  depends_on = [module.rg_spoke]
}

# ============================================================================
# Function App Subnet Naming
# ============================================================================

module "function_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "function"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Spoke Subnets
# ============================================================================

# Function App Subnet (for Azure Function Apps with VNet Integration)
module "function_subnet" {
  count  = local.deploy_function_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = module.function_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.function_subnet]

  # Service endpoints for Function Apps
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Web"
  ]

  # Delegation required for Function App VNet Integration
  delegation = {
    name         = "function-delegation"
    service_name = "Microsoft.Web/serverFarms"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/action"
    ]
  }

  depends_on = [module.spoke_vnet]
}
