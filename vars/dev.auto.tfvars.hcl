# dev.tfvars.example
# Development environment configuration for Hub-Spoke Network Topology
# Copy this file to dev.tfvars and customize for your development environment
#
# Usage: terraform apply -var-file="dev.tfvars"

# ============================================================================
# General Configuration
# ============================================================================

subscription_id = "xx"  # Replace with your Azure subscription ID

environment = "dev"
location    = "westeurope"

tags = {
  Project     = "HubSpokeNetwork"
  ManagedBy   = "Terraform"
  Owner       = "Platform Team"
  CostCenter  = "IT-Development"
  Environment = "Development"
}

# ============================================================================
# Network Configuration
# ============================================================================

hub_address_space         = "10.0.0.0/16"
development_address_space = "10.1.0.0/16"
production_address_space  = "10.2.0.0/16"

# ============================================================================
# Hub Feature Flags - Cost Optimized
# ============================================================================

deploy_firewall          = false  # Optional for dev - saves ~€800/month
deploy_bastion           = true   # Needed for secure access
deploy_management_subnet = true

# ============================================================================
# Spoke Deployment Flags
# ============================================================================

deploy_development_spoke = true   # Deploy development spoke
deploy_production_spoke  = false  # Not needed in dev workspace

# Development Spoke Subnets
deploy_development_workload_subnet = true
deploy_development_data_subnet     = true
deploy_development_app_subnet      = true

# Production Spoke Subnets (not deployed in dev)
deploy_production_workload_subnet = false
deploy_production_data_subnet     = false
deploy_production_app_subnet      = false

# ============================================================================
# Azure Firewall Configuration
# ============================================================================

firewall_sku_tier          = "Basic"   # Cost-optimized for dev (~€6/month)
firewall_threat_intel_mode = "Off"     # Not critical for dev
firewall_dns_servers       = []

# ============================================================================
# Azure Bastion Configuration - DEVELOPMENT (Cost Optimized)
# ============================================================================

bastion_sku                = "Basic"   # ~€110/month vs €130 for Standard
bastion_scale_units        = 2         # N/A for Basic SKU
bastion_copy_paste_enabled = true
bastion_file_copy_enabled  = false     # Not available in Basic
bastion_ip_connect_enabled = false     # Not available in Basic
bastion_tunneling_enabled  = false     # Not available in Basic
bastion_zones              = ["1"]     # Single zone for cost savings

# ============================================================================
# Application Gateway Configuration - DEVELOPMENT
# NOTE: Application Gateway is mandatory and always deployed
# ============================================================================

app_gateway_sku_name        = "Standard_v2"
app_gateway_sku_tier        = "Standard_v2"
app_gateway_enable_autoscale = true
app_gateway_min_capacity    = 1  # Minimum for dev if enabled
app_gateway_max_capacity    = 3  # Lower max for dev
app_gateway_enable_waf      = false
app_gateway_waf_mode        = "Detection"
app_gateway_zones           = ["1"]  # Single zone for cost savings

# ============================================================================
# High Availability
# ============================================================================

availability_zones = ["1"]  # Single zone for dev to reduce costs

# ============================================================================
# Network Security Group Rules
# ============================================================================

# Management Subnet NSG Rules
management_nsg_rules = [
  # INBOUND - Very Restrictive
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
  # OUTBOUND - Permissive for Admin Tasks
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
    description                = "Allow WinRM to spoke VMs"
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
    description                = "Allow HTTP to Internet"
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
    description                = "Allow DNS TCP"
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
    description                = "Allow DNS UDP"
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
    description                = "Allow NTP"
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
    description                = "Allow Azure Monitor"
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
    description                = "Allow Azure Storage"
  }
]

# Application Gateway Subnet NSG Rules
app_gateway_nsg_rules = [
  # INBOUND - Required for App Gateway
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
    name                       = "AllowAzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    description                = "Allow health probes (required)"
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
    description                = "Deny all other inbound"
  },
  # OUTBOUND - Required for App Gateway
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
    description                = "Allow HTTPS to Internet"
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
    description                = "Allow HTTPS to backend"
  }
]

# ============================================================================
# Route Table Configuration
# ============================================================================

enable_forced_tunneling = false  # Not needed if firewall is disabled

route_table_routes = [
  {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"  # Hub Firewall private IP
  },
  {
    name                   = "to-production-spoke"
    address_prefix         = "10.2.0.0/16"  # Production spoke
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"
  }
]

# ============================================================================
# VM Configuration
# ============================================================================

# IMPORTANT: Replace with your actual SSH public key
# Generate key: ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Get public key: cat ~/.ssh/id_rsa.pub
vm_admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... (REPLACE_WITH_YOUR_PUBLIC_KEY)"

# ============================================================================
# Monitoring and Diagnostics - Cost Optimized
# ============================================================================

enable_diagnostics         = true
enable_flow_logs           = false  # Optional for dev - saves storage costs
enable_traffic_analytics   = false  # Optional for dev
traffic_analytics_interval = 60     # Less frequent if enabled

log_analytics_sku            = "PerGB2018"
log_analytics_retention_days = 30   # Minimum retention
storage_replication_type     = "LRS"  # Locally redundant for dev

# ============================================================================
# Resource Lock Configuration
# ============================================================================

enable_resource_lock = false  # Disabled for dev to allow easy cleanup
