# Development Spoke Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Read dev tfvars for mock values
locals {
  vars = read_terragrunt_config("${get_repo_root()}/vars/dev.auto.tfvars.hcl")
}

# Automatically pass dev.auto.tfvars.hcl to Terraform
terraform {
  extra_arguments "vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${get_repo_root()}/vars/dev.auto.tfvars.hcl"
    ]
  }
}

# Spoke depends on Hub - Terragrunt will deploy hub first
dependency "hub" {
  config_path = "../hub"

  # Mock outputs for validation (when hub isn't deployed yet)
  # hub_vnet_id from tfvars, rest hardcoded
  mock_outputs = {
    hub_vnet_id              = local.vars.locals.mock_hub_vnet_id
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
