# modules/app-gateway/outputs.tf
# Application Gateway module outputs

output "app_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "app_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "public_ip_id" {
  description = "ID of the Application Gateway Public IP"
  value       = azurerm_public_ip.app_gateway.id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "backend_address_pool_ids" {
  description = "IDs of backend address pools"
  value       = { for pool in azurerm_application_gateway.main.backend_address_pool : pool.name => pool.id }
}

output "frontend_ip_configuration_id" {
  description = "ID of the frontend IP configuration"
  value       = azurerm_application_gateway.main.frontend_ip_configuration[0].id
}
