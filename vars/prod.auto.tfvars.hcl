# prod.tfvars.example
# Production environment configuration for Hub-Spoke Network Topology
# Copy this file to prod.tfvars and customize for your production environment
#
# Usage: terraform apply -var-file="prod.tfvars"

# ============================================================================
# General Configuration
# ============================================================================

subscription_id = "xx"  # Replace with your Azure subscription ID

environment = "prod"
location    = "westeurope"

tags = {
  Project     = "HubSpokeNetwork"
  ManagedBy   = "Terraform"
  Owner       = "Platform Team"
  CostCenter  = "IT-Infrastructure"
  Environment = "Production"
}

# ============================================================================
# Network Configuration
# ============================================================================

hub_address_space         = "10.0.0.0/16"
development_address_space = "10.1.0.0/16"
production_address_space  = "10.2.0.0/16"

# ============================================================================
# Hub Feature Flags
# ============================================================================

deploy_firewall          = true
deploy_bastion           = true
deploy_management_subnet = true

# ============================================================================
# Spoke Deployment Flags
# ============================================================================

deploy_development_spoke = false  # Not deployed in prod workspace
deploy_production_spoke  = true

# Production Spoke Subnets
deploy_production_workload_subnet = true
deploy_production_data_subnet     = true
deploy_production_app_subnet      = true

# Development Spoke Subnets (not deployed in prod)
deploy_development_workload_subnet = false
deploy_development_data_subnet     = false
deploy_development_app_subnet      = false

# ============================================================================
# Azure Firewall Configuration
# ============================================================================

firewall_sku_tier          = "Standard"  # or "Premium" for advanced features
firewall_threat_intel_mode = "Alert"     # "Alert", "Deny", or "Off"
firewall_dns_servers       = []          # Leave empty for Azure DNS

# ============================================================================
# Azure Bastion Configuration - PRODUCTION
# ============================================================================

bastion_sku                = "Standard"
bastion_scale_units        = 2
bastion_copy_paste_enabled = true
bastion_file_copy_enabled  = true
bastion_ip_connect_enabled = true
bastion_tunneling_enabled  = true
bastion_zones              = ["1", "2", "3"]

# ============================================================================
# Application Gateway Configuration - PRODUCTION
# ============================================================================

app_gateway_sku_name        = "Standard_v2"  # or "WAF_v2" for Web Application Firewall
app_gateway_sku_tier        = "Standard_v2"
app_gateway_enable_autoscale = true
app_gateway_min_capacity    = 2
app_gateway_max_capacity    = 10
app_gateway_enable_waf      = false  # Set to true with WAF_v2 SKU for enhanced security
app_gateway_waf_mode        = "Prevention"  # "Detection" or "Prevention"
app_gateway_zones           = ["1", "2", "3"]

# ============================================================================
# High Availability
# ============================================================================

availability_zones = ["1", "2", "3"]

# ============================================================================
# Route Table Configuration
# ============================================================================

enable_forced_tunneling = true  # Route all spoke traffic through hub firewall

route_table_routes = [
  {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"  # Hub Firewall private IP
  },
  {
    name                   = "to-development-spoke"
    address_prefix         = "10.1.0.0/16"  # Development spoke
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
# Monitoring and Diagnostics
# ============================================================================

enable_diagnostics         = true
enable_flow_logs           = true
enable_traffic_analytics   = true
traffic_analytics_interval = 10  # 10 or 60 minutes

log_analytics_sku            = "PerGB2018"
log_analytics_retention_days = 90  # Longer retention for production
storage_replication_type     = "GRS"  # Geo-redundant for production

# ============================================================================
# Resource Lock Configuration
# ============================================================================

enable_resource_lock = true  # CRITICAL: Enabled for production resources
