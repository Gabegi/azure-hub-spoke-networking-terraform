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
    # ========================================================================
    # INBOUND RULES - Very Restrictive
    # ========================================================================
    {
      name                       = "Allow-SSH-From-Bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "AzureBastionSubnet"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow SSH from Bastion subnet"
    },
    {
      name                       = "Allow-RDP-From-Bastion"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "AzureBastionSubnet"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow RDP from Bastion subnet"
    },
    {
      name                       = "Deny-All-Inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound traffic"
    },
    # ========================================================================
    # OUTBOUND RULES - More Permissive for Admin Tasks
    # ========================================================================
    {
      name                       = "Allow-SSH-to-Spokes"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow SSH to spoke VMs"
    },
    {
      name                       = "Allow-RDP-to-Spokes"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow RDP to spoke VMs"
    },
    {
      name                       = "Allow-WinRM-to-Spokes"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5985-5986"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow WinRM to spoke VMs (PowerShell remoting)"
    },
    {
      name                       = "Allow-HTTPS-Internet"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
      description                = "Allow HTTPS to Internet"
    },
    {
      name                       = "Allow-HTTP-Internet"
      priority                   = 210
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
      description                = "Allow HTTP to Internet (package updates)"
    },
    {
      name                       = "Allow-DNS-TCP"
      priority                   = 220
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "53"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
      description                = "Allow DNS TCP to Internet"
    },
    {
      name                       = "Allow-DNS-UDP"
      priority                   = 221
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_range     = "53"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
      description                = "Allow DNS UDP to Internet"
    },
    {
      name                       = "Allow-NTP"
      priority                   = 230
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_range     = "123"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
      description                = "Allow NTP to Internet (time sync)"
    },
    {
      name                       = "Allow-AzureMonitor"
      priority                   = 300
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureMonitor"
      description                = "Allow HTTPS to Azure Monitor"
    },
    {
      name                       = "Allow-AzureStorage"
      priority                   = 310
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Storage"
      description                = "Allow HTTPS to Azure Storage"
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

# ============================================================================
# Application Gateway Subnet NSG
# ============================================================================

module "app_gateway_nsg_naming" {
  source = "../modules/naming"

  resource_type = "nsg"
  workload      = "appgw"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "app_gateway_nsg" {
  count  = local.deploy_app_gateway ? 1 : 0
  source = "../modules/nsg"

  nsg_name            = module.app_gateway_nsg_naming.name
  location            = var.location
  resource_group_name = module.rg_networking.rg_name

  security_rules = [
    # INBOUND RULES - Required for App Gateway to function
    {
      name                       = "AllowGatewayManager"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
      description                = "Allow Azure Gateway Manager for control plane (required)"
    },
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Allow Azure Load Balancer health probes (required)"
    },
    {
      name                       = "AllowHTTPSFromInternet"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Allow HTTPS from Internet"
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
    },
    # OUTBOUND RULES - Required for App Gateway to function
    {
      name                       = "AllowHTTPSToInternet"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Allow HTTPS to Internet (certificate validation, Azure Monitor)"
    },
    {
      name                       = "AllowHTTPSToBackend"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow HTTPS to backend pools in VNet"
    }
  ]

  # Associate with app gateway subnet
  subnet_id = module.app_gateway_subnet[0].subnet_id

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

  tags = module.app_gateway_nsg_naming.tags

  depends_on = [
    module.app_gateway_subnet
  ]
}
