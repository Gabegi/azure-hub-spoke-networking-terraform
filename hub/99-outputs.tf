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
  value       = var.deploy_firewall ? module.firewall_subnet[0].subnet_id : null
  description = "Firewall subnet ID"
}

# Management subnet output removed - subnet not currently deployed

output "app_gateway_subnet_id" {
  value       = var.deploy_app_gateway ? module.app_gateway_subnet[0].subnet_id : null
  description = "Application Gateway subnet ID (if deployed)"
}

# ============================================================================
# Firewall Outputs
# ============================================================================

output "firewall_id" {
  value       = var.deploy_firewall ? module.firewall[0].firewall_id : null
  description = "Azure Firewall ID"
}

output "firewall_name" {
  value       = var.deploy_firewall ? module.firewall[0].firewall_name : null
  description = "Azure Firewall name"
}

output "firewall_private_ip" {
  value       = var.deploy_firewall ? module.firewall[0].firewall_private_ip : null
  description = "Firewall private IP (use as next hop in route tables)"
}

output "firewall_public_ip" {
  value       = var.deploy_firewall ? module.firewall[0].firewall_public_ip : null
  description = "Firewall public IP address"
}

# ============================================================================
# Application Gateway Outputs
# ============================================================================

output "app_gateway_id" {
  value       = var.deploy_app_gateway ? module.app_gateway[0].app_gateway_id : null
  description = "Application Gateway ID"
}

output "app_gateway_name" {
  value       = var.deploy_app_gateway ? module.app_gateway[0].app_gateway_name : null
  description = "Application Gateway name"
}

output "app_gateway_public_ip" {
  value       = var.deploy_app_gateway ? module.app_gateway[0].public_ip_address : null
  description = "Application Gateway public IP address"
}

output "app_gateway_backend_pool_ids" {
  value       = var.deploy_app_gateway ? module.app_gateway[0].backend_address_pool_ids : null
  description = "Application Gateway backend pool IDs"
}

# ============================================================================
# Route Table Outputs
# ============================================================================

output "app_gateway_route_table_id" {
  value       = var.deploy_app_gateway ? module.app_gateway_route_table[0].route_table_id : null
  description = "App Gateway subnet route table ID (if deployed)"
}

# Note: Bastion and NSG modules not yet implemented in hub

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
    resource_group        = module.rg_networking.rg_name
    vnet_name            = module.hub_vnet.vnet_name
    vnet_address_space   = var.hub_address_space
    firewall_deployed    = var.deploy_firewall
    firewall_private_ip  = var.deploy_firewall ? module.firewall[0].firewall_private_ip : null
    app_gateway_deployed = var.deploy_app_gateway
    app_gateway_public_ip = var.deploy_app_gateway ? module.app_gateway[0].public_ip_address : null
    management_deployed  = var.deploy_management_subnet
  }
  description = "Hub configuration summary"
}
