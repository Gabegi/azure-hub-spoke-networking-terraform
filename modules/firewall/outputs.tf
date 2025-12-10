# modules/firewall/outputs.tf

# ============================================================================
# Firewall Outputs
# ============================================================================

output "firewall_id" {
  value       = azurerm_firewall.firewall.id
  description = "Full resource ID of the Azure Firewall"
}

output "firewall_name" {
  value       = azurerm_firewall.firewall.name
  description = "Name of the Azure Firewall"
}

output "firewall_private_ip" {
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  description = "Private IP address of the Azure Firewall (use this as next hop in route tables)"
}

output "firewall_public_ip" {
  value       = azurerm_public_ip.firewall.ip_address
  description = "Public IP address of the Azure Firewall"
}

output "firewall_sku_name" {
  value       = azurerm_firewall.firewall.sku_name
  description = "SKU name of the firewall (AZFW_VNet or AZFW_Hub)"
}

output "firewall_sku_tier" {
  value       = azurerm_firewall.firewall.sku_tier
  description = "SKU tier of the firewall (Basic, Standard, or Premium)"
}

# ============================================================================
# Public IP Outputs
# ============================================================================

output "public_ip_id" {
  value       = azurerm_public_ip.firewall.id
  description = "Resource ID of the firewall's primary public IP"
}

output "public_ip_fqdn" {
  value       = azurerm_public_ip.firewall.fqdn
  description = "FQDN of the firewall's public IP (if domain name label is set)"
}

output "management_public_ip" {
  value       = var.firewall_management_ip_name != null ? azurerm_public_ip.firewall_management[0].ip_address : null
  description = "Management public IP address (if configured for forced tunneling)"
}

output "management_public_ip_id" {
  value       = var.firewall_management_ip_name != null ? azurerm_public_ip.firewall_management[0].id : null
  description = "Resource ID of the management public IP"
}

# ============================================================================
# Firewall Policy Outputs
# ============================================================================

output "firewall_policy_id" {
  value       = var.create_firewall_policy ? azurerm_firewall_policy.policy[0].id : var.firewall_policy_id
  description = "ID of the firewall policy"
}

output "firewall_policy_name" {
  value       = var.create_firewall_policy ? azurerm_firewall_policy.policy[0].name : null
  description = "Name of the firewall policy (if created by this module)"
}

# ============================================================================
# Public IP Prefix Outputs
# ============================================================================

output "public_ip_prefix_id" {
  value       = var.create_public_ip_prefix ? azurerm_public_ip_prefix.firewall[0].id : null
  description = "Resource ID of the public IP prefix (if created)"
}

output "public_ip_prefix_range" {
  value       = var.create_public_ip_prefix ? azurerm_public_ip_prefix.firewall[0].ip_prefix : null
  description = "IP prefix range (e.g., 20.123.45.0/31)"
}

# ============================================================================
# Route Table Configuration Helper
# ============================================================================

output "route_table_next_hop_ip" {
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  description = "Use this IP as 'next_hop_in_ip_address' in route table configurations"
}

# ============================================================================
# Comprehensive Configuration Info
# ============================================================================

output "firewall_config" {
  value = {
    firewall_id      = azurerm_firewall.firewall.id
    firewall_name    = azurerm_firewall.firewall.name
    private_ip       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
    public_ip        = azurerm_public_ip.firewall.ip_address
    sku              = "${azurerm_firewall.firewall.sku_name}/${azurerm_firewall.firewall.sku_tier}"
    threat_intel     = azurerm_firewall.firewall.threat_intel_mode
    policy_id        = var.create_firewall_policy ? azurerm_firewall_policy.policy[0].id : var.firewall_policy_id
    dns_proxy        = var.dns_proxy_enabled
    availability_zones = var.availability_zones
  }
  description = "Comprehensive firewall configuration information"
}

# ============================================================================
# Resource Group and Location
# ============================================================================

output "resource_group_name" {
  value       = azurerm_firewall.firewall.resource_group_name
  description = "Resource group name where firewall is deployed"
}

output "location" {
  value       = azurerm_firewall.firewall.location
  description = "Azure region where firewall is deployed"
}
