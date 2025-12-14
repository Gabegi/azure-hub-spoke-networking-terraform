# modules/app-gateway/main.tf
# Application Gateway resource

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = var.tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.app_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.availability_zones

  # SKU Configuration
  sku {
    name = var.sku_name
    tier = var.sku_tier
    capacity = var.enable_autoscale ? null : var.capacity
  }

  # Autoscale Configuration
  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscale ? [1] : []
    content {
      min_capacity = var.autoscale_min_capacity
      max_capacity = var.autoscale_max_capacity
    }
  }

  # Gateway IP Configuration
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  # Frontend IP Configuration
  frontend_ip_configuration {
    name                 = "frontend-public-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  # Frontend Ports
  frontend_port {
    name = "http"
    port = var.frontend_port_http
  }

  frontend_port {
    name = "https"
    port = var.frontend_port_https
  }

  # Backend Address Pools
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  # Backend HTTP Settings
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      probe_name                          = backend_http_settings.value.probe_name
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      path                                = backend_http_settings.value.path
    }
  }

  # Health Probes
  dynamic "probe" {
    for_each = var.health_probes
    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      host                                      = probe.value.host

      match {
        status_code = probe.value.match_status_codes
      }
    }
  }

  # HTTP Listeners
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = "frontend-public-ip"
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
    }
  }

  # Request Routing Rules
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = request_routing_rule.value.rule_type
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      priority                   = request_routing_rule.value.priority
    }
  }

  # WAF Configuration
  dynamic "waf_configuration" {
    for_each = var.enable_waf && var.sku_tier == "WAF_v2" ? [1] : []
    content {
      enabled                  = true
      firewall_mode            = var.waf_mode
      rule_set_type            = "OWASP"
      rule_set_version         = var.waf_rule_set_version
      file_upload_limit_mb     = var.waf_file_upload_limit_mb
      request_body_check       = true
      max_request_body_size_kb = var.waf_max_request_body_size_kb
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.app_gateway_name}"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
