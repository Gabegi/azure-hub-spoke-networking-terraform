# Development Spoke Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Automatically pass dev.tfvars to Terraform
terraform {
  extra_arguments "vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${get_repo_root()}/vars/dev.tfvars"
    ]
  }
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

# Hub Integration - Pass hub outputs to Terraform
inputs = {
  hub_vnet_id              = dependency.hub.outputs.hub_vnet_id
  hub_vnet_name            = dependency.hub.outputs.hub_vnet_name
  hub_resource_group_name  = dependency.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip  = try(dependency.hub.outputs.hub_firewall_private_ip, null)
}
