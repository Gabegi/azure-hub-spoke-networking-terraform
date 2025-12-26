# Development Spoke Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Spoke depends on Hub - Terragrunt will deploy hub first
dependency "hub" {
  config_path = "../hub"

  # Mock outputs for validation (when hub isn't deployed yet)
  mock_outputs = {
    hub_vnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    hub_vnet_name            = "vnet-hub-dev-westeurope-001"
    hub_resource_group_name  = "rg-hub-dev-westeurope-001"
    hub_firewall_private_ip  = null
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Development Spoke specific inputs
inputs = {
  subscription_id = "YOUR-SUBSCRIPTION-ID-HERE"  # Replace with your Azure subscription ID

  # Environment
  environment = "dev"

  # Network Configuration
  spoke_address_space = "10.1.0.0/16"

  # Subnet Deployment Flags
  deploy_workload_subnet = true
  deploy_data_subnet     = true
  deploy_app_subnet      = true

  # Hub Integration - Automatically get values from hub outputs
  hub_vnet_id              = dependency.hub.outputs.hub_vnet_id
  hub_vnet_name            = dependency.hub.outputs.hub_vnet_name
  hub_resource_group_name  = dependency.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip  = try(dependency.hub.outputs.hub_firewall_private_ip, null)

  # Route Table Configuration
  enable_forced_tunneling = false  # No firewall in dev
  route_table_routes = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    },
    {
      name                   = "to-production-spoke"
      address_prefix         = "10.2.0.0/16"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    }
  ]

  # VM Configuration
  vm_admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... (REPLACE_WITH_YOUR_PUBLIC_KEY)"

  # Monitoring
  enable_diagnostics         = true
  enable_flow_logs           = false
  enable_traffic_analytics   = false
  traffic_analytics_interval = 60

  # Resource Lock
  enable_resource_lock = false
}
