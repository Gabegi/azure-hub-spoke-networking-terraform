# modules/storage-account/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'st' for Storage Account)"
  default     = "st"
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
  description = "Azure region for the storage account"
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
# Storage Account Configuration
# ============================================================================

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "account_tier" {
  type        = string
  description = "Storage account tier (Standard or Premium)"
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be 'Standard' or 'Premium'"
  }
}

variable "replication_type" {
  type        = string
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS"
  }
}

variable "account_kind" {
  type        = string
  description = "Storage account kind (BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2)"
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Account kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2"
  }
}

variable "min_tls_version" {
  type        = string
  description = "Minimum TLS version for the storage account"
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "TLS version must be one of: TLS1_0, TLS1_1, TLS1_2"
  }
}

# ============================================================================
# Security Settings
# ============================================================================

variable "https_only" {
  type        = bool
  description = "Enforce HTTPS traffic only"
  default     = true
}

variable "allow_public_access" {
  type        = bool
  description = "Allow public access to containers and blobs"
  default     = false
}

variable "enable_shared_access_key" {
  type        = bool
  description = "Enable shared access key authentication"
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access to storage account"
  default     = true
}

# ============================================================================
# Network Rules
# ============================================================================

variable "network_rules_enabled" {
  type        = bool
  description = "Enable network rules for the storage account"
  default     = false
}

variable "network_rules_default_action" {
  type        = string
  description = "Default action for network rules (Allow or Deny)"
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_rules_default_action)
    error_message = "Default action must be 'Allow' or 'Deny'"
  }
}

variable "network_rules_ip_rules" {
  type        = list(string)
  description = "List of public IP addresses or ranges allowed to access the storage account"
  default     = []
}

variable "network_rules_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs allowed to access the storage account"
  default     = []
}

variable "network_rules_bypass" {
  type        = list(string)
  description = "List of services to bypass network rules (AzureServices, Logging, Metrics, None)"
  default     = ["AzureServices"]
}
