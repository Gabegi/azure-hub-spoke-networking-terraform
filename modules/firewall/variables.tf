# modules/firewall/variables.tf

# ============================================================================
# Naming Variables (for internal naming module)
# ============================================================================

variable "resource_type" {
  type        = string
  description = "Azure resource type abbreviation (e.g., 'afw' for Azure Firewall)"
  default     = "afw"
}

variable "workload" {
  type        = string
  description = "Workload or application name (e.g., 'hub', 'spoke', 'app')"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'dev', 'prod', 'staging')"
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
# Required Variables
# ============================================================================

variable "location" {
  type        = string
  description = "Azure region for the firewall (e.g., westeurope, eastus)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where firewall will be deployed"
}

variable "subnet_id" {
  type        = string
  description = "ID of the AzureFirewallSubnet (must be named exactly 'AzureFirewallSubnet' and at least /26)"

  validation {
    condition     = can(regex("/subnets/AzureFirewallSubnet$", var.subnet_id))
    error_message = "Subnet must be named 'AzureFirewallSubnet' (case-sensitive Azure requirement)"
  }
}

# ============================================================================
# SKU Configuration
# ============================================================================

variable "sku_name" {
  type        = string
  description = <<-EOT
    SKU name for Azure Firewall:
    - AZFW_VNet: Traditional VNet deployment (most common)
    - AZFW_Hub: Virtual WAN hub deployment
  EOT
  default     = "AZFW_VNet"

  validation {
    condition     = contains(["AZFW_VNet", "AZFW_Hub"], var.sku_name)
    error_message = "SKU name must be 'AZFW_VNet' or 'AZFW_Hub'"
  }
}

variable "sku_tier" {
  type        = string
  description = <<-EOT
    SKU tier for Azure Firewall:
    - Basic: ~€6/month, limited to small workloads (100 Mbps)
    - Standard: ~€800/month, full features except TLS inspection and IDPS
    - Premium: ~€1,000/month, includes TLS inspection, IDPS, and URL filtering
  EOT
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium", "Basic"], var.sku_tier)
    error_message = "SKU tier must be 'Standard', 'Premium', or 'Basic'"
  }
}

# ============================================================================
# High Availability
# ============================================================================

variable "availability_zones" {
  type        = list(string)
  description = <<-EOT
    Availability zones for zone redundancy (e.g., ["1", "2", "3"]).
    Provides 99.99% SLA when using all 3 zones.
    Note: Not all regions support availability zones.
  EOT
  default     = null

  validation {
    condition = var.availability_zones == null ? true : alltrue([
      for zone in var.availability_zones : contains(["1", "2", "3"], zone)
    ])
    error_message = "Availability zones must be null or contain only '1', '2', or '3'"
  }
}

# ============================================================================
# Firewall Policy
# ============================================================================

variable "firewall_policy_id" {
  type        = string
  description = "ID of an existing firewall policy (required if create_firewall_policy = false)"
  default     = null
}

variable "create_firewall_policy" {
  type        = bool
  description = "Create a new firewall policy (if false, must provide firewall_policy_id)"
  default     = false
}

variable "firewall_policy_name" {
  type        = string
  description = "Name of the firewall policy (if creating new). Defaults to '{firewall_name}-policy'"
  default     = null
}

variable "ignore_policy_changes" {
  type        = bool
  description = "Ignore changes to firewall_policy_id (useful if policy is managed separately)"
  default     = false
}

# ============================================================================
# Threat Intelligence
# ============================================================================

variable "threat_intel_mode" {
  type        = string
  description = <<-EOT
    Threat intelligence mode:
    - Off: Disabled (not recommended)
    - Alert: Log threats but allow traffic (good for testing)
    - Deny: Block and log threats (recommended for production)
  EOT
  default     = "Alert"

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.threat_intel_mode)
    error_message = "Threat intel mode must be 'Off', 'Alert', or 'Deny'"
  }
}

