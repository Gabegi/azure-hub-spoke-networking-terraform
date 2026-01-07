# spoke-production/05-nsg.tf
# Network Security Groups for Production Spoke

# ============================================================================
# Function App Subnet NSG
# ============================================================================

module "function_nsg" {
  count  = local.deploy_function_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "function"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Security rules from variables
  security_rules = var.function_nsg_rules

  # Associate with Function App subnet
  subnet_id = module.function_subnet[0].subnet_id

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
    module.function_subnet
  ]
}
