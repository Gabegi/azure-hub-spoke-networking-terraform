# Production Spoke Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Automatically pass prod.auto.tfvars.hcl to Terraform
terraform {
  extra_arguments "vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${get_repo_root()}/vars/prod.auto.tfvars.hcl"
    ]
  }
}

# Spoke depends on Hub - Terragrunt will deploy hub first
dependency "hub" {
  config_path = "../hub"
}

# Hub Integration - Pass hub outputs to Terraform
inputs = {
  hub_vnet_id                         = dependency.hub.outputs.vnet_id
  hub_vnet_name                       = dependency.hub.outputs.vnet_name
  hub_resource_group_name             = dependency.hub.outputs.resource_group_name
  hub_firewall_private_ip             = try(dependency.hub.outputs.firewall_private_ip, null)
  log_analytics_workspace_id          = dependency.hub.outputs.log_analytics_workspace_id
  log_analytics_workspace_resource_id = dependency.hub.outputs.log_analytics_workspace_id
}
