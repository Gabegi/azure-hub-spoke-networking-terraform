# spoke-development/04-route-table.tf
# Route Table for Development Spoke - Forces all traffic through Hub Firewall

# ============================================================================
# ACI Subnet Route Table
# ============================================================================

module "aci_route_table" {
  count  = local.deploy_aci_subnet ? 1 : 0
  source = "../modules/route-table"

  # Naming (module handles naming internally)
  resource_type = "route"
  workload      = "aci"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Disable BGP route propagation to prevent on-premises routes
  disable_bgp_route_propagation = true

  # Routes - Force all traffic through Hub Firewall
  routes = [
    {
      name                   = "InternetViaFirewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"  # Hub Firewall private IP
    },
    {
      name                   = "ProductionSpokeViaFirewall"
      address_prefix         = "10.2.0.0/16"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"  # Hub Firewall private IP
    }
  ]

  # Associate with ACI subnet
  subnet_id = module.aci_subnet[0].subnet_id

  depends_on = [
    module.aci_subnet
  ]
}
