# spoke-production/07-aci.tf
# Azure Container Instances infrastructure for Production spoke

# ============================================================================
# Naming Modules
# ============================================================================

module "aci_naming" {
  source = "../modules/naming"

  resource_type = "aci"
  workload      = "test"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Azure Container Instance
# ============================================================================

resource "azurerm_container_group" "aci" {
  count               = local.deploy_aci_subnet ? 1 : 0
  name                = module.aci_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name
  os_type             = "Linux"

  # Network configuration
  subnet_ids         = [module.aci_subnet[0].subnet_id]
  ip_address_type    = "Private"

  # Restart policy
  restart_policy = "Always"

  container {
    name   = "aci-helloworld"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = var.environment
      "SPOKE"       = "production"
    }
  }

  tags = merge(
    module.aci_naming.tags,
    {
      Purpose = "Connectivity Testing"
      Usage   = "Test spoke-to-spoke communication via hub firewall"
    }
  )

  depends_on = [
    module.aci_subnet,
    module.aci_nsg
  ]
}
