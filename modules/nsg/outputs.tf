# modules/nsg/outputs.tf

# ============================================================================
# NSG Outputs
# ============================================================================

output "nsg_id" {
  value       = azurerm_network_security_group.nsg.id
  description = "Full resource ID of the network security group"
}

output "nsg_name" {
  value       = azurerm_network_security_group.nsg.name
  description = "Name of the network security group"
}

output "nsg_location" {
  value       = azurerm_network_security_group.nsg.location
  description = "Location of the network security group"
}

output "nsg_resource_group_name" {
  value       = azurerm_network_security_group.nsg.resource_group_name
  description = "Resource group name of the network security group"
}

# ============================================================================
# Security Rules Outputs
# ============================================================================

output "security_rule_ids" {
  value = {
    for name, rule in azurerm_network_security_rule.rules : name => rule.id
  }
  description = "Map of security rule names to their resource IDs"
}

output "security_rule_count" {
  value       = length(azurerm_network_security_rule.rules)
  description = "Number of security rules in the NSG"
}

output "security_rules_summary" {
  value = {
    for name, rule in azurerm_network_security_rule.rules : name => {
      priority  = rule.priority
      direction = rule.direction
      access    = rule.access
      protocol  = rule.protocol
    }
  }
  description = "Summary of all security rules (priority, direction, access, protocol)"
}

# ============================================================================
# Association Outputs
# ============================================================================

output "subnet_association_id" {
  value       = azurerm_subnet_network_security_group_association.nsg_subnet.id
  description = "ID of the subnet-NSG association"
}

output "nic_association_ids" {
  value = {
    for nic_id, assoc in azurerm_network_interface_security_group_association.nsg_nic : nic_id => assoc.id
  }
  description = "Map of NIC IDs to their NSG association IDs"
}

# ============================================================================
# Application Security Groups Outputs
# ============================================================================

output "application_security_group_ids" {
  value = {
    for name, asg in azurerm_application_security_group.asg : name => asg.id
  }
  description = "Map of ASG names to their resource IDs"
}

output "application_security_groups" {
  value = {
    for name, asg in azurerm_application_security_group.asg : name => {
      id   = asg.id
      name = asg.name
    }
  }
  description = "Application Security Groups created by this module"
}

# ============================================================================
# Flow Logs Outputs
# ============================================================================

output "flow_log_id" {
  value       = var.enable_flow_logs ? azurerm_network_watcher_flow_log.nsg_flow_log[0].id : null
  description = "ID of the NSG flow log (if enabled)"
}

output "flow_log_enabled" {
  value       = var.enable_flow_logs
  description = "Whether flow logs are enabled for this NSG"
}

output "traffic_analytics_enabled" {
  value       = var.enable_traffic_analytics
  description = "Whether Traffic Analytics is enabled for this NSG"
}

# ============================================================================
# Diagnostic Settings Outputs
# ============================================================================

output "diagnostic_setting_id" {
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.nsg[0].id : null
  description = "ID of the diagnostic setting (if enabled)"
}

# ============================================================================
# Comprehensive Configuration Info
# ============================================================================

output "nsg_config" {
  value = {
    nsg_id               = azurerm_network_security_group.nsg.id
    nsg_name             = azurerm_network_security_group.nsg.name
    location             = azurerm_network_security_group.nsg.location
    resource_group       = azurerm_network_security_group.nsg.resource_group_name
    rule_count           = length(azurerm_network_security_rule.rules)
    subnet_associated    = true
    nic_count            = length(var.network_interface_ids)
    asg_count            = length(azurerm_application_security_group.asg)
    flow_logs_enabled    = var.enable_flow_logs
    traffic_analytics    = var.enable_traffic_analytics
    diagnostics_enabled  = var.enable_diagnostic_settings
  }
  description = "Comprehensive NSG configuration information"
}

# ============================================================================
# Resource Group and Location
# ============================================================================

output "resource_group_name" {
  value       = azurerm_network_security_group.nsg.resource_group_name
  description = "Resource group name where NSG is deployed"
}

output "location" {
  value       = azurerm_network_security_group.nsg.location
  description = "Azure region where NSG is deployed"
}
