# Production Spoke Terragrunt Configuration

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
    hub_vnet_name            = "vnet-hub-prod-westeurope-001"
    hub_resource_group_name  = "rg-hub-prod-westeurope-001"
    hub_firewall_private_ip  = "10.0.0.4"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Production Spoke specific inputs
inputs = {
  # Required variables (no defaults in variables.tf)
  # subscription_id: Set via environment variable TF_VAR_subscription_id or pass via -var flag

  # Hub Integration - Automatically get values from hub outputs
  hub_vnet_id              = dependency.hub.outputs.hub_vnet_id
  hub_vnet_name            = dependency.hub.outputs.hub_vnet_name
  hub_resource_group_name  = dependency.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip  = dependency.hub.outputs.hub_firewall_private_ip

  # VM SSH Key (required if deploying VMs)
  vm_admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... (REPLACE_WITH_YOUR_PUBLIC_KEY)"

  # Override defaults for production
  environment = "prod"  # Must be "prod" for this spoke

  # Optional: Override other defaults from variables.tf if needed
  # location            = "westeurope"     # default: "westeurope"
  # spoke_address_space = "10.2.0.0/16"   # default: "10.2.0.0/16"
  # route_table_routes  = [...]            # default: []
  # enable_resource_lock = true            # Recommended for prod
}
