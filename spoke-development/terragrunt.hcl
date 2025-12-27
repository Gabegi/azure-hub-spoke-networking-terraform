# Development Spoke Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
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
}

# Hub Integration - Pass hub outputs to Terraform
inputs = {
  hub_vnet_id              = dependency.hub.outputs.hub_vnet_id
  hub_vnet_name            = dependency.hub.outputs.hub_vnet_name
  hub_resource_group_name  = dependency.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip  = try(dependency.hub.outputs.hub_firewall_private_ip, null)
}
