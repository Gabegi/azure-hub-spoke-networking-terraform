# modules/storage-account/outputs.tf

output "storage_account_id" {
  value       = azurerm_storage_account.storage.id
  description = "Full resource ID of the storage account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Name of the storage account"
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.storage.primary_blob_endpoint
  description = "Primary blob endpoint"
}

output "primary_connection_string" {
  value       = azurerm_storage_account.storage.primary_connection_string
  description = "Primary connection string"
  sensitive   = true
}

output "primary_access_key" {
  value       = azurerm_storage_account.storage.primary_access_key
  description = "Primary access key"
  sensitive   = true
}
