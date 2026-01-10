# spoke-production/04-route-table.tf
# Route Tables for Production Spoke

# ============================================================================
# VM Subnet Route Table
# ============================================================================

module "vm_route_table" {
  source = "../modules/route-table"

  # Naming (module handles naming internally)
  resource_type = "route"
  workload      = "vm"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Disable BGP route propagation to prevent on-premises routes
  bgp_route_propagation_enabled = false

  # Routes from tfvars
  routes = var.vm_route_table_routes

  # Associate with VM subnet
  subnet_id = module.vm_subnet.subnet_id

  depends_on = [
    module.vm_subnet
  ]
}
