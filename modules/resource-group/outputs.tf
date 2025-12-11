# modules/resource-group/outputs.tf

output "rg_id" {
  value       = azurerm_resource_group.rg.id
  description = "Full resource ID of the resource group"
}

output "rg_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "rg_location" {
  value       = azurerm_resource_group.rg.location
  description = "Location of the resource group"
}

output "lock_id" {
  value       = var.enable_resource_lock ? azurerm_management_lock.rg_lock[0].id : null
  description = "ID of the resource lock (if enabled)"
}
