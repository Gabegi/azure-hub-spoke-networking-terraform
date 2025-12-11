# main.tf
# Main orchestration file for Azure Hub-Spoke Network Topology

# ============================================================================
# Hub VNet Module
# ============================================================================

module "hub" {
  source = "./hub"

  # General Configuration
  environment = var.environment
  location    = var.location
  tags        = var.tags

  # Network Configuration
  hub_address_space = var.hub_address_space

  # Feature Flags
  deploy_firewall = var.deploy_firewall
  deploy_bastion  = var.deploy_bastion
  deploy_gateway  = var.deploy_gateway
  deploy_mgmt     = var.deploy_management_subnet

  # Firewall Configuration
  firewall_sku_tier          = var.firewall_sku_tier
  firewall_threat_intel_mode = var.firewall_threat_intel_mode
  firewall_dns_servers       = var.firewall_dns_servers

  # Bastion Configuration
  bastion_sku                 = var.bastion_sku
  bastion_scale_units         = var.bastion_scale_units
  bastion_copy_paste_enabled  = var.bastion_copy_paste_enabled
  bastion_file_copy_enabled   = var.bastion_file_copy_enabled
  bastion_ip_connect_enabled  = var.bastion_ip_connect_enabled
  bastion_tunneling_enabled   = var.bastion_tunneling_enabled

  # High Availability
  availability_zones = var.availability_zones

  # Monitoring Configuration
  enable_diagnostics                  = var.enable_diagnostics
  enable_flow_logs                    = var.enable_flow_logs
  enable_traffic_analytics            = var.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_id                  = azurerm_storage_account.flow_logs.id

  # Resource Lock
  enable_resource_lock = var.environment == "prod" ? var.enable_resource_lock : false

  depends_on = [
    azurerm_log_analytics_workspace.main,
    azurerm_storage_account.flow_logs
  ]
}

# ============================================================================
# Staging Spoke VNet Module
# ============================================================================

module "spoke_staging" {
  count  = var.deploy_staging_spoke ? 1 : 0
  source = "./spoke-staging"

  # General Configuration
  environment = "staging"
  location    = var.location
  tags        = var.tags

  # Network Configuration
  spoke_address_space = var.staging_address_space

  # Subnet Deployment Flags
  deploy_workload_subnet = var.deploy_staging_workload_subnet
  deploy_data_subnet     = var.deploy_staging_data_subnet
  deploy_app_subnet      = var.deploy_staging_app_subnet

  # Hub Integration
  hub_vnet_id               = module.hub.vnet_id
  hub_vnet_name             = module.hub.vnet_name
  hub_resource_group_name   = module.hub.resource_group_name
  hub_firewall_private_ip   = module.hub.firewall_private_ip

  # Route Table Configuration
  enable_forced_tunneling = var.enable_forced_tunneling

  # Monitoring Configuration
  enable_diagnostics                  = var.enable_diagnostics
  enable_flow_logs                    = var.enable_flow_logs
  enable_traffic_analytics            = var.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_id                  = azurerm_storage_account.flow_logs.id

  # Resource Lock
  enable_resource_lock = false

  depends_on = [
    module.hub,
    azurerm_log_analytics_workspace.main,
    azurerm_storage_account.flow_logs
  ]
}

# ============================================================================
# Production Spoke VNet Module
# ============================================================================

module "spoke_production" {
  count  = var.deploy_production_spoke ? 1 : 0
  source = "./spoke-production"

  # General Configuration
  environment = "prod"
  location    = var.location
  tags        = var.tags

  # Network Configuration
  spoke_address_space = var.production_address_space

  # Subnet Deployment Flags
  deploy_workload_subnet = var.deploy_production_workload_subnet
  deploy_data_subnet     = var.deploy_production_data_subnet
  deploy_app_subnet      = var.deploy_production_app_subnet

  # Hub Integration
  hub_vnet_id               = module.hub.vnet_id
  hub_vnet_name             = module.hub.vnet_name
  hub_resource_group_name   = module.hub.resource_group_name
  hub_firewall_private_ip   = module.hub.firewall_private_ip

  # Route Table Configuration
  enable_forced_tunneling = var.enable_forced_tunneling

  # Monitoring Configuration
  enable_diagnostics                  = var.enable_diagnostics
  enable_flow_logs                    = var.enable_flow_logs
  enable_traffic_analytics            = var.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_id                  = azurerm_storage_account.flow_logs.id

  # Resource Lock
  enable_resource_lock = var.enable_resource_lock

  depends_on = [
    module.hub,
    azurerm_log_analytics_workspace.main,
    azurerm_storage_account.flow_logs
  ]
}
