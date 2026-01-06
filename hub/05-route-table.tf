# hub/04-route-table.tf
# Route Table for Hub - Routes spoke traffic through Firewall

# ============================================================================
# Gateway Subnet Route Table (for VPN/ExpressRoute → Spokes via Firewall)
# ============================================================================

module "gateway_route_table" {
  count  = local.deploy_gateway ? 1 : 0
  source = "../modules/route-table"

  # Naming (module handles naming internally)
  resource_type = "route"
  workload      = "gateway"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name

  # Disable BGP route propagation
  disable_bgp_route_propagation = true

  # Routes from tfvars
  routes = var.gateway_route_table_routes

  # Associate with Gateway subnet
  subnet_id = module.gateway_subnet[0].subnet_id

  depends_on = [
    module.gateway_subnet
  ]
}
