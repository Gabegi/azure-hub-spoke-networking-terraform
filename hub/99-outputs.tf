# hub/99-outputs.tf
# Outputs from Hub VNet configuration

# ============================================================================
# Resource Group Outputs
# ============================================================================

output "resource_group_id" {
  value       = module.rg_networking.rg_id
  description = "Hub resource group ID"
}

output "resource_group_name" {
  value       = module.rg_networking.rg_name
  description = "Hub resource group name"
}

# ============================================================================
# VNet Outputs
# ============================================================================

output "vnet_id" {
  value       = module.hub_vnet.vnet_id
  description = "Hub VNet ID"
}

output "vnet_name" {
  value       = module.hub_vnet.vnet_name
  description = "Hub VNet name"
}

output "vnet_address_space" {
  value       = module.hub_vnet.vnet_address_space
  description = "Hub VNet address space"
}

# ============================================================================
# Subnet Outputs
# ============================================================================

output "firewall_subnet_id" {
  value       = module.firewall_subnet.subnet_id
  description = "Firewall subnet ID"
}

output "bastion_subnet_id" {
  value       = module.bastion_subnet.subnet_id
  description = "Bastion subnet ID"
}

output "management_subnet_id" {
  value       = local.deploy_mgmt ? module.management_subnet[0].subnet_id : null
  description = "Management subnet ID (if deployed)"
}

output "app_gateway_subnet_id" {
  value       = module.app_gateway_subnet.subnet_id
  description = "Application Gateway subnet ID"
}

# ============================================================================
# Firewall Outputs
# ============================================================================

output "firewall_id" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_id : null
  description = "Azure Firewall ID"
}

output "firewall_name" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_name : null
  description = "Azure Firewall name"
}

output "firewall_private_ip" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_private_ip : null
  description = "Firewall private IP (use as next hop in route tables)"
}

output "firewall_public_ip" {
  value       = local.deploy_firewall ? module.firewall[0].firewall_public_ip : null
  description = "Firewall public IP address"
}

# ============================================================================
# Bastion Outputs
# ============================================================================

output "bastion_id" {
  value       = local.deploy_bastion ? module.bastion[0].bastion_id : null
  description = "Azure Bastion ID"
}

output "bastion_name" {
  value       = local.deploy_bastion ? module.bastion[0].bastion_name : null
  description = "Azure Bastion name"
}

output "bastion_fqdn" {
  value       = local.deploy_bastion ? module.bastion[0].bastion_dns_name : null
  description = "Azure Bastion FQDN"
}

# ============================================================================
# Application Gateway Outputs
# ============================================================================

output "app_gateway_id" {
  value       = module.app_gateway.app_gateway_id
  description = "Application Gateway ID"
}

output "app_gateway_name" {
  value       = module.app_gateway.app_gateway_name
  description = "Application Gateway name"
}

output "app_gateway_public_ip" {
  value       = module.app_gateway.public_ip_address
  description = "Application Gateway public IP address"
}

# ============================================================================
# NSG Outputs
# ============================================================================

output "management_nsg_id" {
  value       = local.deploy_mgmt ? module.management_nsg[0].nsg_id : null
  description = "Management NSG ID"
}

output "app_gateway_nsg_id" {
  value       = module.app_gateway_nsg.nsg_id
  description = "Application Gateway NSG ID"
}

# ============================================================================
# Summary Output
# ============================================================================

output "hub_summary" {
  value = {
    resource_group       = module.rg_networking.rg_name
    vnet_name           = module.hub_vnet.vnet_name
    vnet_address_space  = local.hub_address_space
    firewall_deployed   = local.deploy_firewall
    firewall_private_ip = local.deploy_firewall ? module.firewall[0].firewall_private_ip : null
    bastion_deployed    = local.deploy_bastion
    management_deployed  = local.deploy_mgmt
  }
  description = "Hub configuration summary"
}
