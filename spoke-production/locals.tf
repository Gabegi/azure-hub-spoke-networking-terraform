# spoke-production/locals.tf
# Local variables for Production Spoke configuration

locals {
  # Network Configuration
  spoke_address_space = var.spoke_address_space
  function_subnet     = "10.2.0.0/24"  # Function App subnet (reusing ACI subnet range)

  # Feature Flags
  deploy_function_subnet = var.deploy_function_subnet

  # Monitoring Configuration
  enable_diagnostics        = var.enable_diagnostics
  enable_flow_logs          = var.enable_flow_logs && var.storage_account_id != null
  enable_traffic_analytics  = var.enable_traffic_analytics && var.log_analytics_workspace_id != null

  # Route Table Configuration
  enable_forced_tunneling = var.enable_forced_tunneling
  next_hop_firewall_ip    = var.hub_firewall_private_ip

  # Peering Configuration
  hub_vnet_id   = var.hub_vnet_id
  hub_vnet_name = var.hub_vnet_name
}
