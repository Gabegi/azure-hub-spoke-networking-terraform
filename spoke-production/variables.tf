# spoke-production/variables.tf
# Input variables for Production Spoke configuration

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
  description = "Environment name (production)"
  default     = "production"

  validation {
    condition     = var.environment == "production"
    error_message = "Environment must be 'production' for this spoke."
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
  description = "Address space for production spoke VNet"
  default     = "10.2.0.0/16"
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
# Service Endpoints Configuration
# ============================================================================

variable "workload_subnet_service_endpoints" {
  type        = list(string)
  description = "Service endpoints for workload subnet"
  default = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry"
  ]
}

variable "data_subnet_service_endpoints" {
  type        = list(string)
  description = "Service endpoints for data subnet"
  default = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
}

variable "app_subnet_service_endpoints" {
  type        = list(string)
  description = "Service endpoints for app subnet"
  default = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# ============================================================================
# Network Security Group Rules
# ============================================================================

variable "workload_nsg_rules" {
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
  description = "Security rules for workload subnet NSG"
  default     = []
}

variable "data_nsg_rules" {
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
  description = "Security rules for data subnet NSG"
  default     = []
}

variable "app_nsg_rules" {
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
  description = "Security rules for app subnet NSG"
  default     = []
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
  description = "Enable resource lock on resource group (recommended for production)"
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
  default     = ""
}
