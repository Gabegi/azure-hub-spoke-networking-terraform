# modules/vnet/outputs.tf

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the virtual network"
}

output "vnet_address_space" {
  value       = azurerm_virtual_network.vnet.address_space
  description = "Address space of the virtual network"
}

output "vnet_location" {
  value       = azurerm_virtual_network.vnet.location
  description = "Location of the virtual network"
}

output "vnet_resource_group_name" {
  value       = azurerm_virtual_network.vnet.resource_group_name
  description = "Resource group name of the virtual network"
}
