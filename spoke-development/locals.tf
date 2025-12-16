# spoke-staging/locals.tf
# Local variables for Staging Spoke configuration

locals {
  # Network Configuration
  spoke_address_space = var.spoke_address_space
  workload_subnet     = "10.1.0.0/24"
  data_subnet         = "10.1.1.0/24"
  app_subnet          = "10.1.2.0/24"

  # Feature Flags
  deploy_workload_subnet = var.deploy_workload_subnet
  deploy_data_subnet     = var.deploy_data_subnet
  deploy_app_subnet      = var.deploy_app_subnet

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
