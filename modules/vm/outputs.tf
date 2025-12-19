# modules/vm/outputs.tf

output "vm_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "VM resource ID"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.vm.name
  description = "VM name"
}

output "vm_private_ip" {
  value       = azurerm_network_interface.vm.private_ip_address
  description = "VM private IP address"
}

output "nic_id" {
  value       = azurerm_network_interface.vm.id
  description = "Network interface ID"
}
