# modules/route-table/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'route' for Route Table)"
  default     = "route"
}

variable "workload" {
  type        = string
  description = "Workload or application name"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'dev', 'prod', 'staging')"
}

variable "location" {
  type        = string
  description = "Azure region for the route table"
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

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "bgp_route_propagation_enabled" {
  type        = bool
  description = "Enable BGP route propagation (set to false to disable)"
  default     = true
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "List of routes to create in the route table"
  default     = []

  validation {
    condition = alltrue([
      for route in var.routes :
      contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], route.next_hop_type)
    ])
    error_message = "Next hop type must be one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None"
  }
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to associate with this route table (optional)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the route table"
  default     = {}
}
