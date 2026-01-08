# modules/naming/main.tf
# Naming convention module following Microsoft best practices
# Pattern: {resource-type}-{workload}-{environment}-{region}-{instance}

locals {
  # Standard naming pattern
  base_name = "${var.resource_type}-${var.workload}-${var.environment}-${var.location}-${var.instance}"

  # Storage account names require special handling (no hyphens, lowercase only, 3-24 chars)
  storage_name = var.resource_type == "st" ? substr(replace(lower("${var.resource_type}${var.workload}${var.environment}${var.location}${var.instance}"), "-", ""), 0, 24) : local.base_name

  # Standard tags following Azure best practices
  standard_tags = merge(
    var.common_tags,
    {
      Environment = title(var.environment)
      Location    = var.location
      ManagedBy   = "Terraform"
      Project     = "HubSpokeNetwork"
      CostCenter  = var.cost_center
      CreatedDate = timestamp()
    }
  )
}
