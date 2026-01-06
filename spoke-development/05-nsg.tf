# spoke-development/03-nsg.tf
# Network Security Groups for Development Spoke

# ============================================================================
# ACI Subnet NSG
# ============================================================================

module "aci_nsg" {
  count  = local.deploy_aci_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "aci"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Security rules from variables
  security_rules = var.aci_nsg_rules

  # Associate with ACI subnet
  subnet_id = module.aci_subnet[0].subnet_id

  # Flow Logs
  enable_flow_logs                    = local.enable_flow_logs
  network_watcher_name                = local.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = local.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = var.storage_account_id

  # Traffic Analytics
  enable_traffic_analytics            = local.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = var.log_analytics_workspace_id
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id

  # Diagnostic Settings
  enable_diagnostic_settings = local.enable_diagnostics

  depends_on = [
    module.aci_subnet
  ]
}
