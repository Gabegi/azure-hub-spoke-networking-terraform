# spoke-production/07-function-app.tf
# Azure Function App infrastructure for Production spoke

# ============================================================================
# Storage Account for Function App
# ============================================================================

module "function_storage" {
  count  = local.deploy_function_subnet ? 1 : 0
  source = "../modules/storage-account"

  # Naming (module handles naming internally)
  resource_type = "st"
  workload      = "function"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Storage Configuration
  resource_group_name = module.rg_spoke.rg_name
  account_tier        = "Standard"
  replication_type    = "LRS"
  account_kind        = "StorageV2"

  # Security
  https_only                    = true
  allow_public_access           = false
  enable_shared_access_key      = true
  public_network_access_enabled = true

  depends_on = [module.rg_spoke]
}

# ============================================================================
# App Service Plan for Function App (Elastic Premium)
# ============================================================================

module "function_plan" {
  count  = local.deploy_function_subnet ? 1 : 0
  source = "../modules/app-service-plan"

  # Naming (module handles naming internally)
  resource_type = "asp"
  workload      = "function"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Plan Configuration
  resource_group_name = module.rg_spoke.rg_name
  os_type             = "Linux"
  sku_name            = "EP1"  # Elastic Premium 1

  # Elastic Premium Settings
  maximum_elastic_worker_count = 3
  per_site_scaling_enabled     = false
  zone_balancing_enabled       = false

  depends_on = [module.rg_spoke]
}

# ============================================================================
# Function App
# ============================================================================

module "function_app" {
  count  = local.deploy_function_subnet ? 1 : 0
  source = "../modules/function-app"

  # Naming (module handles naming internally)
  resource_type = "func"
  workload      = "app"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Function App Configuration
  resource_group_name        = module.rg_spoke.rg_name
  service_plan_id            = module.function_plan[0].plan_id
  storage_account_name       = module.function_storage[0].storage_account_name
  storage_account_access_key = module.function_storage[0].primary_access_key

  # VNet Integration
  virtual_network_subnet_id = module.function_subnet[0].subnet_id

  # OS and Runtime
  os_type                  = "Linux"
  functions_worker_runtime = "dotnet"
  dotnet_version           = "8.0"

  # Security
  https_only                    = true
  public_network_access_enabled = true

  # Site Configuration
  always_on              = true
  vnet_route_all_enabled = true
  http2_enabled          = true
  minimum_tls_version    = "1.2"

  # Elastic Premium Settings
  elastic_instance_minimum  = 1
  pre_warmed_instance_count = 1

  # CORS Configuration for testing directly in the portal
  cors_allowed_origins     = ["https://portal.azure.com"]
  cors_support_credentials = true

  # Application Settings
  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION"                 = "~4"
    "ENVIRONMENT"                                 = var.environment
    "WEBSITE_CONTENTSHARE"                        = "func-app-prod-content"
    "WEBSITE_RUN_FROM_PACKAGE"                    = "1"
    "WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED"      = "1"
  }

  depends_on = [
    module.function_plan,
    module.function_storage,
    module.function_subnet
  ]
}