variable "threat_intelligence_allowlist_fqdns" {
  type        = list(string)
  description = "FQDNs to bypass threat intelligence filtering (e.g., trusted partners)"
  default     = []
}

variable "threat_intelligence_allowlist_ips" {
  type        = list(string)
  description = "IP addresses/ranges to bypass threat intelligence filtering"
  default     = []
}

# ============================================================================
# DNS Configuration
# ============================================================================

variable "dns_servers" {
  type        = list(string)
  description = "Custom DNS servers for the firewall (uses Azure DNS if empty)"
  default     = []
}

variable "dns_proxy_enabled" {
  type        = bool
  description = "Enable DNS proxy (allows spoke VMs to use firewall for DNS resolution)"
  default     = true
}

# ============================================================================
# Premium Features (Premium SKU Only)
# ============================================================================

variable "enable_idps" {
  type        = bool
  description = "Enable Intrusion Detection and Prevention System (Premium SKU only)"
  default     = false
}

variable "idps_mode" {
  type        = string
  description = "IDPS mode: Alert (log only) or Deny (block and log)"
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny"], var.idps_mode)
    error_message = "IDPS mode must be 'Alert' or 'Deny'"
  }
}

variable "idps_signature_overrides" {
  type = list(object({
    id    = string
    state = string # Alert, Deny, or Off
  }))
  description = "IDPS signature overrides (customize specific signature behavior)"
  default     = []
}

variable "idps_traffic_bypass" {
  type = list(object({
    name                  = string
    protocol              = string
    description           = optional(string)
    destination_addresses = optional(list(string))
    destination_ports     = optional(list(string))
    source_addresses      = optional(list(string))
    source_ip_groups      = optional(list(string))
  }))
  description = "IDPS traffic bypass rules (skip inspection for trusted traffic)"
  default     = []
}

# TLS Inspection (Premium SKU only)
variable "tls_certificate_key_vault_secret_id" {
  type        = string
  description = "Key Vault secret ID containing TLS certificate for inspection (Premium SKU only)"
  default     = null
}

variable "tls_certificate_name" {
  type        = string
  description = "Name for the TLS certificate"
  default     = "fw-tls-cert"
}

variable "user_assigned_identity_id" {
  type        = string
  description = "User-assigned managed identity ID for accessing Key Vault (required for TLS inspection)"
  default     = null
}

# ============================================================================
# Management IP (Forced Tunneling)
# ============================================================================

variable "firewall_management_ip_name" {
  type        = string
  description = "Name of management public IP (required for forced tunneling scenarios)"
  default     = null
}

variable "management_subnet_id" {
  type        = string
  description = "ID of AzureFirewallManagementSubnet (required if using management IP)"
  default     = null
}

# ============================================================================
# Public IP Prefix
# ============================================================================

variable "create_public_ip_prefix" {
  type        = bool
  description = "Create a public IP prefix for predictable SNAT IP ranges"
  default     = false
}

variable "public_ip_prefix_length" {
  type        = number
  description = "Public IP prefix length (/28 = 16 IPs, /30 = 4 IPs, /31 = 2 IPs)"
  default     = 31

  validation {
    condition     = contains([28, 29, 30, 31], var.public_ip_prefix_length)
    error_message = "Public IP prefix length must be 28, 29, 30, or 31"
  }
}

# ============================================================================
# Monitoring and Logging
# ============================================================================

variable "enable_diagnostic_settings" {
  type        = bool
  description = "Enable diagnostic settings for firewall (logs and metrics)"
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic settings (required if enable_diagnostic_settings = true)"
  default     = null

  validation {
    condition     = var.enable_diagnostic_settings == false || var.log_analytics_workspace_id != null
    error_message = "log_analytics_workspace_id is required when enable_diagnostic_settings is true"
  }
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  type        = map(string)
  description = "Tags to apply to firewall resources (best practice: include Owner, CostCenter, Environment)"
  default     = {}

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Azure supports a maximum of 50 tags per resource"
  }
}
