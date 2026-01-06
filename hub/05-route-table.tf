# hub/05-route-table.tf
# Route Table for Hub - Routes spoke traffic through Firewall

# ============================================================================
# App Gateway Subnet Route Table (for App Gateway → Spokes via Firewall)
# ============================================================================

module "app_gateway_route_table" {
  count  = local.deploy_app_gateway ? 1 : 0
  source = "../modules/route-table"

  # Naming
  route_table_name = "route-appgw-${var.environment}-${var.location}-001"
  location         = var.location

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name

  # Disable BGP route propagation
  disable_bgp_route_propagation = true

  # Routes from tfvars (routes to spoke networks via firewall)
  routes = var.app_gateway_route_table_routes

  # Associate with App Gateway subnet
  subnet_id = module.app_gateway_subnet[0].subnet_id

  # Tags
  tags = var.tags

  depends_on = [
    module.app_gateway_subnet
  ]
}
