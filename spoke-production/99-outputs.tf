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
# VM Subnet Outputs
# ============================================================================

output "vm_subnet_id" {
  value       = module.vm_subnet.subnet_id
  description = "VM subnet ID"
}

output "vm_nsg_id" {
  value       = module.vm_nsg.nsg_id
  description = "VM NSG ID"
}

output "vm_route_table_id" {
  value       = module.vm_route_table.route_table_id
  description = "VM route table ID"
}

# ============================================================================
# VM Outputs
# ============================================================================

output "vm_id" {
  value       = module.vm.vm_id
  description = "VM resource ID"
}

output "vm_name" {
  value       = module.vm.vm_name
  description = "VM name"
}

output "vm_private_ip" {
  value       = module.vm.vm_private_ip
  description = "VM private IP address"
}

output "vm_identity_principal_id" {
  value       = module.vm.vm_identity_principal_id
  description = "VM system-assigned managed identity principal ID"
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
# Summary Output
# ============================================================================

output "spoke_summary" {
  value = {
    resource_group     = module.rg_spoke.rg_name
    vnet_name          = module.spoke_vnet.vnet_name
    vnet_address_space = local.spoke_address_space
    vm_name            = module.vm.vm_name
    vm_private_ip      = module.vm.vm_private_ip
    forced_tunneling   = local.enable_forced_tunneling
    resource_lock      = var.enable_resource_lock
    peering_to_hub     = azurerm_virtual_network_peering.spoke_to_hub.name
  }
  description = "Production spoke configuration summary"
}
