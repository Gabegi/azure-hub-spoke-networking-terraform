# modules/resource-group/variables.tf

variable "rg_name" {
  type        = string
  description = "Name of the resource group"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.()]{0,88}[a-zA-Z0-9_()]$", var.rg_name))
    error_message = "Resource group name must be 1-90 characters and contain only alphanumeric, hyphens, underscores, periods, or parentheses"
  }
}

variable "location" {
  type        = string
  description = "Azure region for the resource group (e.g., westeurope, eastus)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource group"
  default     = {}

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Azure supports a maximum of 50 tags per resource"
  }
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
