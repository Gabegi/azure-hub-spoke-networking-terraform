# spoke-production/03-nsg.tf
# Network Security Groups for Production Spoke subnets

# ============================================================================
# Workload Subnet NSG
# ============================================================================

module "workload_nsg" {
  count  = local.deploy_workload_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "workload"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Security rules from variables
  security_rules = var.workload_nsg_rules

  # Associate with workload subnet
  subnet_id = module.workload_subnet[0].subnet_id

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
    module.workload_subnet
  ]
}

# ============================================================================
# Data Subnet NSG
# ============================================================================

module "data_nsg" {
  count  = local.deploy_data_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "data"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Security rules from variables
  security_rules = var.data_nsg_rules

  # Associate with data subnet
  subnet_id = module.data_subnet[0].subnet_id

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
    module.data_subnet
  ]
}

# ============================================================================
# Application Subnet NSG
# ============================================================================

module "app_nsg" {
  count  = local.deploy_app_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "app"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  # Security rules from variables
  security_rules = var.app_nsg_rules

  # Associate with app subnet
  subnet_id = module.app_subnet[0].subnet_id

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
    module.app_subnet
  ]
}
