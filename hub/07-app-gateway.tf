# hub/07-app-gateway.tf
# Application Gateway configuration

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
  sku_name               = var.app_gateway_sku_name
  sku_tier               = var.app_gateway_sku_tier
  enable_autoscale       = var.app_gateway_enable_autoscale
  autoscale_min_capacity = var.app_gateway_min_capacity
  autoscale_max_capacity = var.app_gateway_max_capacity

  # High Availability
  availability_zones = var.app_gateway_zones

  # WAF Configuration
  enable_waf = var.app_gateway_enable_waf
  waf_mode   = var.app_gateway_waf_mode

  # Default Backend Configuration
  backend_address_pools = [
    {
      name         = "default-backend-pool"
      fqdns        = []
      ip_addresses = []
    }
  ]

  backend_http_settings = [
    {
      name                  = "default-http-settings"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
      probe_name            = "default-health-probe"
    }
  ]

  health_probes = [
    {
      name                = "default-health-probe"
      protocol            = "Http"
      path                = "/"
      host                = "127.0.0.1"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
      match_status_codes  = ["200-399"]
    }
  ]

  http_listeners = [
    {
      name               = "default-http-listener"
      frontend_port_name = "http"
      protocol           = "Http"
    }
  ]

  request_routing_rules = [
    {
      name                       = "default-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "default-http-listener"
      backend_address_pool_name  = "default-backend-pool"
      backend_http_settings_name = "default-http-settings"
      priority                   = 100
    }
  ]

  # Monitoring
  enable_diagnostic_settings = local.enable_diagnostics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  depends_on = [
    module.app_gateway_subnet,
    azurerm_log_analytics_workspace.hub
  ]
}
