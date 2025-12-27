# modules/nsg/main.tf
# Generic Network Security Group (NSG) module - provides subnet-level firewall rules

# Network Security Group
# Acts as a virtual firewall for controlling inbound/outbound traffic to subnets or NICs
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Security Rules
# Create multiple rules dynamically from a list of rule definitions
# Priority: 100-4096 (lower = higher priority, default deny-all is 65500)
resource "azurerm_network_security_rule" "rules" {
  for_each = { for rule in var.security_rules : rule.name => rule }

  name                        = each.value.name
  priority                    = each.value.priority          # 100-4096, must be unique
  direction                   = each.value.direction         # Inbound or Outbound
  access                      = each.value.access            # Allow or Deny
  protocol                    = each.value.protocol          # Tcp, Udp, Icmp, Esp, Ah, or * (all)

  # Port ranges - use singular OR plural, not both
  # try() handles optional parameters gracefully (returns null if not provided)
  source_port_range           = try(each.value.source_port_range, null)       # Single port or range (e.g., "80" or "8000-8080")
  source_port_ranges          = try(each.value.source_port_ranges, null)      # Multiple ports/ranges (e.g., ["80", "443"])
  destination_port_range      = try(each.value.destination_port_range, null)  # Single port or range
  destination_port_ranges     = try(each.value.destination_port_ranges, null) # Multiple ports/ranges

  # Address prefixes - use singular OR plural, not both
  # Can use CIDR (10.0.0.0/24), service tags (Internet, VirtualNetwork), or * (any)
  source_address_prefix       = try(each.value.source_address_prefix, null)       # Single IP/CIDR/tag
  source_address_prefixes     = try(each.value.source_address_prefixes, null)     # Multiple IPs/CIDRs/tags
  destination_address_prefix  = try(each.value.destination_address_prefix, null)  # Single IP/CIDR/tag
  destination_address_prefixes = try(each.value.destination_address_prefixes, null) # Multiple IPs/CIDRs/tags

  # Application Security Groups (optional)
  # ASGs allow grouping VMs logically instead of by IP
  source_application_security_group_ids      = try(each.value.source_application_security_group_ids, null)
  destination_application_security_group_ids = try(each.value.destination_application_security_group_ids, null)

  # Description for documentation (max 140 chars)
  description = try(each.value.description, null)

  # Link to parent NSG
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

# Associate NSG with Subnet
# Subnet-level NSG applies to all resources in the subnet
resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_network_security_group.nsg,
    azurerm_network_security_rule.rules
  ]
}

# Optional: Associate NSG with Network Interface
# NIC-level NSG applies only to that specific VM
resource "azurerm_network_interface_security_group_association" "nsg_nic" {
  for_each = toset(var.network_interface_ids)

  network_interface_id      = each.value
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_network_security_group.nsg,
    azurerm_network_security_rule.rules
  ]
}

# Optional: Diagnostic Settings for NSG Flow Logs
# Flow logs track all traffic allowed/denied by NSG rules
resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name                      = "${var.nsg_name}-flow-log"
  network_watcher_name      = var.network_watcher_name
  resource_group_name       = var.network_watcher_resource_group_name
  network_security_group_id = azurerm_network_security_group.nsg.id
  storage_account_id        = var.flow_log_storage_account_id
  enabled                   = true
  version                   = 2 # Version 2 includes more detailed info

  retention_policy {
    enabled = var.flow_log_retention_enabled
    days    = var.flow_log_retention_days
  }

  # Traffic Analytics (optional) - provides insights into traffic patterns
  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
      interval_in_minutes   = var.traffic_analytics_interval # 10 or 60 minutes
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

# Optional: Diagnostic Settings for NSG Events
# Logs NSG rule hits, changes, and security events
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.nsg_name}-diag"
  target_resource_id         = azurerm_network_security_group.nsg.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # NSG Events - Logs when rules are added/removed/modified
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  # NSG Rule Counter - Logs how many times each rule was hit
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

# Optional: Create Application Security Groups
# ASGs allow logical grouping of VMs for easier security rule management
resource "azurerm_application_security_group" "asg" {
  for_each = { for asg in var.application_security_groups : asg.name => asg }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, try(each.value.tags, {}))

  lifecycle {
    prevent_destroy = false
  }
}
