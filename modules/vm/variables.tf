# modules/vm/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'vm' for Virtual Machine)"
  default     = "vm"
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
  description = "Azure region for the VM"
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

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the VM NIC will be attached"
}

# ============================================================================
# VM Configuration
# ============================================================================

variable "vm_size" {
  type        = string
  description = "Size of the Virtual Machine"
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for VM authentication"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the VM and Public IP"
  default     = []
}

variable "enable_system_assigned_identity" {
  type        = bool
  description = "Enable system-assigned managed identity"
  default     = false
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "enable_public_ip" {
  type        = bool
  description = "Enable public IP for the VM"
  default     = false
}

variable "private_ip_address_allocation" {
  type        = string
  description = "Private IP allocation method (Dynamic or Static)"
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "Private IP allocation must be Dynamic or Static."
  }
}

variable "private_ip_address" {
  type        = string
  description = "Static private IP address (only used if private_ip_address_allocation is Static)"
  default     = null
}

# ============================================================================
# OS Disk Configuration
# ============================================================================

variable "os_disk_caching" {
  type        = string
  description = "OS disk caching type"
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "OS disk caching must be None, ReadOnly, or ReadWrite."
  }
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "OS disk storage account type"
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.os_disk_storage_account_type)
    error_message = "OS disk storage account type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS."
  }
}

variable "os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 30
}

# ============================================================================
# OS Image Configuration
# ============================================================================

variable "source_image_publisher" {
  type        = string
  description = "OS image publisher"
  default     = "Canonical"
}

variable "source_image_offer" {
  type        = string
  description = "OS image offer"
  default     = "0001-com-ubuntu-server-jammy"
}

variable "source_image_sku" {
  type        = string
  description = "OS image SKU"
  default     = "22_04-lts-gen2"
}

variable "source_image_version" {
  type        = string
  description = "OS image version"
  default     = "latest"
}
