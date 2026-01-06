# hub/06-app-gateway.tf
# Application Gateway for routing traffic to spoke workloads

# ============================================================================
# Application Gateway
# ============================================================================

module "app_gateway" {
  count  = local.deploy_app_gateway ? 1 : 0
  source = "../modules/app-gateway"

  # Naming (module handles naming internally)
  resource_type = "agw"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.app_gateway_subnet[0].subnet_id

  # SKU Configuration
  sku_name = var.app_gateway_sku_name
  sku_tier = var.app_gateway_sku_tier

  # Autoscaling
  enable_autoscale        = var.app_gateway_enable_autoscale
  autoscale_min_capacity  = var.app_gateway_min_capacity
  autoscale_max_capacity  = var.app_gateway_max_capacity
  availability_zones      = var.app_gateway_zones

  # WAF Configuration
  enable_waf = var.app_gateway_enable_waf
  waf_mode   = var.app_gateway_waf_mode

  # Backend Configuration
  backend_address_pools    = var.app_gateway_backend_address_pools
  backend_http_settings    = var.app_gateway_backend_http_settings
  health_probes            = var.app_gateway_health_probes
  http_listeners           = var.app_gateway_http_listeners
  request_routing_rules    = var.app_gateway_request_routing_rules

  # Monitoring
  enable_diagnostic_settings = local.enable_diagnostics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  depends_on = [
    module.app_gateway_subnet,
    azurerm_log_analytics_workspace.hub
  ]
}
