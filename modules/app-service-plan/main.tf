# modules/app-service-plan/main.tf
# App Service Plan module for Azure Function Apps

# ============================================================================
# Internal Naming Module
# ============================================================================

module "plan_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# App Service Plan (Elastic Premium for Function Apps)
# ============================================================================

resource "azurerm_service_plan" "plan" {
  name                = module.plan_naming.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.sku_name

  # Elastic Premium specific settings
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  zone_balancing_enabled       = var.zone_balancing_enabled

  tags = module.plan_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}
