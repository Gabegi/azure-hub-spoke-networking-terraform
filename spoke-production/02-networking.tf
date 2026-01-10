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
# VM Subnet Naming
# ============================================================================

module "vm_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "vm"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# VM Subnet
# ============================================================================

module "vm_subnet" {
  source = "../modules/subnet"

  subnet_name          = module.vm_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = ["10.2.0.0/24"]

  # No delegation needed for VMs
  delegation = null

  # No service endpoints needed for VMs
  service_endpoints = []

  private_endpoint_network_policies_enabled     = true
  private_link_service_network_policies_enabled = true

  depends_on = [module.spoke_vnet]
}

