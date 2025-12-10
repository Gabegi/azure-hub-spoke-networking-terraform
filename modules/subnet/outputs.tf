# modules/subnet/outputs.tf

output "subnet_id" {
  value       = azurerm_subnet.subnet.id
  description = "ID of the subnet"
}

output "subnet_name" {
  value       = azurerm_subnet.subnet.name
  description = "Name of the subnet"
}

output "subnet_address_prefixes" {
  value       = azurerm_subnet.subnet.address_prefixes
  description = "Address prefixes of the subnet"
}
