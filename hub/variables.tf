# hub/variables.tf
# Input variables for Hub VNet configuration

# ============================================================================
# General Configuration
# ============================================================================

variable "environment" {
  type        = string
  description = "Environment name (prod, staging, dev)"
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

# ============================================================================
# Feature Flags
# ============================================================================

variable "deploy_firewall" {
  type        = bool
  description = "Deploy Azure Firewall"
  default     = true
}

variable "deploy_bastion" {
  type        = bool
  description = "Deploy Azure Bastion"
  default     = true
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

# ============================================================================
# Bastion Configuration
# ============================================================================

variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU (Basic or Standard)"
  default     = "Standard"
}

variable "bastion_scale_units" {
  type        = number
  description = "Number of scale units for Bastion (2-50)"
  default     = 2
}

variable "bastion_copy_paste_enabled" {
  type        = bool
  description = "Enable copy/paste for Bastion"
  default     = true
}

variable "bastion_file_copy_enabled" {
  type        = bool
  description = "Enable file copy (Standard SKU only)"
  default     = false
}

variable "bastion_ip_connect_enabled" {
  type        = bool
  description = "Enable IP connect (Standard SKU only)"
  default     = false
}

variable "bastion_tunneling_enabled" {
  type        = bool
  description = "Enable tunneling (Standard SKU only)"
  default     = false
}

variable "bastion_zones" {
  type        = list(string)
  description = "Availability zones for Azure Bastion"
  default     = ["1", "2", "3"]
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

# ============================================================================
# Network Security Group Rules
# ============================================================================

variable "management_nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = string
  }))
  description = "Security rules for Management subnet NSG"
  default     = []
}

variable "app_gateway_nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = string
  }))
  description = "Security rules for Application Gateway subnet NSG"
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

# ============================================================================
# External References
# ============================================================================

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID"
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Log Analytics workspace resource ID"
  default     = null
}

variable "storage_account_id" {
  type        = string
  description = "Storage account ID for flow logs"
  default     = null
}
