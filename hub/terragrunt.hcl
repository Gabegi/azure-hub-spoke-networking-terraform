# Hub VNet Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Automatically pass the appropriate tfvars file to Terraform
terraform {
  extra_arguments "vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${get_repo_root()}/vars/dev.tfvars"
    ]
  }
}
