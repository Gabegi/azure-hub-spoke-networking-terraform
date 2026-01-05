# hub/99-outputs.tf
# Outputs from Hub VNet configuration

# ============================================================================
# Resource Group Outputs
# ============================================================================

output "resource_group_id" {
  value       = module.rg_networking.rg_id
  description = "Hub resource group ID"
}

output "resource_group_name" {
  value       = module.rg_networking.rg_name
  description = "Hub resource group name"
}

# ============================================================================
# VNet Outputs
# ============================================================================

output "vnet_id" {
  value       = module.hub_vnet.vnet_id
  description = "Hub VNet ID"
}

output "vnet_name" {
  value       = module.hub_vnet.vnet_name
  description = "Hub VNet name"
}

output "vnet_address_space" {
  value       = module.hub_vnet.vnet_address_space
  description = "Hub VNet address space"
}

# ============================================================================
# Subnet Outputs
# ============================================================================

output "firewall_subnet_id" {
  value       = module.firewall_subnet.subnet_id
  description = "Firewall subnet ID"
}

output "bastion_subnet_id" {
  value       = local.deploy_bastion ? module.bastion_subnet[0].subnet_id : null
  description = "Bastion subnet ID (if deployed)"
}

output "management_subnet_id" {
  value       = local.deploy_mgmt ? module.management_subnet[0].subnet_id : null
  description = "Management subnet ID (if deployed)"
}

output "app_gateway_subnet_id" {
  value       = local.deploy_app_gateway ? module.app_gateway_subnet[0].subnet_id : null
  description = "Application Gateway subnet ID (if deployed)"
}

# ============================================================================
# Firewall Outputs
# ============================================================================

output "firewall_id" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_id : null
  description = "Azure Firewall ID"
}

output "firewall_name" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_name : null
  description = "Azure Firewall name"
}

output "firewall_private_ip" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_private_ip : null
  description = "Firewall private IP (use as next hop in route tables)"
}

output "firewall_public_ip" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_public_ip : null
  description = "Firewall public IP address"
}

# ============================================================================
# Route Table Outputs
# ============================================================================

output "gateway_route_table_id" {
  value       = local.deploy_gateway ? module.gateway_route_table[0].route_table_id : null
  description = "Gateway subnet route table ID (if deployed)"
}

# ============================================================================
# Bastion Outputs
# ============================================================================

output "bastion_id" {
  value       = local.deploy_bastion ? module.bastion[0].bastion_id : null
  description = "Azure Bastion ID"
}

output "bastion_name" {
  value       = local.deploy_bastion ? module.bastion[0].bastion_name : null
  description = "Azure Bastion name"
}

output "bastion_fqdn" {
  value       = local.deploy_bastion ? module.bastion[0].bastion_dns_name : null
  description = "Azure Bastion FQDN"
}

# ============================================================================
# NSG Outputs
# ============================================================================

output "management_nsg_id" {
  value       = local.deploy_mgmt ? module.management_nsg[0].nsg_id : null
  description = "Management NSG ID"
}

output "app_gateway_nsg_id" {
  value       = local.deploy_app_gateway ? module.app_gateway_nsg[0].nsg_id : null
  description = "Application Gateway NSG ID"
}

# ============================================================================
# Monitoring Outputs
# ============================================================================

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.hub.id
  description = "Log Analytics workspace resource ID for diagnostics"
}

output "log_analytics_workspace_guid" {
  value       = azurerm_log_analytics_workspace.hub.workspace_id
  description = "Log Analytics workspace GUID"
}

output "storage_account_id" {
  value       = var.enable_flow_logs ? azurerm_storage_account.flow_logs[0].id : null
  description = "Storage account ID for flow logs"
}

# ============================================================================
# Summary Output
# ============================================================================

output "hub_summary" {
  value = {
    resource_group       = module.rg_networking.rg_name
    vnet_name           = module.hub_vnet.vnet_name
    vnet_address_space  = local.hub_address_space
    firewall_deployed   = local.deploy_firewall
    firewall_private_ip = local.deploy_firewall ? module.firewall[0].firewall_private_ip : null
    bastion_deployed    = local.deploy_bastion
    management_deployed  = local.deploy_mgmt
  }
  description = "Hub configuration summary"
}
