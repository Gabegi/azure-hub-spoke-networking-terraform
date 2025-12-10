# modules/subnet/variables.tf

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
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
