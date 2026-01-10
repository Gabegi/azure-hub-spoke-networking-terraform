# modules/vm/outputs.tf

output "vm_id" {
  description = "ID of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  description = "Name of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the VM (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.vm_public_ip[0].ip_address : null
}

output "network_interface_id" {
  description = "ID of the VM network interface"
  value       = azurerm_network_interface.vm_nic.id
}

output "vm_identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity (if enabled)"
  value       = var.enable_system_assigned_identity ? azurerm_linux_virtual_machine.vm.identity[0].principal_id : null
}
