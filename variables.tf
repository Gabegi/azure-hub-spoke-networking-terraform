# variables.tf
# Root-level input variables for Hub-Spoke Network Topology

# ============================================================================
# General Configuration
# ============================================================================

variable "environment" {
  type        = string
  description = "Environment name (prod, staging, dev)"
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be prod, staging, or dev."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "westeurope"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Project     = "HubSpokeNetwork"
    ManagedBy   = "Terraform"
    Owner       = "Platform Team"
  }
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "hub_address_space" {
  type        = string
  description = "Address space for hub VNet"
  default     = "10.0.0.0/16"
}

variable "staging_address_space" {
  type        = string
  description = "Address space for staging spoke VNet"
  default     = "10.1.0.0/16"
}

variable "production_address_space" {
  type        = string
  description = "Address space for production spoke VNet"
  default     = "10.2.0.0/16"
}

# ============================================================================
# Hub Feature Flags
# ============================================================================

variable "deploy_firewall" {
  type        = bool
  description = "Deploy Azure Firewall in hub"
  default     = true
}

variable "deploy_bastion" {
  type        = bool
  description = "Deploy Azure Bastion in hub"
  default     = true
}

variable "deploy_gateway" {
  type        = bool
  description = "Deploy VPN/ExpressRoute gateway subnet in hub"
  default     = false
}

variable "deploy_management_subnet" {
  type        = bool
  description = "Deploy management subnet in hub"
  default     = true
}

# ============================================================================
# Spoke Deployment Flags
# ============================================================================

variable "deploy_staging_spoke" {
  type        = bool
  description = "Deploy staging spoke VNet"
  default     = true
}

variable "deploy_production_spoke" {
  type        = bool
  description = "Deploy production spoke VNet"
  default     = true
}

# Staging Spoke Subnets
variable "deploy_staging_workload_subnet" {
  type        = bool
  description = "Deploy workload subnet in staging spoke"
  default     = true
}

variable "deploy_staging_data_subnet" {
  type        = bool
  description = "Deploy data subnet in staging spoke"
  default     = true
}

variable "deploy_staging_app_subnet" {
  type        = bool
  description = "Deploy application subnet in staging spoke"
  default     = true
}

# Production Spoke Subnets
variable "deploy_production_workload_subnet" {
  type        = bool
  description = "Deploy workload subnet in production spoke"
  default     = true
}

variable "deploy_production_data_subnet" {
  type        = bool
  description = "Deploy data subnet in production spoke"
  default     = true
}

variable "deploy_production_app_subnet" {
  type        = bool
  description = "Deploy application subnet in production spoke"
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
    error_message = "Firewall SKU tier must be Standard or Premium."
  }
}

variable "firewall_threat_intel_mode" {
  type        = string
  description = "Threat intelligence mode (Alert, Deny, Off)"
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.firewall_threat_intel_mode)
    error_message = "Threat intel mode must be Alert, Deny, or Off."
  }
}

variable "firewall_dns_servers" {
  type        = list(string)
  description = "Custom DNS servers for Azure Firewall"
  default     = []
}

# ============================================================================
# Azure Bastion Configuration (Environment-Specific)
# ============================================================================

# Environment-specific Bastion configurations
# Production: Standard SKU with all features for maximum capability
# Dev/Test: Basic SKU with minimal features for cost optimization
variable "bastion_config" {
  type = map(object({
    sku                = string
    scale_units        = number
    copy_paste_enabled = bool
    file_copy_enabled  = bool
    ip_connect_enabled = bool
    tunneling_enabled  = bool
    zones              = list(string)
  }))
  description = "Environment-specific Azure Bastion configurations"
  default = {
    prod = {
      sku                = "Standard"
      scale_units        = 2
      copy_paste_enabled = true
      file_copy_enabled  = true
      ip_connect_enabled = true
      tunneling_enabled  = true
      zones              = ["1", "2", "3"]
    }
    staging = {
      sku                = "Basic"
      scale_units        = 2
      copy_paste_enabled = true
      file_copy_enabled  = false
      ip_connect_enabled = false
      tunneling_enabled  = false
      zones              = ["1"]
    }
    dev = {
      sku                = "Basic"
      scale_units        = 2
      copy_paste_enabled = true
      file_copy_enabled  = false
      ip_connect_enabled = false
      tunneling_enabled  = false
      zones              = ["1"]
    }
  }
}

# Manual override options (optional - will override environment-specific defaults)
variable "bastion_sku_override" {
  type        = string
  description = "Override Bastion SKU (Basic or Standard). Leave null to use environment default."
  default     = null

  validation {
    condition     = var.bastion_sku_override == null || contains(["Basic", "Standard"], var.bastion_sku_override)
    error_message = "Bastion SKU must be Basic or Standard."
  }
}

variable "bastion_scale_units_override" {
  type        = number
  description = "Override Bastion scale units (2-50, Standard SKU only). Leave null to use environment default."
  default     = null

  validation {
    condition     = var.bastion_scale_units_override == null || (var.bastion_scale_units_override >= 2 && var.bastion_scale_units_override <= 50)
    error_message = "Bastion scale units must be between 2 and 50."
  }
}

variable "bastion_zones_override" {
  type        = list(string)
  description = "Override availability zones for Bastion. Leave null to use environment default."
  default     = null
}

# ============================================================================
# High Availability
# ============================================================================

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for zone-redundant resources"
  default     = ["1", "2", "3"]
}

# ============================================================================
# Route Table Configuration
# ============================================================================

variable "enable_forced_tunneling" {
  type        = bool
  description = "Enable forced tunneling through hub firewall for spoke VNets"
  default     = true
}

# ============================================================================
# Monitoring and Diagnostics
# ============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic settings for all resources"
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
  description = "Traffic Analytics processing interval in minutes"
  default     = 10

  validation {
    condition     = contains([10, 60], var.traffic_analytics_interval)
    error_message = "Traffic Analytics interval must be 10 or 60 minutes."
  }
}

variable "log_analytics_sku" {
  type        = string
  description = "Log Analytics workspace SKU"
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerNode", "PerGB2018", "Standalone", "Standard", "Premium"], var.log_analytics_sku)
    error_message = "Invalid Log Analytics SKU."
  }
}

variable "log_analytics_retention_days" {
  type        = number
  description = "Log Analytics workspace retention in days"
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "storage_replication_type" {
  type        = string
  description = "Storage account replication type for flow logs"
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Invalid storage replication type."
  }
}

# ============================================================================
# Resource Lock Configuration
# ============================================================================

variable "enable_resource_lock" {
  type        = bool
  description = "Enable resource locks on production resources"
  default     = true
}
