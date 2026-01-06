# spoke-development/02-networking.tf
# Development Spoke VNet and Subnets

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
# ACI Subnet Naming
# ============================================================================

module "aci_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "aci"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Spoke Subnets
# ============================================================================

# ACI Subnet (for Azure Container Instances)
module "aci_subnet" {
  count  = local.deploy_aci_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = module.aci_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.aci_subnet]

  # Service endpoints for ACI
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]

  # Delegation required for ACI
  delegation = {
    name         = "aci-delegation"
    service_name = "Microsoft.ContainerInstance/containerGroups"
    actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }

  depends_on = [module.spoke_vnet]
}
