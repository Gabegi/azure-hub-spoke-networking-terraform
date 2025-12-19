# modules/vm/variables.tf

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "nic_name" {
  type        = string
  description = "Name of the network interface"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the network interface"
}

variable "vm_size" {
  type        = string
  description = "VM size"
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Admin username"
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for admin user"
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "OS disk storage account type"
  default     = "Standard_LRS"
}

variable "image_publisher" {
  type        = string
  description = "OS image publisher"
  default     = "Canonical"
}

variable "image_offer" {
  type        = string
  description = "OS image offer"
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  type        = string
  description = "OS image SKU"
  default     = "22_04-lts-gen2"
}

variable "image_version" {
  type        = string
  description = "OS image version"
  default     = "latest"
}

variable "custom_data" {
  type        = string
  description = "Custom data script for VM initialization"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
  default     = {}
}
