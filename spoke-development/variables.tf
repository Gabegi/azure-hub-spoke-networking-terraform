# spoke-development/variables.tf
# Input variables for Development Spoke configuration

# ============================================================================
# General Configuration
# ============================================================================

variable "environment" {
  type        = string
  description = "Environment name (dev)"
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "Environment must be 'dev' for this spoke."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "spoke_address_space" {
  type        = string
  description = "Address space for development spoke VNet"
  default     = "10.1.0.0/16"
}

# ============================================================================
# Subnet Deployment Flags
# ============================================================================

variable "deploy_workload_subnet" {
  type        = bool
  description = "Deploy workload subnet"
  default     = true
}

variable "deploy_data_subnet" {
  type        = bool
  description = "Deploy data subnet"
  default     = true
}

variable "deploy_app_subnet" {
  type        = bool
  description = "Deploy application subnet"
  default     = true
}

# ============================================================================
# Hub Integration
# ============================================================================

variable "hub_vnet_id" {
  type        = string
  description = "Hub VNet resource ID for peering"
}

variable "hub_vnet_name" {
  type        = string
  description = "Hub VNet name for peering"
}

variable "hub_resource_group_name" {
  type        = string
  description = "Hub resource group name"
}

variable "hub_firewall_private_ip" {
  type        = string
  description = "Hub Firewall private IP for route table next hop"
  default     = null
}

# ============================================================================
# Route Table Configuration
# ============================================================================

variable "enable_forced_tunneling" {
  type        = bool
  description = "Enable forced tunneling through hub firewall"
  default     = true
}

variable "route_table_routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  }))
  description = "Routes for spoke subnet route tables"
  default     = []
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

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostics and Traffic Analytics"
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Log Analytics workspace resource ID for Traffic Analytics"
  default     = null
}

variable "storage_account_id" {
  type        = string
  description = "Storage account ID for NSG flow logs"
  default     = null
}

# ============================================================================
# Resource Lock Configuration
# ============================================================================

variable "enable_resource_lock" {
  type        = bool
  description = "Enable resource lock on resource group"
  default     = false
}

variable "lock_level" {
  type        = string
  description = "Lock level (CanNotDelete or ReadOnly)"
  default     = "CanNotDelete"

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Lock level must be CanNotDelete or ReadOnly."
  }
}

# ============================================================================
# VM Configuration
# ============================================================================

variable "vm_admin_ssh_public_key" {
  type        = string
  description = "SSH public key for VM admin user"
  default     = null
}
