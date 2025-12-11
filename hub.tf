# hub.tf
# Hub VNet - Central connectivity hub for all spoke networks
# Contains: Firewall, Bastion, Gateway, Management, and Shared Services

# ============================================================================
# Naming Conventions
# ============================================================================

# Resource Group Naming
module "rg_naming" {
  source = "./modules/naming"

  resource_type = "rg"
  workload      = "networking"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Hub VNet Naming
module "hub_vnet_naming" {
  source = "./modules/naming"

  resource_type = "vnet"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Hub Firewall Naming
module "hub_firewall_naming" {
  source = "./modules/naming"

  resource_type = "afw"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Hub Firewall Public IP Naming
module "hub_firewall_pip_naming" {
  source = "./modules/naming"

  resource_type = "pip"
  workload      = "firewall"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Hub Bastion Naming
module "hub_bastion_naming" {
  source = "./modules/naming"

  resource_type = "bas"
  workload      = "hub"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Hub Bastion Public IP Naming
module "hub_bastion_pip_naming" {
  source = "./modules/naming"

  resource_type = "pip"
  workload      = "bastion"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Management Subnet Naming
module "hub_management_subnet_naming" {
  source = "./modules/naming"

  resource_type = "snet"
  workload      = "management"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# Management NSG Naming
module "hub_management_nsg_naming" {
  source = "./modules/naming"

  resource_type = "nsg"
  workload      = "management"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Resource Group for Networking
# ============================================================================

module "rg_networking" {
  source = "./modules/resource-group"

  rg_name  = module.rg_naming.name
  location = var.location
  tags     = module.rg_naming.tags

  # Optional: Enable resource lock for production
  enable_resource_lock = var.environment == "prod" ? var.enable_resource_lock : false
  lock_level          = "CanNotDelete"
  lock_notes          = "Production networking resources - managed by Terraform"
}

# ============================================================================
# Hub Virtual Network
# ============================================================================

module "hub_vnet" {
  source = "./modules/vnet"

  vnet_name           = module.hub_vnet_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  address_space       = [var.hub_address_space] # 10.0.0.0/16

  tags = module.hub_vnet_naming.tags

  depends_on = [module.rg_networking]
}

# ============================================================================
# Hub Subnets
# ============================================================================

# AzureFirewallSubnet (REQUIRED - must be named exactly "AzureFirewallSubnet")
# Minimum /26 (64 IPs), we use /26 for cost optimization
module "hub_firewall_subnet" {
  source = "./modules/subnet"

  subnet_name          = "AzureFirewallSubnet" # Must be exactly this name
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.0.0/26"] # 10.0.0.0 - 10.0.0.63 (64 IPs, 59 usable)

  # No service endpoints or delegations for Firewall subnet
  # Azure Firewall manages this subnet's traffic

  depends_on = [module.hub_vnet]
}

# AzureBastionSubnet (REQUIRED - must be named exactly "AzureBastionSubnet")
# Minimum /26 (64 IPs), we use /26
module "hub_bastion_subnet" {
  source = "./modules/subnet"

  subnet_name          = "AzureBastionSubnet" # Must be exactly this name
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.1.0/26"] # 10.0.1.0 - 10.0.1.63 (64 IPs, 59 usable)

  # No service endpoints for Bastion subnet
  # Bastion manages its own network policies

  depends_on = [module.hub_vnet]
}

# GatewaySubnet (OPTIONAL - for future VPN/ExpressRoute Gateway)
# Must be named exactly "GatewaySubnet"
# Minimum /27 (32 IPs) for basic gateway, /26 or /24 recommended for production
module "hub_gateway_subnet" {
  count  = var.deploy_vpn_gateway ? 1 : 0
  source = "./modules/subnet"

  subnet_name          = "GatewaySubnet" # Must be exactly this name
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.2.0/27"] # 10.0.2.0 - 10.0.2.31 (32 IPs, 27 usable)

  # No service endpoints for Gateway subnet
  # Gateway manages its own network configuration

  depends_on = [module.hub_vnet]
}

# Management Subnet (OPTIONAL - for jump boxes, monitoring tools, etc.)
module "hub_management_subnet" {
  count  = var.deploy_management_subnet ? 1 : 0
  source = "./modules/subnet"

  subnet_name          = module.hub_management_subnet_naming.name
  resource_group_name  = module.rg_networking.rg_name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.3.0/24"] # 10.0.3.0 - 10.0.3.255 (256 IPs, 251 usable)

  # Service endpoints for management tools
  service_endpoints = [
    "Microsoft.Storage",        # Access to storage accounts
    "Microsoft.KeyVault",       # Access to Key Vault
    "Microsoft.Sql",            # Access to SQL databases
    "Microsoft.ContainerRegistry" # Access to ACR
  ]

  depends_on = [module.hub_vnet]
}

# ============================================================================
# Azure Firewall (OPTIONAL - for centralized network security)
# ============================================================================

module "hub_firewall" {
  count  = var.deploy_firewall ? 1 : 0
  source = "./modules/firewall"

  firewall_name       = module.hub_firewall_naming.name
  public_ip_name      = module.hub_firewall_pip_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.hub_firewall_subnet.subnet_id

