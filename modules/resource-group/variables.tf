# modules/resource-group/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'rg' for Resource Group)"
  default     = "rg"
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
  description = "Azure region for the resource group (e.g., westeurope, eastus)"
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
# Resource Lock (Optional)
# ============================================================================

variable "enable_resource_lock" {
  type        = bool
  description = "Enable resource lock to prevent accidental deletion or modification"
  default     = false
}

variable "lock_level" {
  type        = string
  description = "Lock level: CanNotDelete (prevent deletion) or ReadOnly (prevent changes)"
  default     = "CanNotDelete"

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Lock level must be 'CanNotDelete' or 'ReadOnly'"
  }
}

variable "lock_notes" {
  type        = string
  description = "Notes about why the lock is in place"
  default     = "Locked by Terraform to prevent accidental deletion"
}
