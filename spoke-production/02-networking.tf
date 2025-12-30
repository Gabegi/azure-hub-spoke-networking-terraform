# spoke-production/02-networking.tf
# Production Spoke VNet and Subnets

# ============================================================================
# Spoke Virtual Network
# ============================================================================

module "spoke_vnet" {
  source = "../modules/vnet"

  # Naming (module handles naming internally)
  resource_type = "vnet"
  workload      = "spoke-production"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name
  address_space       = [local.spoke_address_space]

  depends_on = [module.rg_networking]
}

# ============================================================================
# Spoke Subnets
# ============================================================================

# Workload Subnet (for general workloads)
module "workload_subnet" {
  count  = local.deploy_workload_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-workload-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.workload_subnet]

  service_endpoints = var.workload_subnet_service_endpoints

  depends_on = [module.spoke_vnet]
}

# Data Subnet (for databases, storage)
module "data_subnet" {
  count  = local.deploy_data_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-data-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.data_subnet]

  service_endpoints = var.data_subnet_service_endpoints

  depends_on = [module.spoke_vnet]
}

# App Subnet (for application tier)
module "app_subnet" {
  count  = local.deploy_app_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-app-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.app_subnet]

  service_endpoints = var.app_subnet_service_endpoints

  depends_on = [module.spoke_vnet]
}

# ACI Subnet (for Azure Container Instances)
module "aci_subnet" {
  count  = local.deploy_aci_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = "snet-aci-${var.environment}-${var.location}-001"
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.aci_subnet]

  # Delegate subnet to Azure Container Instances
  delegation = {
    name         = "aci-delegation"
    service_name = "Microsoft.ContainerInstance/containerGroups"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/action"
    ]
  }

  depends_on = [module.spoke_vnet]
}
