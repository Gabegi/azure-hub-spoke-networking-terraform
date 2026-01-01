# spoke-development/07-aci.tf
# Azure Container Instances infrastructure for Development spoke

# ============================================================================
# Naming Modules
# ============================================================================

module "aci_subnet_naming" {
  source = "../modules/naming"

  resource_type = "snet"
  workload      = "aci"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "aci_route_table_naming" {
  source = "../modules/naming"

  resource_type = "route"
  workload      = "aci"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "aci_naming" {
  source = "../modules/naming"

  resource_type = "aci"
  workload      = "test"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# ACI Subnet (with delegation)
# ============================================================================

module "aci_subnet" {
  count  = local.deploy_aci_subnet ? 1 : 0
  source = "../modules/subnet"

  subnet_name          = module.aci_subnet_naming.name
  resource_group_name  = module.rg_spoke.rg_name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = [local.aci_subnet]

  # Service endpoints for ACI
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]

  # Delegation required for ACI
  delegation = {
    name         = "aci-delegation"
    service_name = "Microsoft.ContainerInstance/containerGroups"
    actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }

  depends_on = [
    module.spoke_vnet
  ]
}

# ============================================================================
# ACI Subnet NSG
# ============================================================================

module "aci_nsg" {
  count  = local.deploy_aci_subnet ? 1 : 0
  source = "../modules/nsg"

  # Naming (module handles naming internally)
  resource_type = "nsg"
  workload      = "aci"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Network Configuration
  resource_group_name = module.rg_spoke.rg_name

  security_rules = [
    # INBOUND
    {
      name                       = "AllowHTTPSInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTPS inbound for container apps"
    },
    {
      name                       = "AllowHTTPInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTP inbound for container apps"
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
      description                = "Allow Azure health probes"
    },
    # OUTBOUND
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
      name                       = "AllowHTTPOutbound"
      priority                   = 110
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
      name                       = "AllowDNSOutbound"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "53"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Allow DNS queries"
    },
    {
      name                       = "AllowToSpokes"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow traffic to other spokes via hub"
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

  # Associate with ACI subnet
  subnet_id = module.aci_subnet[0].subnet_id

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
    module.aci_subnet
  ]
}

# ============================================================================
# ACI Subnet Route Table (Force traffic through Hub Firewall)
# ============================================================================

module "aci_route_table" {
  count  = local.deploy_aci_subnet && local.enable_forced_tunneling ? 1 : 0
  source = "../modules/route-table"

  route_table_name             = module.aci_route_table_naming.name
  location                     = var.location
  resource_group_name          = module.rg_spoke.rg_name
  disable_bgp_route_propagation = true

  routes = var.route_table_routes

  # Associate with ACI subnet
  subnet_id = module.aci_subnet[0].subnet_id

  tags = module.aci_route_table_naming.tags

  depends_on = [
    module.aci_subnet
  ]
}

# ============================================================================
# Azure Container Instance
# ============================================================================

resource "azurerm_container_group" "aci" {
  count               = local.deploy_aci_subnet ? 1 : 0
  name                = module.aci_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name
  os_type             = "Linux"

  # Network configuration
  subnet_ids         = [module.aci_subnet[0].subnet_id]
  ip_address_type    = "Private"

  # Restart policy
  restart_policy = "Always"

  container {
    name   = "aci-helloworld"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = var.environment
      "SPOKE"       = "development"
    }
  }

  tags = merge(
    module.aci_naming.tags,
    {
      Purpose = "Connectivity Testing"
      Usage   = "Test spoke-to-spoke communication via hub firewall"
    }
  )

  depends_on = [
    module.aci_subnet,
    module.aci_nsg
  ]
}
