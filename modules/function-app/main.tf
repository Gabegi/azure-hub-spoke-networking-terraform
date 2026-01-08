# modules/function-app/main.tf
# Function App module for Azure Functions with VNet Integration

# ============================================================================
# Internal Naming Module
# ============================================================================

module "function_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Linux Function App
# ============================================================================

resource "azurerm_linux_function_app" "function" {
  count = var.os_type == "Linux" ? 1 : 0

  name                       = module.function_naming.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = var.service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  # VNet Integration
  virtual_network_subnet_id = var.virtual_network_subnet_id

  # Function App Settings
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled

  site_config {
    always_on                              = var.always_on
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    ftps_state                             = var.ftps_state
    http2_enabled                          = var.http2_enabled
    minimum_tls_version                    = var.minimum_tls_version
    use_32_bit_worker                      = var.use_32_bit_worker
    elastic_instance_minimum               = var.elastic_instance_minimum
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    runtime_scale_monitoring_enabled       = var.runtime_scale_monitoring_enabled

    application_stack {
      python_version = var.python_version
      node_version   = var.node_version
      dotnet_version = var.dotnet_version
      java_version   = var.java_version
    }

    dynamic "cors" {
      for_each = var.cors_allowed_origins != null ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      "WEBSITE_CONTENTOVERVNET"              = "1"
      "WEBSITE_VNET_ROUTE_ALL"               = var.vnet_route_all_enabled ? "1" : "0"
      "FUNCTIONS_WORKER_RUNTIME"             = var.functions_worker_runtime
    }
  )

  tags = module.function_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# ============================================================================
# Windows Function App
# ============================================================================

resource "azurerm_windows_function_app" "function" {
  count = var.os_type == "Windows" ? 1 : 0

  name                       = module.function_naming.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = var.service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  # VNet Integration
  virtual_network_subnet_id = var.virtual_network_subnet_id

  # Function App Settings
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled

  site_config {
    always_on                              = var.always_on
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    ftps_state                             = var.ftps_state
    http2_enabled                          = var.http2_enabled
    minimum_tls_version                    = var.minimum_tls_version
    use_32_bit_worker                      = var.use_32_bit_worker
    elastic_instance_minimum               = var.elastic_instance_minimum
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    runtime_scale_monitoring_enabled       = var.runtime_scale_monitoring_enabled

    application_stack {
      node_version        = var.node_version
      dotnet_version      = var.dotnet_version
      java_version        = var.java_version
      powershell_core_version = var.powershell_core_version
    }

    dynamic "cors" {
      for_each = var.cors_allowed_origins != null ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      "WEBSITE_CONTENTOVERVNET"              = "1"
      "WEBSITE_VNET_ROUTE_ALL"               = var.vnet_route_all_enabled ? "1" : "0"
      "FUNCTIONS_WORKER_RUNTIME"             = var.functions_worker_runtime
    }
  )

  tags = module.function_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}
