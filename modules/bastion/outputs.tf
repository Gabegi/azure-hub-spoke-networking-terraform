# modules/bastion/outputs.tf

# ============================================================================
# Bastion Host Outputs
# ============================================================================

output "bastion_id" {
  value       = azurerm_bastion_host.bastion.id
  description = "Full resource ID of the Azure Bastion host"
}

output "bastion_name" {
  value       = azurerm_bastion_host.bastion.name
  description = "Name of the Azure Bastion host"
}

output "bastion_dns_name" {
  value       = azurerm_bastion_host.bastion.dns_name
  description = "Fully qualified domain name (FQDN) of the Bastion host"
}

output "bastion_sku" {
  value       = azurerm_bastion_host.bastion.sku
  description = "SKU of the Bastion host (Basic or Standard)"
}

output "bastion_scale_units" {
  value       = azurerm_bastion_host.bastion.scale_units
  description = "Number of scale units configured for the Bastion host"
}

# ============================================================================
# Public IP Outputs
# ============================================================================

output "public_ip_id" {
  value       = azurerm_public_ip.bastion.id
  description = "Resource ID of the Bastion's public IP"
}

output "public_ip_address" {
  value       = azurerm_public_ip.bastion.ip_address
  description = "Public IP address assigned to the Bastion host"
}

output "public_ip_fqdn" {
  value       = azurerm_public_ip.bastion.fqdn
  description = "FQDN of the public IP (if domain name label is set)"
}

# ============================================================================
# Connection Information
# ============================================================================

output "connection_info" {
  value = {
    bastion_url  = "https://portal.azure.com/#@/resource${azurerm_bastion_host.bastion.id}/connect"
    bastion_fqdn = azurerm_bastion_host.bastion.dns_name
    public_ip    = azurerm_public_ip.bastion.ip_address
    sku          = azurerm_bastion_host.bastion.sku
    scale_units  = azurerm_bastion_host.bastion.scale_units
    features = {
      copy_paste_enabled     = azurerm_bastion_host.bastion.copy_paste_enabled
      file_copy_enabled      = azurerm_bastion_host.bastion.file_copy_enabled
      ip_connect_enabled     = azurerm_bastion_host.bastion.ip_connect_enabled
      tunneling_enabled      = azurerm_bastion_host.bastion.tunneling_enabled
      shareable_link_enabled = azurerm_bastion_host.bastion.shareable_link_enabled
    }
  }
  description = "Comprehensive connection and configuration information for the Bastion host"
}

# ============================================================================
# Resource Group and Location
# ============================================================================

output "resource_group_name" {
  value       = azurerm_bastion_host.bastion.resource_group_name
  description = "Resource group name where Bastion is deployed"
}

output "location" {
  value       = azurerm_bastion_host.bastion.location
  description = "Azure region where Bastion is deployed"
}
