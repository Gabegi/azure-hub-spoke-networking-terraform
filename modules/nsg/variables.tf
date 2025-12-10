# modules/nsg/variables.tf

# ============================================================================
# Required Variables
# ============================================================================

variable "nsg_name" {
  type        = string
  description = "Name of the network security group"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9_]$", var.nsg_name))
    error_message = "NSG name must be 1-80 characters and contain only alphanumeric, hyphens, underscores, or periods"
  }
}

variable "location" {
  type        = string
  description = "Azure region for the NSG (e.g., westeurope, eastus)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where NSG will be deployed"
}

# ============================================================================
# Security Rules Configuration
# ============================================================================

variable "security_rules" {
  type = list(object({
    name                                       = string
    priority                                   = number
    direction                                  = string
    access                                     = string
    protocol                                   = string
    description                                = optional(string)
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(list(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
  }))
  description = <<-EOT
    List of security rules to create in the NSG.

    Priority: 100-4096 (lower = higher priority)
    Direction: Inbound or Outbound
    Access: Allow or Deny
    Protocol: Tcp, Udp, Icmp, Esp, Ah, or * (all)

    Common Service Tags:
    - Internet: All internet IPs
    - VirtualNetwork: All VNet IPs (includes peered VNets)
    - AzureLoadBalancer: Azure load balancer IPs
    - AzureCloud: All Azure datacenter IPs
    - Storage, Sql, AzureMonitor, etc.
  EOT
  default     = []

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "Priority must be between 100 and 4096"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "Direction must be 'Inbound' or 'Outbound'"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Access must be 'Allow' or 'Deny'"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)
    ])
    error_message = "Protocol must be 'Tcp', 'Udp', 'Icmp', 'Esp', 'Ah', or '*'"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      rule.description == null || length(rule.description) <= 140
    ])
    error_message = "Rule description must be 140 characters or less"
  }
}

# ============================================================================
# NSG Association
# ============================================================================

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to associate with this NSG (optional, for subnet-level NSG)"
  default     = null
}

variable "network_interface_ids" {
  type        = list(string)
  description = "List of network interface IDs to associate with this NSG (optional, for NIC-level NSG)"
  default     = []
}

# ============================================================================
# Application Security Groups
# ============================================================================

variable "application_security_groups" {
  type = list(object({
    name = string
    tags = optional(map(string))
  }))
  description = "List of Application Security Groups to create for logical VM grouping"
  default     = []
}

# ============================================================================
# NSG Flow Logs
# ============================================================================

variable "enable_flow_logs" {
  type        = bool
  description = "Enable NSG flow logs (requires Network Watcher and Storage Account)"
  default     = false
}

variable "network_watcher_name" {
  type        = string
  description = "Name of the Network Watcher (required if enable_flow_logs = true)"
  default     = null

  validation {
    condition     = var.enable_flow_logs == false || var.network_watcher_name != null
    error_message = "network_watcher_name is required when enable_flow_logs is true"
  }
}

variable "network_watcher_resource_group_name" {
  type        = string
  description = "Resource group name of the Network Watcher (required if enable_flow_logs = true)"
  default     = null

  validation {
    condition     = var.enable_flow_logs == false || var.network_watcher_resource_group_name != null
    error_message = "network_watcher_resource_group_name is required when enable_flow_logs is true"
  }
}

variable "flow_log_storage_account_id" {
  type        = string
  description = "Storage Account ID for NSG flow logs (required if enable_flow_logs = true)"
  default     = null

  validation {
    condition     = var.enable_flow_logs == false || var.flow_log_storage_account_id != null
    error_message = "flow_log_storage_account_id is required when enable_flow_logs is true"
  }
}

variable "flow_log_retention_enabled" {
  type        = bool
  description = "Enable retention policy for flow logs"
  default     = true
}

variable "flow_log_retention_days" {
  type        = number
  description = "Number of days to retain flow logs (0 = indefinite)"
  default     = 30

  validation {
    condition     = var.flow_log_retention_days >= 0 && var.flow_log_retention_days <= 365
    error_message = "Retention days must be between 0 and 365"
  }
}

# ============================================================================
# Traffic Analytics
# ============================================================================

variable "enable_traffic_analytics" {
  type        = bool
  description = "Enable Traffic Analytics for NSG flow logs (requires enable_flow_logs = true)"
  default     = false
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

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for Traffic Analytics or diagnostic settings"
  default     = null

  validation {
    condition = (
      (var.enable_traffic_analytics == false && var.enable_diagnostic_settings == false) ||
      var.log_analytics_workspace_id != null
    )
    error_message = "log_analytics_workspace_id is required when enable_traffic_analytics or enable_diagnostic_settings is true"
  }
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Full resource ID of Log Analytics workspace (required for Traffic Analytics)"
  default     = null

  validation {
    condition     = var.enable_traffic_analytics == false || var.log_analytics_workspace_resource_id != null
    error_message = "log_analytics_workspace_resource_id is required when enable_traffic_analytics is true"
  }
}

# ============================================================================
# Diagnostic Settings
# ============================================================================

variable "enable_diagnostic_settings" {
  type        = bool
  description = "Enable diagnostic settings for NSG events and rule counters"
  default     = false
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  type        = map(string)
  description = "Tags to apply to NSG and related resources"
  default     = {}

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Azure supports a maximum of 50 tags per resource"
  }
}
