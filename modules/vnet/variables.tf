# modules/vnet/variables.tf

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

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

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the VNet"
  default     = {}
}
