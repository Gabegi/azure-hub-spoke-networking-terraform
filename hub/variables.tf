# hub/variables.tf
# Input variables for Hub VNet configuration

# ============================================================================
# General Configuration
# ============================================================================

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Environment name (prod or dev)"
}

variable "location" {
  type        = string
  description = "Azure region for hub resources"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for high availability"
  default     = ["1", "2", "3"]
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all hub resources"
  default     = {}
}

# ============================================================================
# Networking
# ============================================================================

variable "hub_address_space" {
  type        = string
  description = "Address space for Hub VNet (e.g., 10.0.0.0/16)"
  default     = "10.0.0.0/16"
}

variable "firewall_subnet" {
  type        = string
  description = "CIDR block for Azure Firewall subnet"
  default     = "10.0.0.0/26"
}

variable "app_gateway_subnet" {
  type        = string
  description = "CIDR block for Application Gateway subnet"
  default     = "10.0.1.0/27"
}

variable "gateway_subnet" {
  type        = string
  description = "CIDR block for VPN/ExpressRoute Gateway subnet"
  default     = "10.0.2.0/26"
}

variable "management_subnet" {
  type        = string
  description = "CIDR block for Management subnet"
  default     = "10.0.3.0/27"
}

# ============================================================================
# Feature Flags
# ============================================================================

variable "deploy_firewall" {
  type        = bool
  description = "Deploy Azure Firewall"
  default     = true
}

variable "deploy_app_gateway" {
  type        = bool
  description = "Deploy Application Gateway"
  default     = true
}

variable "deploy_gateway" {
  type        = bool
  description = "Deploy App Gateway"
  default     = false
}

variable "deploy_management_subnet" {
  type        = bool
  description = "Deploy management subnet"
  default     = true
}

variable "enable_resource_lock" {
  type        = bool
  description = "Enable resource lock to prevent deletion"
  default     = false
}

# ============================================================================
# Firewall Configuration
# ============================================================================

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier (Standard or Premium)"
  default     = "Standard"
}

variable "firewall_threat_intel_mode" {
  type        = string
  description = "Threat Intelligence mode (Off, Alert, Deny)"
  default     = "Alert"
}

variable "firewall_dns_servers" {
  type        = list(string)
  description = "Custom DNS servers for firewall"
  default     = []
}

variable "firewall_network_rules" {
  type = list(object({
    name                  = string
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
  }))
  description = "Network rules for Azure Firewall"
  default     = []
}

# ============================================================================
# Application Gateway Configuration
# ============================================================================

variable "app_gateway_sku_name" {
  type        = string
  description = "Application Gateway SKU name (Standard_v2 or WAF_v2)"
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  type        = string
  description = "Application Gateway SKU tier (Standard_v2 or WAF_v2)"
  default     = "Standard_v2"
}

variable "app_gateway_enable_autoscale" {
  type        = bool
  description = "Enable autoscaling for Application Gateway"
  default     = true
}

variable "app_gateway_min_capacity" {
  type        = number
  description = "Minimum autoscale capacity for Application Gateway"
  default     = 2
}

variable "app_gateway_max_capacity" {
  type        = number
  description = "Maximum autoscale capacity for Application Gateway"
  default     = 10
}

variable "app_gateway_zones" {
  type        = list(string)
  description = "Availability zones for Application Gateway"
  default     = ["1", "2", "3"]
}

variable "app_gateway_enable_waf" {
  type        = bool
  description = "Enable Web Application Firewall on Application Gateway"
  default     = false
}

variable "app_gateway_waf_mode" {
  type        = string
  description = "WAF mode (Detection or Prevention)"
  default     = "Prevention"
}

variable "app_gateway_backend_address_pools" {
  type = list(object({
    name         = string
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
  description = "Backend address pools for Application Gateway"
  default = [{
    name         = "default-backend-pool"
    fqdns        = []
    ip_addresses = []
  }]
}

variable "app_gateway_backend_http_settings" {
  type = list(object({
    name                                = string
    cookie_based_affinity               = string
    port                                = number
    protocol                            = string
    request_timeout                     = number
    probe_name                          = optional(string, null)
    host_name                           = optional(string, null)
    pick_host_name_from_backend_address = optional(bool, false)
    path                                = optional(string, "/")
  }))
  description = "Backend HTTP settings for Application Gateway"
  default = [{
    name                  = "default-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }]
}

variable "app_gateway_health_probes" {
  type = list(object({
    name                                      = string
    protocol                                  = string
    path                                      = string
    interval                                  = number
    timeout                                   = number
    unhealthy_threshold                       = number
    pick_host_name_from_backend_http_settings = optional(bool, false)
    host                                      = optional(string, null)
    match_status_codes                        = optional(list(string), ["200-399"])
  }))
  description = "Health probes for Application Gateway"
  default = [{
    name                = "default-health-probe"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    match_status_codes  = ["200-399"]
  }]
}

variable "app_gateway_http_listeners" {
  type = list(object({
    name                 = string
    frontend_port_name   = string
    protocol             = string
    host_name            = optional(string, null)
    require_sni          = optional(bool, false)
    ssl_certificate_name = optional(string, null)
  }))
  description = "HTTP listeners for Application Gateway"
  default = [{
    name               = "default-http-listener"
    frontend_port_name = "http"
    protocol           = "Http"
  }]
}

variable "app_gateway_request_routing_rules" {
  type = list(object({
    name                       = string
    rule_type                  = string
    http_listener_name         = string
    backend_address_pool_name  = string
    backend_http_settings_name = string
    priority                   = number
  }))
  description = "Request routing rules for Application Gateway"
  default = [{
    name                       = "default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-http-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-http-settings"
    priority                   = 100
  }]
}

# ============================================================================
# Route Table Configuration
# ============================================================================

variable "app_gateway_route_table_routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  }))
  description = "Routes for App Gateway subnet route table"
  default     = []
}

# ============================================================================
# Monitoring
# ============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic settings"
  default     = true
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable NSG flow logs"
  default     = true
}

variable "enable_traffic_analytics" {
  type        = bool
  description = "Enable Traffic Analytics"
  default     = true
}

variable "traffic_analytics_interval" {
  type        = number
  description = "Traffic Analytics interval in minutes (10 or 60)"
  default     = 60
}

variable "log_retention_days" {
  type        = number
  description = "Log retention in days"
  default     = 90
}
