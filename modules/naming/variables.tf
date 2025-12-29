# modules/naming/variables.tf

variable "resource_type" {
  type        = string
  description = "Resource type abbreviation following Microsoft conventions"

  validation {
    condition = contains([
      "vnet",    # Virtual Network
      "snet",    # Subnet
      "nsg",     # Network Security Group
      "afw",     # Azure Firewall
      "afwp",    # Azure Firewall Policy
      "bas",     # Bastion
      "route",   # Route Table
      "pip",     # Public IP
      "log",     # Log Analytics
      "st",      # Storage Account
      "rg",      # Resource Group
      "peer",    # VNet Peering
      "vm",      # Virtual Machine
      "nic",     # Network Interface
      "agw",     # Application Gateway
      "aci"      # Azure Container Instance
    ], var.resource_type)
    error_message = "Must use approved Microsoft abbreviations"
  }
}

variable "workload" {
  type        = string
  description = "Workload identifier (hub, spoke, web, app, data)"
}

variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["prod", "dev", "production"], var.environment)
    error_message = "Environment must be prod, dev, or production"
  }
}

variable "location" {
  type        = string
  description = "Azure region (eastus, westeurope, etc.)"
  default     = "westeurope"
}

variable "instance" {
  type        = string
  description = "Instance number for resource uniqueness (001, 002, etc.)"
  default     = "001"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number (e.g., 001, 002)"
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Additional tags to merge with standard tags"
  default     = {}
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing purposes"
  default     = "IT-Network"
}
