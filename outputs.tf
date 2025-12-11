# outputs.tf
# Root-level outputs for Hub-Spoke Network Topology

# ============================================================================
# Monitoring Outputs
# ============================================================================

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.main.workspace_id
  description = "Log Analytics workspace ID"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.main.name
  description = "Log Analytics workspace name"
}

output "storage_account_name" {
  value       = azurerm_storage_account.flow_logs.name
  description = "Storage account name for flow logs"
}

# ============================================================================
# Hub Outputs
# ============================================================================

output "hub_resource_group_name" {
  value       = module.hub.resource_group_name
  description = "Hub resource group name"
}

output "hub_vnet_id" {
  value       = module.hub.vnet_id
  description = "Hub VNet ID"
}

output "hub_vnet_name" {
  value       = module.hub.vnet_name
  description = "Hub VNet name"
}

output "hub_vnet_address_space" {
  value       = module.hub.vnet_address_space
  description = "Hub VNet address space"
}

output "hub_firewall_private_ip" {
  value       = module.hub.firewall_private_ip
  description = "Hub Firewall private IP address (use as next hop in route tables)"
  sensitive   = false
}

output "hub_bastion_fqdn" {
  value       = module.hub.bastion_fqdn
  description = "Hub Azure Bastion FQDN"
}

output "hub_summary" {
  value       = module.hub.hub_summary
  description = "Hub configuration summary"
}

# ============================================================================
# Staging Spoke Outputs
# ============================================================================

output "staging_resource_group_name" {
  value       = var.deploy_staging_spoke ? module.spoke_staging[0].resource_group_name : null
  description = "Staging spoke resource group name"
}

output "staging_vnet_id" {
  value       = var.deploy_staging_spoke ? module.spoke_staging[0].vnet_id : null
  description = "Staging spoke VNet ID"
}

output "staging_vnet_name" {
  value       = var.deploy_staging_spoke ? module.spoke_staging[0].vnet_name : null
  description = "Staging spoke VNet name"
}

output "staging_vnet_address_space" {
  value       = var.deploy_staging_spoke ? module.spoke_staging[0].vnet_address_space : null
  description = "Staging spoke VNet address space"
}

output "staging_spoke_summary" {
  value       = var.deploy_staging_spoke ? module.spoke_staging[0].spoke_summary : null
  description = "Staging spoke configuration summary"
}

# ============================================================================
# Production Spoke Outputs
# ============================================================================

output "production_resource_group_name" {
  value       = var.deploy_production_spoke ? module.spoke_production[0].resource_group_name : null
  description = "Production spoke resource group name"
}

output "production_vnet_id" {
  value       = var.deploy_production_spoke ? module.spoke_production[0].vnet_id : null
  description = "Production spoke VNet ID"
}

output "production_vnet_name" {
  value       = var.deploy_production_spoke ? module.spoke_production[0].vnet_name : null
  description = "Production spoke VNet name"
}

output "production_vnet_address_space" {
  value       = var.deploy_production_spoke ? module.spoke_production[0].vnet_address_space : null
  description = "Production spoke VNet address space"
}

output "production_spoke_summary" {
  value       = var.deploy_production_spoke ? module.spoke_production[0].spoke_summary : null
  description = "Production spoke configuration summary"
}

# ============================================================================
# Topology Summary
# ============================================================================

output "topology_summary" {
  value = {
    hub = {
      vnet_name           = module.hub.vnet_name
      vnet_address_space  = module.hub.vnet_address_space
      firewall_private_ip = module.hub.firewall_private_ip
      bastion_deployed    = module.hub.hub_summary.bastion_deployed
      firewall_deployed   = module.hub.hub_summary.firewall_deployed
    }
    staging = var.deploy_staging_spoke ? {
      vnet_name          = module.spoke_staging[0].vnet_name
      vnet_address_space = module.spoke_staging[0].vnet_address_space
      forced_tunneling   = module.spoke_staging[0].spoke_summary.forced_tunneling
    } : null
    production = var.deploy_production_spoke ? {
      vnet_name          = module.spoke_production[0].vnet_name
      vnet_address_space = module.spoke_production[0].vnet_address_space
      forced_tunneling   = module.spoke_production[0].spoke_summary.forced_tunneling
      resource_lock      = module.spoke_production[0].spoke_summary.resource_lock
    } : null
  }
  description = "Complete hub-spoke topology summary"
}
