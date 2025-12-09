# modules/naming/main.tf
# Naming convention module following Microsoft best practices
# Pattern: {resource-type}-{workload}-{environment}-{region}-{instance}

locals {
  # Standard naming pattern
  base_name = "${var.resource_type}-${var.workload}-${var.environment}-${var.location}-${var.instance}"

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
