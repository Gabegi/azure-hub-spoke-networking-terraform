# Root Terragrunt Configuration
# This file contains common configuration for all environments

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl", "env.hcl"))
  environment      = try(local.environment_vars.locals.environment, "dev")

  # Azure region
  location = "westeurope"

  # Common tags
  common_tags = {
    Project     = "HubSpokeNetwork"
    ManagedBy   = "Terragrunt"
    Environment = local.environment
  }
}

# Generate an Azure provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
}
EOF
}

# Remote state disabled - using local state files
# Each module will store its state locally in terraform.tfstate
# Note: For production, consider enabling remote state with Azure Storage

# Inputs that are common across all modules
inputs = {
  environment = local.environment
  location    = local.location
  tags        = local.common_tags
}
