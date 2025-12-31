# hub/04-bastion.tf
# Azure Bastion configuration

# ============================================================================
# Azure Bastion
# ============================================================================

module "bastion" {
  count  = local.deploy_bastion ? 1 : 0
  source = "../modules/bastion"

  # Naming (module handles naming internally)
  resource_type = "bas"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.bastion_subnet[0].subnet_id

  # SKU Configuration
  sku         = var.bastion_sku
  scale_units = var.bastion_scale_units

  # Features
  copy_paste_enabled = var.bastion_copy_paste_enabled
  file_copy_enabled  = var.bastion_file_copy_enabled
  ip_connect_enabled = var.bastion_ip_connect_enabled
  tunneling_enabled  = var.bastion_tunneling_enabled

  # High Availability
  availability_zones = var.bastion_zones

  # Monitoring
  enable_diagnostic_settings = local.enable_diagnostics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  depends_on = [
    module.bastion_subnet,
    azurerm_log_analytics_workspace.hub
  ]
}