  # SKU Configuration
  sku_name = "AZFW_VNet"         # Traditional VNet deployment
  sku_tier = var.firewall_sku_tier # Standard or Premium

  # Create integrated firewall policy
  create_firewall_policy = true
  firewall_policy_name   = "afwp-${module.hub_firewall_naming.name}"

  # Threat Intelligence
  threat_intel_mode = var.firewall_threat_intel_mode # Alert or Deny

  # DNS Proxy for spoke VNets
  dns_proxy_enabled = true
  dns_servers       = var.firewall_dns_servers

  # High Availability (99.99% SLA with 3 zones)
  availability_zones = var.availability_zones

  # Monitoring (optional)
  enable_diagnostic_settings = var.enable_diagnostics
  log_analytics_workspace_id = var.enable_diagnostics ? azurerm_log_analytics_workspace.main[0].id : null

  tags = module.hub_firewall_naming.tags

  depends_on = [
    module.hub_firewall_subnet,
    azurerm_log_analytics_workspace.main
  ]
}

# ============================================================================
# Azure Bastion (OPTIONAL - for secure VM access without public IPs)
# ============================================================================

module "hub_bastion" {
  count  = var.deploy_bastion ? 1 : 0
  source = "./modules/bastion"

  bastion_name        = module.hub_bastion_naming.name
  public_ip_name      = module.hub_bastion_pip_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  subnet_id           = module.hub_bastion_subnet.subnet_id

  # SKU Configuration
  sku         = var.bastion_sku         # Basic or Standard
  scale_units = var.bastion_scale_units # 2-50 (Standard SKU only)

  # Standard SKU Features
  copy_paste_enabled = var.bastion_copy_paste_enabled
  file_copy_enabled  = var.bastion_file_copy_enabled
  ip_connect_enabled = var.bastion_ip_connect_enabled
  tunneling_enabled  = var.bastion_tunneling_enabled

  # High Availability
  availability_zones = var.availability_zones

  # Monitoring (optional)
  enable_diagnostic_settings = var.enable_diagnostics
  log_analytics_workspace_id = var.enable_diagnostics ? azurerm_log_analytics_workspace.main[0].id : null

  tags = module.hub_bastion_naming.tags

  depends_on = [
    module.hub_bastion_subnet,
    azurerm_log_analytics_workspace.main
  ]
}

# ============================================================================
# Management Subnet NSG (OPTIONAL)
# ============================================================================

module "hub_management_nsg" {
  count  = var.deploy_management_subnet ? 1 : 0
  source = "./modules/nsg"

  nsg_name            = module.hub_management_nsg_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name

  security_rules = [
    {
      name                       = "AllowBastionSSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.1.0/26" # Bastion subnet
      destination_address_prefix = "*"
      description                = "Allow SSH from Bastion"
    },
    {
      name                       = "AllowBastionRDP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "10.0.1.0/26" # Bastion subnet
      destination_address_prefix = "*"
      description                = "Allow RDP from Bastion"
    },
    {
      name                       = "AllowHTTPSOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Allow HTTPS to Internet"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound traffic"
    }
  ]

  # Associate with management subnet
  subnet_id = module.hub_management_subnet[0].subnet_id

  # Flow logs (optional)
  enable_flow_logs                    = var.enable_flow_logs
  network_watcher_name                = var.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = var.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = var.enable_flow_logs ? azurerm_storage_account.flow_logs[0].id : null

  # Traffic Analytics (optional)
  enable_traffic_analytics           = var.enable_traffic_analytics
  traffic_analytics_interval         = var.traffic_analytics_interval
  log_analytics_workspace_id         = var.enable_traffic_analytics ? azurerm_log_analytics_workspace.main[0].workspace_id : null
  log_analytics_workspace_resource_id = var.enable_traffic_analytics ? azurerm_log_analytics_workspace.main[0].id : null

  # Diagnostic settings (optional)
  enable_diagnostic_settings = var.enable_diagnostics

  tags = module.hub_management_nsg_naming.tags

  depends_on = [
    module.hub_management_subnet,
    azurerm_storage_account.flow_logs,
    azurerm_log_analytics_workspace.main
  ]
}

# ============================================================================
# Outputs
# ============================================================================

output "hub_vnet_id" {
  value       = module.hub_vnet.vnet_id
  description = "Hub VNet ID"
}

output "hub_vnet_name" {
  value       = module.hub_vnet.vnet_name
  description = "Hub VNet name"
}

output "hub_firewall_private_ip" {
  value       = var.deploy_firewall ? module.hub_firewall[0].firewall_private_ip : null
  description = "Hub Firewall private IP (use as next hop in route tables)"
}

output "hub_bastion_id" {
  value       = var.deploy_bastion ? module.hub_bastion[0].bastion_id : null
  description = "Hub Bastion ID"
}

output "hub_subnets" {
  value = {
    firewall_subnet_id   = module.hub_firewall_subnet.subnet_id
    bastion_subnet_id    = module.hub_bastion_subnet.subnet_id
    gateway_subnet_id    = var.deploy_vpn_gateway ? module.hub_gateway_subnet[0].subnet_id : null
    management_subnet_id = var.deploy_management_subnet ? module.hub_management_subnet[0].subnet_id : null
  }
  description = "Hub subnet IDs"
}
