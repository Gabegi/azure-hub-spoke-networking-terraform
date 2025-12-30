# modules/firewall/main.tf
# Azure Firewall module - centralized network security and traffic inspection for hub-spoke architecture

# ============================================================================
# Internal Naming Module
# ============================================================================

module "firewall_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

module "firewall_pip_naming" {
  source = "../naming"

  resource_type = "pip"
  workload      = "firewall"
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

module "firewall_policy_naming" {
  source = "../naming"

  resource_type = "afwp"
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Azure Firewall Resources
# ============================================================================

# Public IP for Azure Firewall (required)
# Must be Static and Standard SKU for Firewall compatibility
resource "azurerm_public_ip" "firewall" {
  name                = module.firewall_pip_naming.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"              # Required for Firewall
  sku                 = "Standard"            # Required for Firewall
  zones               = var.availability_zones # Zone redundancy for HA (1, 2, 3)
  tags                = module.firewall_pip_naming.tags

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Optional: Additional Public IP addresses for SNAT
# Helps prevent SNAT port exhaustion with high traffic volumes
resource "azurerm_public_ip" "firewall_management" {
  count = var.management_subnet_id != null ? 1 : 0

  name                = "pip-firewall-mgmt-${var.environment}-${var.location}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = module.firewall_pip_naming.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Azure Firewall Policy (if creating new)
# Contains all firewall rules, threat intelligence, DNS settings, and IDPS configuration
resource "azurerm_firewall_policy" "policy" {
  count = var.create_firewall_policy ? 1 : 0

  name                     = module.firewall_policy_naming.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.sku_tier
  threat_intelligence_mode = var.threat_intel_mode
  tags                     = module.firewall_policy_naming.tags

  # DNS configuration (Standard/Premium SKU only - not available in Basic)
  dynamic "dns" {
    for_each = var.sku_tier != "Basic" ? [1] : []
    content {
      proxy_enabled = var.dns_proxy_enabled
      servers       = var.dns_servers
    }
  }

  # Threat Intelligence allowlist/denylist
  dynamic "threat_intelligence_allowlist" {
    for_each = length(var.threat_intelligence_allowlist_fqdns) > 0 || length(var.threat_intelligence_allowlist_ips) > 0 ? [1] : []
    content {
      fqdns        = var.threat_intelligence_allowlist_fqdns
      ip_addresses = var.threat_intelligence_allowlist_ips
    }
  }

  # Intrusion Detection and Prevention System (Premium SKU only)
  dynamic "intrusion_detection" {
    for_each = var.sku_tier == "Premium" && var.enable_idps ? [1] : []
    content {
      mode = var.idps_mode # Alert or Deny

      dynamic "signature_overrides" {
        for_each = var.idps_signature_overrides
        content {
          id    = signature_overrides.value.id
          state = signature_overrides.value.state # Alert or Deny or Off
        }
      }

      dynamic "traffic_bypass" {
        for_each = var.idps_traffic_bypass
        content {
          name                  = traffic_bypass.value.name
          protocol              = traffic_bypass.value.protocol
          description           = traffic_bypass.value.description
          destination_addresses = traffic_bypass.value.destination_addresses
          destination_ports     = traffic_bypass.value.destination_ports
          source_addresses      = traffic_bypass.value.source_addresses
          source_ip_groups      = traffic_bypass.value.source_ip_groups
        }
      }
    }
  }

  # TLS Inspection (Premium SKU only)
  dynamic "tls_certificate" {
    for_each = var.sku_tier == "Premium" && var.tls_certificate_key_vault_secret_id != null ? [1] : []
    content {
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
      name                = var.tls_certificate_name
    }
  }

  # Identity for accessing Key Vault (Premium SKU with TLS inspection)
  dynamic "identity" {
    for_each = var.sku_tier == "Premium" && var.tls_certificate_key_vault_secret_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.user_assigned_identity_id]
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Azure Firewall
# Provides stateful firewall, SNAT/DNAT, threat intelligence, and application/network filtering
resource "azurerm_firewall" "firewall" {
  name                = module.firewall_naming.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # SKU: AZFW_VNet (traditional VNet) or AZFW_Hub (Virtual WAN)
  sku_name = var.sku_name

  # Tier: Basic (~€6/mo, small workloads), Standard (~€800/mo), Premium (~€1,000/mo, TLS inspection + IDPS)
  sku_tier = var.sku_tier

  # Link to Firewall Policy (required for rule management)
  firewall_policy_id = var.create_firewall_policy ? azurerm_firewall_policy.policy[0].id : var.firewall_policy_id

  # Zone redundancy for 99.99% SLA (requires 3 zones)
  zones = var.availability_zones

  tags = module.firewall_naming.tags

  # Primary IP configuration - connects Firewall to AzureFirewallSubnet
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.subnet_id            # Must be AzureFirewallSubnet (/26 minimum, /24 recommended)
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  # Optional: Management IP configuration (for forced tunneling scenarios)
  dynamic "management_ip_configuration" {
    for_each = var.firewall_management_ip_name != null ? [1] : []
    content {
      name                 = "fw-mgmt-ipconfig"
      subnet_id            = var.management_subnet_id
      public_ip_address_id = azurerm_public_ip.firewall_management[0].id
    }
  }

  # Threat Intelligence mode: Off, Alert (log only), or Deny (block + log)
  # Recommendation: Use "Alert" initially, then switch to "Deny" after testing
  threat_intel_mode = var.threat_intel_mode

  # DNS configuration is handled via Firewall Policy (not directly on firewall resource)

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true for production
  }

  depends_on = [
    azurerm_public_ip.firewall,
    azurerm_firewall_policy.policy
  ]
}

# Optional: Diagnostic Settings for monitoring and compliance
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${module.firewall_naming.name}-diag"
  target_resource_id         = azurerm_firewall.firewall.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Application Rule Logs - Track allowed/denied application-level traffic
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  # Network Rule Logs - Track allowed/denied network-level traffic
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  # DNS Proxy Logs - Track DNS queries (if DNS proxy enabled)
  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  # IDPS Logs - Intrusion detection alerts (Premium SKU only)
  dynamic "enabled_log" {
    for_each = var.sku_tier == "Premium" ? [1] : []
    content {
      category = "AzureFirewallIdpsSignature"
    }
  }

  # Metrics for monitoring performance and usage
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Optional: Public IP Prefix for predictable SNAT IP ranges
# Useful for whitelisting firewall IPs at external services
resource "azurerm_public_ip_prefix" "firewall" {
  count = var.create_public_ip_prefix ? 1 : 0

  name                = "${module.firewall_naming.name}-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = var.public_ip_prefix_length # /28 = 16 IPs, /30 = 4 IPs, /31 = 2 IPs
  zones               = var.availability_zones
  tags                = module.firewall_naming.tags
}
