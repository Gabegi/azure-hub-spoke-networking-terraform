# modules/route-table/main.tf
# Route Table module for custom routing configurations

# ============================================================================
# Internal Naming Module
# ============================================================================

module "route_table_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Route Table
# ============================================================================

resource "azurerm_route_table" "route_table" {
  name                          = module.route_table_naming.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation
  tags                          = module.route_table_naming.tags

  lifecycle {
    ignore_changes = [tags]
  }
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

  lifecycle {
    ignore_changes = [tags]
  }
}

# Associate route table with subnet
resource "azurerm_subnet_route_table_association" "route_table_association" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.route_table.id

  lifecycle {
    ignore_changes = [tags]
  }
}
