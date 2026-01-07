# modules/app-service-plan/outputs.tf

output "plan_id" {
  value       = azurerm_service_plan.plan.id
  description = "Full resource ID of the app service plan"
}

output "plan_name" {
  value       = azurerm_service_plan.plan.name
  description = "Name of the app service plan"
}

output "plan_kind" {
  value       = azurerm_service_plan.plan.kind
  description = "Kind of the app service plan"
}
