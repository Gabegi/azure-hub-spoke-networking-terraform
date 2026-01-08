# spoke-production/99-outputs.tf
# Outputs from Production Spoke configuration

# ============================================================================
# Resource Group Outputs
# ============================================================================

output "resource_group_id" {
  value       = module.rg_spoke.rg_id
  description = "Production spoke resource group ID"
}

output "resource_group_name" {
  value       = module.rg_spoke.rg_name
  description = "Production spoke resource group name"
}

# ============================================================================
# VNet Outputs
# ============================================================================

output "vnet_id" {
  value       = module.spoke_vnet.vnet_id
  description = "Production spoke VNet ID"
}

output "vnet_name" {
  value       = module.spoke_vnet.vnet_name
  description = "Production spoke VNet name"
}

output "vnet_address_space" {
  value       = module.spoke_vnet.vnet_address_space
  description = "Production spoke VNet address space"
}

# ============================================================================
# ACI Subnet Outputs
# ============================================================================

output "function_subnet_id" {
  value       = local.deploy_function_subnet ? module.function_subnet[0].subnet_id : null
  description = "ACI subnet ID (if deployed)"
}

output "function_nsg_id" {
  value       = local.deploy_function_subnet ? module.function_nsg[0].nsg_id : null
  description = "ACI NSG ID (if deployed)"
}

output "function_route_table_id" {
  value       = local.deploy_function_subnet ? module.function_route_table[0].route_table_id : null
  description = "ACI route table ID (if deployed)"
}

# ============================================================================
# ACI Container Instance Outputs
# ============================================================================

# ============================================================================
# Peering Outputs
# ============================================================================

output "spoke_to_hub_peering_id" {
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
  description = "Spoke-to-Hub peering ID"
}

output "hub_to_spoke_peering_id" {
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
  description = "Hub-to-Spoke peering ID"
}

# ============================================================================
# Summary Output
# ============================================================================

output "spoke_summary" {
  value = {
    resource_group     = module.rg_spoke.rg_name
    vnet_name          = module.spoke_vnet.vnet_name
    vnet_address_space = local.spoke_address_space
    aci_deployed       = local.deploy_function_subnet
    forced_tunneling   = local.enable_forced_tunneling
    resource_lock      = var.enable_resource_lock
    peering_to_hub     = azurerm_virtual_network_peering.spoke_to_hub.name
  }
  description = "Production spoke configuration summary"
}
