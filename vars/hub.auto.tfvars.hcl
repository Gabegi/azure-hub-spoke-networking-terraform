# hub.tfvars
# Hub VNet Configuration
# This file contains all hub-specific variables

# ============================================================================
# General Configuration
# ============================================================================

subscription_id = "YOUR-SUBSCRIPTION-ID-HERE"  # Replace with your Azure subscription ID

environment = "dev"
location    = "westeurope"

tags = {
  Project     = "HubSpokeNetwork"
  ManagedBy   = "Terragrunt"
  Owner       = "Platform Team"
  CostCenter  = "IT-Infrastructure"
  Component   = "Hub"
}

# ============================================================================
# Network Configuration
# ============================================================================

hub_address_space = "10.0.0.0/16"

# ============================================================================
# Hub Feature Flags
# ============================================================================

deploy_firewall          = false  # Set to true to enable Azure Firewall
deploy_bastion           = true   # Needed for secure access
deploy_management_subnet = true

# ============================================================================
# Azure Firewall Configuration
# ============================================================================

firewall_sku_tier          = "Basic"
firewall_threat_intel_mode = "Off"
firewall_dns_servers       = []

# ============================================================================
# Azure Bastion Configuration
# ============================================================================

bastion_sku                = "Basic"
bastion_scale_units        = 2
bastion_copy_paste_enabled = true
bastion_file_copy_enabled  = false
bastion_ip_connect_enabled = false
bastion_tunneling_enabled  = false
bastion_zones              = ["1"]

# ============================================================================
# Application Gateway Configuration
# ============================================================================

app_gateway_sku_name         = "Standard_v2"
app_gateway_sku_tier         = "Standard_v2"
app_gateway_enable_autoscale = true
app_gateway_min_capacity     = 1
app_gateway_max_capacity     = 3
app_gateway_enable_waf       = false
app_gateway_waf_mode         = "Detection"
app_gateway_zones            = ["1"]

# ============================================================================
# High Availability
# ============================================================================

availability_zones = ["1"]

# ============================================================================
# Network Security Group Rules
# ============================================================================

# Management Subnet NSG Rules
management_nsg_rules = [
  # INBOUND
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
  # OUTBOUND
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
  }
]

# Application Gateway Subnet NSG Rules
app_gateway_nsg_rules = [
  # INBOUND
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
    description                = "Allow Gateway Manager (required)"
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
  # OUTBOUND
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
    description                = "Allow HTTPS to backend"
  }
]

# ============================================================================
# Monitoring and Diagnostics
# ============================================================================

enable_diagnostics         = true
enable_flow_logs           = false
enable_traffic_analytics   = false
traffic_analytics_interval = 60

# ============================================================================
# Resource Lock Configuration
# ============================================================================

enable_resource_lock = false
