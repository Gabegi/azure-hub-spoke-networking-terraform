# modules/route-table/main.tf
# Route Table module for custom routing configurations

resource "azurerm_route_table" "route_table" {
  name                          = var.route_table_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation
  tags                          = var.tags
}

# Routes
resource "azurerm_route" "routes" {
  for_each = { for route in var.routes : route.name => route }

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.route_table.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = try(each.value.next_hop_in_ip_address, null)
}

# Optional: Associate with subnet
resource "azurerm_subnet_route_table_association" "route_table_association" {
  count = var.subnet_id != null ? 1 : 0

  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.route_table.id
}
