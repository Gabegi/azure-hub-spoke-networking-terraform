# modules/naming/outputs.tf

output "name" {
  value       = local.base_name
  description = "Generated resource name following Microsoft conventions"
}

output "tags" {
  value       = local.standard_tags
  description = "Standard tags merged with custom tags"
}
