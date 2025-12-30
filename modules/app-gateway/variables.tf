# modules/app-gateway/variables.tf
# Application Gateway module variables

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'agw' for App Gateway)"
  default     = "agw"
}

variable "workload" {
  type        = string
  description = "Workload or application name (e.g., 'hub', 'app')"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'dev', 'prod', 'staging')"
}

variable "instance" {
  type        = string
  description = "Instance number (e.g., '001', '002')"
  default     = "001"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to merge with module-generated tags"
  default     = {}
}

# ============================================================================
# Required Variables
# ============================================================================

variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for Application Gateway"
}

# SKU Configuration
variable "sku_name" {
  type        = string
  description = "SKU name for Application Gateway"
  default     = "Standard_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_name)
    error_message = "SKU name must be Standard_v2 or WAF_v2."
  }
}

variable "sku_tier" {
  type        = string
  description = "SKU tier for Application Gateway"
  default     = "Standard_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_tier)
    error_message = "SKU tier must be Standard_v2 or WAF_v2."
  }
}

variable "capacity" {
  type        = number
  description = "Number of instances (1-125). Use null for autoscaling."
  default     = null

  validation {
    condition     = var.capacity == null ? true : (var.capacity >= 1 && var.capacity <= 125)
    error_message = "Capacity must be between 1 and 125, or null for autoscaling."
  }
}

# Autoscaling
variable "enable_autoscale" {
  type        = bool
  description = "Enable autoscaling for Application Gateway"
  default     = true
}

variable "autoscale_min_capacity" {
  type        = number
  description = "Minimum autoscale capacity"
  default     = 2

  validation {
    condition     = var.autoscale_min_capacity >= 1 && var.autoscale_min_capacity <= 125
    error_message = "Minimum capacity must be between 1 and 125."
  }
}

variable "autoscale_max_capacity" {
  type        = number
  description = "Maximum autoscale capacity"
  default     = 10

  validation {
    condition     = var.autoscale_max_capacity >= 2 && var.autoscale_max_capacity <= 125
    error_message = "Maximum capacity must be between 2 and 125."
  }
}

# Availability Zones
variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for Application Gateway"
  default     = ["1", "2", "3"]
}

# WAF Configuration
variable "enable_waf" {
  type        = bool
  description = "Enable Web Application Firewall"
  default     = false
}

variable "waf_mode" {
  type        = string
  description = "WAF mode (Detection or Prevention)"
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be Detection or Prevention."
  }
}

variable "waf_rule_set_version" {
  type        = string
  description = "WAF rule set version"
  default     = "3.2"
}

variable "waf_file_upload_limit_mb" {
  type        = number
  description = "Maximum file upload size in MB"
  default     = 100
}

variable "waf_max_request_body_size_kb" {
  type        = number
  description = "Maximum request body size in KB"
  default     = 128
}

# Backend Configuration
variable "backend_address_pools" {
  type = list(object({
    name         = string
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
  description = "Backend address pools configuration"
  default = [{
    name         = "default-backend-pool"
    fqdns        = []
    ip_addresses = []
  }]
}

variable "backend_http_settings" {
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
  description = "Backend HTTP settings configuration"
  default = [{
    name                  = "default-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }]
}

# Frontend Configuration
variable "frontend_port_http" {
  type        = number
  description = "Frontend HTTP port"
  default     = 80
}

variable "frontend_port_https" {
  type        = number
  description = "Frontend HTTPS port"
  default     = 443
}

# Health Probes
variable "health_probes" {
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
  description = "Health probe configuration"
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

# HTTP Listeners
variable "http_listeners" {
  type = list(object({
    name                 = string
    frontend_port_name   = string
    protocol             = string
    host_name            = optional(string, null)
    require_sni          = optional(bool, false)
    ssl_certificate_name = optional(string, null)
  }))
  description = "HTTP listener configuration"
  default = [{
    name               = "default-http-listener"
    frontend_port_name = "http"
    protocol           = "Http"
  }]
}

# Request Routing Rules
variable "request_routing_rules" {
  type = list(object({
    name                       = string
    rule_type                  = string
    http_listener_name         = string
    backend_address_pool_name  = string
    backend_http_settings_name = string
    priority                   = number
  }))
  description = "Request routing rules configuration"
  default = [{
    name                       = "default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-http-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-http-settings"
    priority                   = 100
  }]
}

# Monitoring
variable "enable_diagnostic_settings" {
  type        = bool
  description = "Enable diagnostic settings"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostics"
  default     = null
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
