# modules/function-app/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'func' for Function App)"
  default     = "func"
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
  description = "Azure region for the function app"
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
# Function App Configuration
# ============================================================================

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "service_plan_id" {
  type        = string
  description = "ID of the app service plan"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account for function app"
}

variable "storage_account_access_key" {
  type        = string
  description = "Access key for the storage account"
  sensitive   = true
}

variable "virtual_network_subnet_id" {
  type        = string
  description = "ID of the subnet for VNet integration"
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

# ============================================================================
# Security Settings
# ============================================================================

variable "https_only" {
  type        = bool
  description = "Enforce HTTPS traffic only"
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access to function app"
  default     = true
}

# ============================================================================
# Site Configuration
# ============================================================================

variable "always_on" {
  type        = bool
  description = "Keep the function app always on (required for Elastic Premium)"
  default     = true
}

variable "vnet_route_all_enabled" {
  type        = bool
  description = "Route all outbound traffic through VNet"
  default     = true
}

variable "ftps_state" {
  type        = string
  description = "FTPS state (AllAllowed, FtpsOnly, Disabled)"
  default     = "Disabled"

  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "FTPS state must be one of: AllAllowed, FtpsOnly, Disabled"
  }
}

variable "http2_enabled" {
  type        = bool
  description = "Enable HTTP/2"
  default     = true
}

variable "minimum_tls_version" {
  type        = string
  description = "Minimum TLS version"
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be one of: 1.0, 1.1, 1.2"
  }
}

variable "use_32_bit_worker" {
  type        = bool
  description = "Use 32-bit worker process"
  default     = false
}

variable "elastic_instance_minimum" {
  type        = number
  description = "Minimum number of instances for Elastic Premium"
  default     = 1

  validation {
    condition     = var.elastic_instance_minimum >= 0 && var.elastic_instance_minimum <= 20
    error_message = "Elastic instance minimum must be between 0 and 20"
  }
}

variable "pre_warmed_instance_count" {
  type        = number
  description = "Number of pre-warmed instances"
  default     = 1

  validation {
    condition     = var.pre_warmed_instance_count >= 0 && var.pre_warmed_instance_count <= 20
    error_message = "Pre-warmed instance count must be between 0 and 20"
  }
}

variable "runtime_scale_monitoring_enabled" {
  type        = bool
  description = "Enable runtime scale monitoring"
  default     = true
}

# ============================================================================
# Application Stack
# ============================================================================

variable "python_version" {
  type        = string
  description = "Python version (3.7, 3.8, 3.9, 3.10, 3.11)"
  default     = null
}

variable "node_version" {
  type        = string
  description = "Node.js version (12, 14, 16, 18, 20)"
  default     = null
}

variable "dotnet_version" {
  type        = string
  description = ".NET version (3.1, 6.0, 7.0, 8.0)"
  default     = null
}

variable "java_version" {
  type        = string
  description = "Java version (8, 11, 17)"
  default     = null
}

variable "powershell_core_version" {
  type        = string
  description = "PowerShell Core version (7, 7.2)"
  default     = null
}

variable "functions_worker_runtime" {
  type        = string
  description = "Functions worker runtime (dotnet, node, python, java, powershell, custom)"
  default     = "python"

  validation {
    condition     = contains(["dotnet", "node", "python", "java", "powershell", "custom"], var.functions_worker_runtime)
    error_message = "Functions worker runtime must be one of: dotnet, node, python, java, powershell, custom"
  }
}

# ============================================================================
# Application Settings
# ============================================================================

variable "app_settings" {
  type        = map(string)
  description = "Application settings for the function app"
  default     = {}
}
