# modules/subnet/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'snet' for Subnet)"
  default     = "snet"
}

variable "workload" {
  type        = string
  description = "Workload or application name"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'dev', 'prd', 'shared')"
}

variable "location" {
  type        = string
  description = "Azure region for the subnet"
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
# Resource Configuration
# ============================================================================

variable "subnet_name" {
  type        = string
  description = "Optional: Override subnet name (if null, uses naming module)"
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the parent virtual network"
}

variable "address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet (e.g., ['10.0.1.0/24'])"

  validation {
    condition     = length(var.address_prefixes) > 0
    error_message = "At least one address prefix must be specified"
  }
}

variable "service_endpoints" {
  type        = list(string)
  description = "List of service endpoints to enable (e.g., Microsoft.Storage, Microsoft.Sql)"
  default     = []
}

variable "delegation" {
  type = object({
    name         = string
    service_name = string
    actions      = list(string)
  })
  description = "Delegation configuration for specific Azure services"
  default     = null
}

variable "private_endpoint_network_policies_enabled" {
  type        = bool
  description = "Enable or disable network policies for private endpoints"
  default     = true
}

variable "private_link_service_network_policies_enabled" {
  type        = bool
  description = "Enable or disable network policies for private link service"
  default     = true
}
