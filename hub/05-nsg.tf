# hub/05-nsg.tf
# Network Security Groups for Hub subnets

# ============================================================================
# Naming Modules
# ============================================================================

module "management_nsg_naming" {
  source = "../modules/naming"

  resource_type = "nsg"
  workload      = "management"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Management Subnet NSG
# ============================================================================

module "management_nsg" {
  count  = local.deploy_mgmt ? 1 : 0
  source = "../modules/nsg"

  nsg_name            = module.management_nsg_naming.name
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
      source_address_prefix      = local.bastion_subnet
      destination_address_prefix = "*"
      description                = "Allow SSH from Bastion subnet"
    },
    {
      name                       = "AllowBastionRDP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = local.bastion_subnet
      destination_address_prefix = "*"
      description                = "Allow RDP from Bastion subnet"
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
  subnet_id = module.management_subnet[0].subnet_id

  # Flow Logs
  enable_flow_logs                    = local.enable_flow_logs
  network_watcher_name                = local.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = local.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = var.storage_account_id

  # Traffic Analytics
  enable_traffic_analytics           = local.enable_traffic_analytics
  traffic_analytics_interval         = var.traffic_analytics_interval
  log_analytics_workspace_id         = var.log_analytics_workspace_id
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id

  # Diagnostic Settings
  enable_diagnostic_settings = local.enable_diagnostics

  tags = module.management_nsg_naming.tags

  depends_on = [
    module.management_subnet
  ]
}
