# spoke-production/04-route-table.tf
# Route Table for Production Spoke - Forces all traffic through Hub Firewall

# ============================================================================
# Function App Subnet Route Table
# ============================================================================

module "function_route_table" {
  count  = local.deploy_function_subnet ? 1 : 0
  source = "../modules/route-table"

  # Naming (module handles naming internally)
  resource_type = "route"
  workload      = "function"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Disable BGP route propagation to prevent on-premises routes
  disable_bgp_route_propagation = true

  # Routes from tfvars
  routes = var.route_table_routes

  # Associate with Function App subnet
  subnet_id = module.function_subnet[0].subnet_id

  depends_on = [
    module.function_subnet
  ]
}
