# Production Spoke Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Load environment variables
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

# Spoke depends on Hub - Terragrunt will deploy hub first
dependency "hub" {
  config_path = "../hub"

  # Mock outputs for validation (when hub isn't deployed yet)
  mock_outputs = {
    hub_vnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    hub_vnet_name            = "vnet-hub-prod-westeurope-001"
    hub_resource_group_name  = "rg-hub-prod-westeurope-001"
    hub_firewall_private_ip  = "10.0.0.4"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Production Spoke specific inputs
inputs = {
  subscription_id = "YOUR-SUBSCRIPTION-ID-HERE"  # Replace with your Azure subscription ID

  # Environment
  environment = "prod"

  # Network Configuration
  spoke_address_space = "10.2.0.0/16"

  # Subnet Deployment Flags
  deploy_workload_subnet = true
  deploy_data_subnet     = true
  deploy_app_subnet      = true

  # Hub Integration - Automatically get values from hub outputs
  hub_vnet_id              = dependency.hub.outputs.hub_vnet_id
  hub_vnet_name            = dependency.hub.outputs.hub_vnet_name
  hub_resource_group_name  = dependency.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip  = dependency.hub.outputs.hub_firewall_private_ip

  # Route Table Configuration
  enable_forced_tunneling = true  # Firewall enabled in prod
  route_table_routes = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    },
    {
      name                   = "to-development-spoke"
      address_prefix         = "10.1.0.0/16"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    }
  ]

  # VM Configuration
  vm_admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... (REPLACE_WITH_YOUR_PUBLIC_KEY)"

  # Monitoring
  enable_diagnostics         = true
  enable_flow_logs           = true
  enable_traffic_analytics   = true
  traffic_analytics_interval = 10

  # Resource Lock
  enable_resource_lock = true  # Production protected
}
