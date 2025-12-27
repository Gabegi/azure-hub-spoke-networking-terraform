# hub/03-firewall.tf
# Azure Firewall configuration

# ============================================================================
# Naming Modules
# ============================================================================

module "firewall_naming" {
  source = "../modules/naming"

  resource_type = "afw"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "firewall_pip_naming" {
  source = "../modules/naming"

  resource_type = "pip"
  workload      = "firewall"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "firewall_policy_naming" {
  source = "../modules/naming"

  resource_type = "afwp"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Azure Firewall
# ============================================================================

module "firewall" {
  count  = local.deploy_firewall ? 1 : 0
  source = "../modules/firewall"

  firewall_name       = module.firewall_naming.name
  public_ip_name      = module.firewall_pip_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.firewall_subnet.subnet_id

  # SKU Configuration
  sku_name = "AZFW_VNet"
  sku_tier = var.firewall_sku_tier

  # Firewall Policy
  create_firewall_policy = true
  firewall_policy_name   = module.firewall_policy_naming.name

  # Threat Intelligence
  threat_intel_mode = var.firewall_threat_intel_mode

  # DNS Configuration
  dns_proxy_enabled = true
  dns_servers       = var.firewall_dns_servers

  # High Availability
  availability_zones = var.availability_zones

  # Monitoring
  enable_diagnostic_settings = local.enable_diagnostics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  tags = module.firewall_naming.tags

  depends_on = [
    module.firewall_subnet,
    azurerm_log_analytics_workspace.hub
  ]
}
