# spoke-production/04-route-table.tf
# Route Tables for Production Spoke subnets

# ============================================================================
# Naming Modules
# ============================================================================

module "workload_route_table_naming" {
  source = "../modules/naming"

  resource_type = "route"
  workload      = "workload"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "data_route_table_naming" {
  source = "../modules/naming"

  resource_type = "route"
  workload      = "data"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "app_route_table_naming" {
  source = "../modules/naming"

  resource_type = "route"
  workload      = "app"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Workload Subnet Route Table
# ============================================================================

module "workload_route_table" {
  count  = local.deploy_workload_subnet && local.enable_forced_tunneling ? 1 : 0
  source = "../modules/route-table"

  route_table_name    = module.workload_route_table_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name

  # Disable BGP route propagation to prevent on-premises routes
  disable_bgp_route_propagation = true

  routes = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.next_hop_firewall_ip
    },
    {
      name                   = "to-development-spoke"
      address_prefix         = "10.1.0.0/16"  # Development spoke
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.next_hop_firewall_ip
    }
  ]

  # Associate with workload subnet
  subnet_id = module.workload_subnet[0].subnet_id

  tags = module.workload_route_table_naming.tags

  depends_on = [
    module.workload_subnet
  ]
}

# ============================================================================
# Data Subnet Route Table
# ============================================================================

module "data_route_table" {
  count  = local.deploy_data_subnet && local.enable_forced_tunneling ? 1 : 0
  source = "../modules/route-table"

  route_table_name    = module.data_route_table_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name

  # Disable BGP route propagation
  disable_bgp_route_propagation = true

  routes = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.next_hop_firewall_ip
    },
    {
      name                   = "to-development-spoke"
      address_prefix         = "10.1.0.0/16"  # Development spoke
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.next_hop_firewall_ip
    }
  ]

  # Associate with data subnet
  subnet_id = module.data_subnet[0].subnet_id

  tags = module.data_route_table_naming.tags

  depends_on = [
    module.data_subnet
  ]
}

# ============================================================================
# Application Subnet Route Table
# ============================================================================

module "app_route_table" {
  count  = local.deploy_app_subnet && local.enable_forced_tunneling ? 1 : 0
  source = "../modules/route-table"

  route_table_name    = module.app_route_table_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name

  # Disable BGP route propagation
  disable_bgp_route_propagation = true

  routes = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.next_hop_firewall_ip
    },
    {
      name                   = "to-development-spoke"
      address_prefix         = "10.1.0.0/16"  # Development spoke
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.next_hop_firewall_ip
    }
  ]

  # Associate with app subnet
  subnet_id = module.app_subnet[0].subnet_id

  tags = module.app_route_table_naming.tags

  depends_on = [
    module.app_subnet
  ]
}
