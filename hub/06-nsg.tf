# hub/05-nsg.tf
# Network Security Groups for Hub subnets

# ============================================================================
# Management Subnet NSG (Optional - Future Use)
# ============================================================================

module "management_nsg" {
  count  = local.deploy_mgmt ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "management"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name

  # Security rules from variables
  security_rules = var.management_nsg_rules

  # Associate with management subnet
  subnet_id = module.management_subnet[0].subnet_id

  # Flow Logs
  enable_flow_logs                    = local.enable_flow_logs
  network_watcher_name                = local.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = local.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = local.enable_flow_logs ? azurerm_storage_account.flow_logs[0].id : null

  # Traffic Analytics
  enable_traffic_analytics            = local.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = azurerm_log_analytics_workspace.hub.id
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.hub.id

  # Diagnostic Settings
  enable_diagnostic_settings = local.enable_diagnostics

  depends_on = [
    module.management_subnet,
    azurerm_log_analytics_workspace.hub,
    azurerm_storage_account.flow_logs
  ]
}
