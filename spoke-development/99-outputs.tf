# spoke-development/99-outputs.tf
# Outputs from Development Spoke configuration

# ============================================================================
# Resource Group Outputs
# ============================================================================

output "resource_group_id" {
  value       = module.rg_spoke.rg_id
  description = "Development spoke resource group ID"
}

output "resource_group_name" {
  value       = module.rg_spoke.rg_name
  description = "Development spoke resource group name"
}

# ============================================================================
# VNet Outputs
# ============================================================================

output "vnet_id" {
  value       = module.spoke_vnet.vnet_id
  description = "Development spoke VNet ID"
}

output "vnet_name" {
  value       = module.spoke_vnet.vnet_name
  description = "Development spoke VNet name"
}

output "vnet_address_space" {
  value       = module.spoke_vnet.vnet_address_space
  description = "Development spoke VNet address space"
}

# ============================================================================
# Subnet Outputs
# ============================================================================

output "workload_subnet_id" {
  value       = local.deploy_workload_subnet ? module.workload_subnet[0].subnet_id : null
  description = "Workload subnet ID (if deployed)"
}

output "data_subnet_id" {
  value       = local.deploy_data_subnet ? module.data_subnet[0].subnet_id : null
  description = "Data subnet ID (if deployed)"
}

output "app_subnet_id" {
  value       = local.deploy_app_subnet ? module.app_subnet[0].subnet_id : null
  description = "Application subnet ID (if deployed)"
}

# ============================================================================
# NSG Outputs
# ============================================================================

output "workload_nsg_id" {
  value       = local.deploy_workload_subnet ? module.workload_nsg[0].nsg_id : null
  description = "Workload NSG ID (if deployed)"
}

output "data_nsg_id" {
  value       = local.deploy_data_subnet ? module.data_nsg[0].nsg_id : null
  description = "Data NSG ID (if deployed)"
}

output "app_nsg_id" {
  value       = local.deploy_app_subnet ? module.app_nsg[0].nsg_id : null
  description = "Application NSG ID (if deployed)"
}

# ============================================================================
# Route Table Outputs
# ============================================================================

output "workload_route_table_id" {
  value       = local.deploy_workload_subnet && local.enable_forced_tunneling ? module.workload_route_table[0].route_table_id : null
  description = "Workload route table ID (if deployed)"
}

output "data_route_table_id" {
  value       = local.deploy_data_subnet && local.enable_forced_tunneling ? module.data_route_table[0].route_table_id : null
  description = "Data route table ID (if deployed)"
}

output "app_route_table_id" {
  value       = local.deploy_app_subnet && local.enable_forced_tunneling ? module.app_route_table[0].route_table_id : null
  description = "Application route table ID (if deployed)"
}

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
# Test VM Outputs
# ============================================================================

output "test_vm_id" {
  value       = local.deploy_workload_subnet && length(module.test_vm) > 0 ? module.test_vm[0].vm_id : null
  description = "Test VM resource ID"
}

output "test_vm_private_ip" {
  value       = local.deploy_workload_subnet && length(module.test_vm) > 0 ? module.test_vm[0].vm_private_ip : null
  description = "Test VM private IP address"
}

# ============================================================================
# Summary Output
# ============================================================================

output "spoke_summary" {
  value = {
    resource_group      = module.rg_spoke.rg_name
    vnet_name           = module.spoke_vnet.vnet_name
    vnet_address_space  = local.spoke_address_space
    workload_deployed   = local.deploy_workload_subnet
    data_deployed       = local.deploy_data_subnet
    app_deployed        = local.deploy_app_subnet
    forced_tunneling    = local.enable_forced_tunneling
    peering_to_hub      = azurerm_virtual_network_peering.spoke_to_hub.name
  }
  description = "Development spoke configuration summary"
}
