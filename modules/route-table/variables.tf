# modules/route-table/variables.tf

variable "route_table_name" {
  type        = string
  description = "Name of the route table"
}

variable "location" {
  type        = string
  description = "Azure region for the route table"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "disable_bgp_route_propagation" {
  type        = bool
  description = "Disable BGP route propagation"
  default     = false
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
