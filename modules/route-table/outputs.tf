# modules/route-table/outputs.tf

output "route_table_id" {
  value       = azurerm_route_table.route_table.id
  description = "ID of the route table"
}

output "route_table_name" {
  value       = azurerm_route_table.route_table.name
  description = "Name of the route table"
}

output "route_ids" {
  value = {
    for name, route in azurerm_route.routes : name => route.id
  }
  description = "Map of route names to their IDs"
}
