# hub/04-bastion.tf
# Azure Bastion configuration

# ============================================================================
# Naming Modules
# ============================================================================

module "bastion_naming" {
  source = "../modules/naming"

  resource_type = "bas"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "bastion_pip_naming" {
  source = "../modules/naming"

  resource_type = "pip"
  workload      = "bastion"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Azure Bastion
# ============================================================================

module "bastion" {
  count  = local.deploy_bastion ? 1 : 0
  source = "../modules/bastion"

  bastion_name        = module.bastion_naming.name
  public_ip_name      = module.bastion_pip_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.bastion_subnet.subnet_id

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
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = module.bastion_naming.tags

  depends_on = [
    module.bastion_subnet
  ]
}
