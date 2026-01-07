# modules/app-service-plan/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'asp' for App Service Plan)"
  default     = "asp"
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
  description = "Azure region for the app service plan"
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
# App Service Plan Configuration
# ============================================================================

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "os_type" {
  type        = string
  description = "Operating system type (Linux or Windows)"
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be 'Linux' or 'Windows'"
  }
}

variable "sku_name" {
  type        = string
  description = "SKU name for the app service plan (EP1, EP2, EP3 for Elastic Premium)"
  default     = "EP1"

  validation {
    condition     = can(regex("^(EP1|EP2|EP3|Y1|B1|B2|B3|S1|S2|S3|P1v2|P2v2|P3v2|P1v3|P2v3|P3v3)$", var.sku_name))
    error_message = "SKU name must be valid (EP1-EP3 for Elastic Premium, Y1 for Consumption, B/S/P for Standard tiers)"
  }
}

# ============================================================================
# Elastic Premium Settings
# ============================================================================

variable "maximum_elastic_worker_count" {
  type        = number
  description = "Maximum number of workers for Elastic Premium (1-20)"
  default     = 3

  validation {
    condition     = var.maximum_elastic_worker_count >= 1 && var.maximum_elastic_worker_count <= 20
    error_message = "Maximum elastic worker count must be between 1 and 20"
  }
}

variable "per_site_scaling_enabled" {
  type        = bool
  description = "Enable per-site scaling"
  default     = false
}

variable "zone_balancing_enabled" {
  type        = bool
  description = "Enable zone balancing for availability zones"
  default     = false
}
