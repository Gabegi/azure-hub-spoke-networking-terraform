# spoke-development/03-nsg.tf
# Network Security Groups for Development Spoke subnets

# ============================================================================
# Workload Subnet NSG
# ============================================================================

module "workload_nsg" {
  count  = local.deploy_workload_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "workload"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  security_rules = [
    {
      name                       = "AllowSSHFromBastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.1.0/26"
      destination_address_prefix = "*"
      description                = "Allow SSH from Azure Bastion subnet"
    },
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Allow Azure health probes and platform services"
    },
    {
      name                       = "AllowHTTPSOutbound"
      priority                   = 200
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
      name                       = "AllowHTTPOutbound"
      priority                   = 210
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Allow HTTP to Internet"
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
      description                = "Deny all inbound traffic (rely on explicit allow rules)"
    }
  ]

  # Associate with workload subnet
  subnet_id = module.workload_subnet[0].subnet_id

  # Flow Logs
  enable_flow_logs                    = local.enable_flow_logs
  network_watcher_name                = local.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = local.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = var.storage_account_id

  # Traffic Analytics
  enable_traffic_analytics            = local.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = var.log_analytics_workspace_id
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id

  # Diagnostic Settings
  enable_diagnostic_settings = local.enable_diagnostics

  depends_on = [
    module.workload_subnet
  ]
}

# ============================================================================
# Data Subnet NSG
# ============================================================================

module "data_nsg" {
  count  = local.deploy_data_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "data"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  security_rules = [
    {
      name                       = "AllowSQLFromWorkload"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = local.workload_subnet
      destination_address_prefix = "*"
      description                = "Allow SQL from workload subnet"
    },
    {
      name                       = "AllowPostgreSQLFromWorkload"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = local.workload_subnet
      destination_address_prefix = "*"
      description                = "Allow PostgreSQL from workload subnet"
    },
    {
      name                       = "DenyInternetOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Deny Internet access from data subnet"
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

  # Associate with data subnet
  subnet_id = module.data_subnet[0].subnet_id

  # Flow Logs
  enable_flow_logs                    = local.enable_flow_logs
  network_watcher_name                = local.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = local.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = var.storage_account_id

  # Traffic Analytics
  enable_traffic_analytics            = local.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = var.log_analytics_workspace_id
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id

  # Diagnostic Settings
  enable_diagnostic_settings = local.enable_diagnostics

  depends_on = [
    module.data_subnet
  ]
}

# ============================================================================
# Application Subnet NSG
# ============================================================================

module "app_nsg" {
  count  = local.deploy_app_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "app"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  security_rules = [
    {
      name                       = "AllowHTTPInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTP inbound"
    },
    {
      name                       = "AllowHTTPSInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTPS inbound"
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

  # Associate with app subnet
  subnet_id = module.app_subnet[0].subnet_id

  # Flow Logs
  enable_flow_logs                    = local.enable_flow_logs
  network_watcher_name                = local.enable_flow_logs ? "NetworkWatcher_${var.location}" : null
  network_watcher_resource_group_name = local.enable_flow_logs ? "NetworkWatcherRG" : null
  flow_log_storage_account_id         = var.storage_account_id

  # Traffic Analytics
  enable_traffic_analytics            = local.enable_traffic_analytics
  traffic_analytics_interval          = var.traffic_analytics_interval
  log_analytics_workspace_id          = var.log_analytics_workspace_id
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id

  # Diagnostic Settings
  enable_diagnostic_settings = local.enable_diagnostics

  depends_on = [
    module.app_subnet
  ]
}
