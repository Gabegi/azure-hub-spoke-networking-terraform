# modules/bastion/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'bas' for Bastion)"
  default     = "bas"
}

variable "workload" {
  type        = string
  description = "Workload or application name (e.g., 'hub')"
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
  description = "Azure region for Bastion (e.g., westeurope, eastus)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where Bastion will be deployed"
}

variable "subnet_id" {
  type        = string
  description = "ID of the AzureBastionSubnet (must be named exactly 'AzureBastionSubnet' and at least /26)"

  validation {
    condition     = can(regex("/subnets/AzureBastionSubnet$", var.subnet_id))
    error_message = "Subnet must be named 'AzureBastionSubnet' (case-sensitive Azure requirement)"
  }
}

# ============================================================================
# SKU and Scaling Configuration
# ============================================================================

variable "sku" {
  type        = string
  description = <<-EOT
    SKU for Azure Bastion:
    - Basic: Fixed 2 scale units, basic features only
    - Standard: Scalable (2-50 units), advanced features (file copy, IP connect, tunneling)
  EOT
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU must be 'Basic' or 'Standard'"
  }
}

variable "scale_units" {
  type        = number
  description = <<-EOT
    Number of scale units for Bastion (2-50).
    Each scale unit supports:
    - 2 concurrent RDP sessions
    - 10 concurrent SSH sessions
    Note: Only applies to Standard SKU. Basic SKU is fixed at 2 units.
  EOT
  default     = 2

  validation {
    condition     = var.scale_units >= 2 && var.scale_units <= 50
    error_message = "Scale units must be between 2 and 50"
  }
}

# ============================================================================
# Feature Flags (Standard SKU Only)
# ============================================================================

variable "copy_paste_enabled" {
  type        = bool
  description = "Enable copy/paste between local machine and remote session (both Basic and Standard)"
  default     = true
}

variable "file_copy_enabled" {
  type        = bool
  description = "Enable file upload/download (Standard SKU only, ignored for Basic)"
  default     = false
}

variable "ip_connect_enabled" {
  type        = bool
  description = "Enable connection via private IP address instead of VM name (Standard SKU only)"
  default     = false
}

variable "shareable_link_enabled" {
  type        = bool
  description = "Enable shareable links for VM access (Standard SKU only, security consideration)"
  default     = false
}

variable "tunneling_enabled" {
  type        = bool
  description = "Enable native client support for RDP/SSH tunneling (Standard SKU only)"
  default     = false
}

# ============================================================================
# High Availability and Monitoring
# ============================================================================

variable "availability_zones" {
  type        = list(string)
  description = <<-EOT
    Availability zones for Bastion public IP (e.g., ["1", "2", "3"]).
    Provides zone redundancy for high availability.
    Note: Not all regions support availability zones.
  EOT
  default     = null

  validation {
    condition = var.availability_zones == null ? true : alltrue([
      for zone in var.availability_zones : contains(["1", "2", "3"], zone)
    ])
    error_message = "Availability zones must be null or contain only '1', '2', or '3'"
  }
}

variable "enable_diagnostic_settings" {
  type        = bool
  description = "Enable diagnostic settings for Bastion (audit logs and metrics)"
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic settings (required if enable_diagnostic_settings = true)"
  default     = null

  validation {
    condition     = var.enable_diagnostic_settings == false || var.log_analytics_workspace_id != null
    error_message = "log_analytics_workspace_id is required when enable_diagnostic_settings is true"
  }
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  type        = map(string)
  description = "Tags to apply to Bastion resources (best practice: include Owner, CostCenter, Environment)"
  default     = {}

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Azure supports a maximum of 50 tags per resource"
  }
}
