# Hub VNet Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Hub-specific inputs
inputs = {
  # Required variables (no defaults in variables.tf)
  # subscription_id: Set via environment variable TF_VAR_subscription_id or pass via -var flag
  environment = "dev"
  location    = "westeurope"

  # Optional: Override defaults from variables.tf if needed
  # deploy_firewall = false
  # bastion_sku     = "Basic"
  # hub_address_space = "10.0.0.0/16"
}
