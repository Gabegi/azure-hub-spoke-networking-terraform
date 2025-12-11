# spoke-production/02-networking.tf
# Production Spoke VNet and Subnets

# ============================================================================
# Naming Modules
# ============================================================================

module "spoke_vnet_naming" {
  source = "../modules/naming"

  resource_type = "vnet"
  workload      = "spoke-production"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "workload_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "workload"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "data_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "data"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "app_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "app"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Spoke Virtual Network
# ============================================================================

module "spoke_vnet" {
  source = "../modules/vnet"

  vnet_name           = module.spoke_vnet_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name
  address_space       = [local.spoke_address_space]

  tags = module.spoke_vnet_naming.tags

  depends_on = [module.rg_spoke]
}

# ============================================================================
# Spoke Subnets
# ============================================================================

# Workload Subnet (General purpose compute resources)
module "workload_subnet" {
  count  = local.deploy_workload_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = module.workload_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.workload_subnet]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry"
  ]

  depends_on = [module.spoke_vnet]
}

# Data Subnet (Databases, data services)
module "data_subnet" {
  count  = local.deploy_data_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = module.data_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.data_subnet]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]

  depends_on = [module.spoke_vnet]
}

# Application Subnet (App services, web apps)
module "app_subnet" {
  count  = local.deploy_app_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = module.app_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.app_subnet]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Web"
  ]

  depends_on = [module.spoke_vnet]
}
