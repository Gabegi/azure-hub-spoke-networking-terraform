# Hub VNet Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Load environment variables
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment

  # Load environment-specific tfvars
  tfvars = read_terragrunt_config(find_in_parent_folders("vars/${local.environment}.tfvars"))
}

# Hub has no dependencies - it's deployed first
dependencies {
  paths = []
}

# Hub-specific inputs
inputs = {
  # Merge with root inputs and add hub-specific variables
  subscription_id = "7c8a8cb5-ee45-4e6e-9a20-4534c4796d8b"

  # Network Configuration
  hub_address_space = "10.0.0.0/16"

  # Feature Flags
  deploy_firewall          = false  # dev environment
  deploy_bastion           = true
  deploy_management_subnet = true

  # Firewall Configuration
  firewall_sku_tier          = "Basic"
  firewall_threat_intel_mode = "Off"
  firewall_dns_servers       = []

  # Bastion Configuration
  bastion_sku                = "Basic"
  bastion_scale_units        = 2
  bastion_copy_paste_enabled = true
  bastion_file_copy_enabled  = false
  bastion_ip_connect_enabled = false
  bastion_tunneling_enabled  = false
  bastion_zones              = ["1"]

  # Application Gateway Configuration
  app_gateway_sku_name        = "Standard_v2"
  app_gateway_sku_tier        = "Standard_v2"
  app_gateway_enable_autoscale = true
  app_gateway_min_capacity    = 1
  app_gateway_max_capacity    = 3
  app_gateway_enable_waf      = false
  app_gateway_waf_mode        = "Detection"
  app_gateway_zones           = ["1"]

  # High Availability
  availability_zones = ["1"]

  # NSG Rules (from vars/dev.tfvars)
  management_nsg_rules   = []  # Will be populated from tfvars
  app_gateway_nsg_rules  = []  # Will be populated from tfvars

  # Monitoring
  enable_diagnostics         = true
  enable_flow_logs           = false
  enable_traffic_analytics   = false
  traffic_analytics_interval = 60
  log_retention_days         = 30

  # Resource Lock
  enable_resource_lock = false
}
