# hub/03-firewall.tf
# Azure Firewall configuration

# ============================================================================
# Azure Firewall
# ============================================================================

module "firewall" {
  count  = var.deploy_firewall ? 1 : 0
  source = "../modules/firewall"

  # Naming (module handles naming internally)
  resource_type = "afw"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.firewall_subnet[0].subnet_id

  # SKU Configuration (NOTE: Basic SKU requires management subnet - upgrade to Standard if needed)
  sku_name = "AZFW_VNet"
  sku_tier = var.firewall_sku_tier

  # Firewall Policy
  create_firewall_policy = true

  # Threat Intelligence
  threat_intel_mode = var.firewall_threat_intel_mode

  # DNS Configuration
  dns_proxy_enabled = var.firewall_sku_tier != "Basic" ? true : false
  dns_servers       = var.firewall_dns_servers

  # High Availability
  availability_zones = var.availability_zones

  # Monitoring
  enable_diagnostic_settings = var.enable_diagnostics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  depends_on = [
    module.firewall_subnet,
    azurerm_log_analytics_workspace.hub
  ]
}
