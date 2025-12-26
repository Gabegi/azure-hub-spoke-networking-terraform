# Root Terragrunt Configuration
# This file contains common configuration for all modules

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
  features {}

  subscription_id = var.subscription_id
}
EOF
}

# Remote state disabled - using local state files for this project
# Each module will store its state locally in terraform.tfstate
# Note: For production, enable remote state with Azure Storage
