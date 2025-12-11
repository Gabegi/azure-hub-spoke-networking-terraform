# variables.tf
# Input variables for Azure Hub-Spoke Network configuration

# ============================================================================
# General Configuration
# ============================================================================

variable "environment" {
  type        = string
  description = "Environment name (prod, staging, dev)"
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be 'prod', 'staging', or 'dev'"
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for high availability (e.g., ['1', '2', '3'])"
  default     = ["1", "2", "3"]
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    Project     = "HubSpokeNetwork"
    ManagedBy   = "Terraform"
    Owner       = "NetworkTeam"
    CostCenter  = "IT-Network"
  }
}

# ============================================================================
# Network Address Spaces
# ============================================================================

variable "hub_address_space" {
  type        = string
  description = "Address space for Hub VNet"
  default     = "10.0.0.0/16"
}

variable "staging_address_space" {
  type        = string
  description = "Address space for Staging Spoke VNet"
  default     = "10.1.0.0/16"
}

variable "production_address_space" {
  type        = string
  description = "Address space for Production Spoke VNet"
  default     = "10.2.0.0/16"
}

# ============================================================================
# Resource Protection
# ============================================================================

variable "enable_resource_lock" {
  type        = bool
  description = "Enable resource lock on production resources to prevent accidental deletion"
  default     = false
}

# ============================================================================
# Feature Flags - Hub Resources
# ============================================================================

variable "deploy_firewall" {
  type        = bool
  description = "Deploy Azure Firewall in hub (recommended for production)"
  default     = true
}

variable "deploy_bastion" {
  type        = bool
  description = "Deploy Azure Bastion for secure VM access (recommended)"
  default     = true
}

variable "deploy_vpn_gateway" {
  type        = bool
  description = "Deploy VPN Gateway for hybrid connectivity (optional)"
  default     = false
}

variable "deploy_management_subnet" {
  type        = bool
  description = "Deploy management subnet for jump boxes and tools (optional)"
  default     = true
}

# ============================================================================
# Azure Firewall Configuration
# ============================================================================

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier (Standard or Premium)"
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall SKU tier must be 'Standard' or 'Premium'"
  }
}

variable "firewall_threat_intel_mode" {
  type        = string
  description = "Threat Intelligence mode (Off, Alert, or Deny)"
  default     = "Alert"

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.firewall_threat_intel_mode)
    error_message = "Threat Intel mode must be 'Off', 'Alert', or 'Deny'"
  }
}

variable "firewall_dns_servers" {
  type        = list(string)
  description = "Custom DNS servers for firewall (empty = use Azure DNS)"
  default     = []
}

# ============================================================================
# Azure Bastion Configuration
# ============================================================================

variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU (Basic or Standard)"
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU must be 'Basic' or 'Standard'"
  }
}

variable "bastion_scale_units" {
  type        = number
  description = "Number of scale units for Bastion (2-50, Standard SKU only)"
  default     = 2

  validation {
    condition     = var.bastion_scale_units >= 2 && var.bastion_scale_units <= 50
    error_message = "Bastion scale units must be between 2 and 50"
  }
}

variable "bastion_copy_paste_enabled" {
  type        = bool
  description = "Enable copy/paste for Bastion sessions"
  default     = true
}

variable "bastion_file_copy_enabled" {
  type        = bool
  description = "Enable file copy for Bastion (Standard SKU only)"
  default     = false
}

variable "bastion_ip_connect_enabled" {
  type        = bool
  description = "Enable IP-based connection for Bastion (Standard SKU only)"
  default     = false
}

variable "bastion_tunneling_enabled" {
  type        = bool
  description = "Enable tunneling for Bastion (Standard SKU only)"
  default     = false
}

# ============================================================================
# Monitoring and Logging
# ============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic settings (logs and metrics)"
  default     = true
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable NSG flow logs"
  default     = true
}

variable "enable_traffic_analytics" {
  type        = bool
  description = "Enable Traffic Analytics for NSG flow logs"
  default     = true
}

variable "traffic_analytics_interval" {
  type        = number
  description = "Traffic Analytics processing interval in minutes (10 or 60)"
  default     = 60

  validation {
    condition     = contains([10, 60], var.traffic_analytics_interval)
    error_message = "Traffic Analytics interval must be 10 or 60 minutes"
  }
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain logs (0 = indefinite)"
  default     = 90

  validation {
    condition     = var.log_retention_days >= 0 && var.log_retention_days <= 365
    error_message = "Log retention days must be between 0 and 365"
  }
}
