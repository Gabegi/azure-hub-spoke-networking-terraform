# spoke-development/07-aci.tf
# Azure Container Instances infrastructure for Development spoke

# ============================================================================
# Azure Container Instance
# ============================================================================

resource "azurerm_container_group" "aci" {
  count               = local.deploy_aci_subnet ? 1 : 0
  name                = "aci-test-${var.environment}-${var.location}-001"
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name
  os_type             = "Linux"

  # Network configuration
  subnet_ids         = [module.aci_subnet[0].subnet_id]
  ip_address_type    = "Private"

  # Restart policy
  restart_policy = "Always"

  container {
    name   = "app-dev"
    image  = "nicolaka/netshoot:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = var.environment
      "SPOKE"       = "development"
    }

    commands = ["sleep", "3600"]
  }

  tags = merge(
    var.tags,
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
