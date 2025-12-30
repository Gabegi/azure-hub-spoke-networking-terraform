# modules/vnet/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'vnet')"
  default     = "vnet"
}

variable "workload" {
  type        = string
  description = "Workload or application name (e.g., 'hub', 'spoke', 'app')"
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
  description = "Azure region where the VNet will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the VNet (e.g., ['10.0.0.0/16'])"

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be specified"
  }
}

variable "dns_servers" {
  type        = list(string)
  description = "List of custom DNS servers (optional, uses Azure default if not specified)"
  default     = []
}

variable "ddos_protection_plan_id" {
  type        = string
  description = "ID of DDoS protection plan to associate (optional)"
  default     = null
}
