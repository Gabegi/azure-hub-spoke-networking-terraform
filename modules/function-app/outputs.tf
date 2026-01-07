# modules/function-app/outputs.tf

output "function_app_id" {
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.function[0].id : azurerm_windows_function_app.function[0].id
  description = "Full resource ID of the function app"
}

output "function_app_name" {
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.function[0].name : azurerm_windows_function_app.function[0].name
  description = "Name of the function app"
}

output "function_app_default_hostname" {
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.function[0].default_hostname : azurerm_windows_function_app.function[0].default_hostname
  description = "Default hostname of the function app"
}

output "function_app_outbound_ip_addresses" {
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.function[0].outbound_ip_addresses : azurerm_windows_function_app.function[0].outbound_ip_addresses
  description = "Outbound IP addresses of the function app"
}

output "function_app_possible_outbound_ip_addresses" {
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.function[0].possible_outbound_ip_addresses : azurerm_windows_function_app.function[0].possible_outbound_ip_addresses
  description = "Possible outbound IP addresses of the function app"
}
