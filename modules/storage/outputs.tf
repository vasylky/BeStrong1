output "storage_account_id" {
  description = "ID of the main storage account"
  value       = azurerm_storage_account.tfstate.id
}

output "storage_account_name" {
  description = "Name of the main storage account"
  value       = azurerm_storage_account.tfstate.name
}

output "app_storage_account_id" {
  description = "ID of the app storage account"
  value       = azurerm_storage_account.app_storage.id
}

output "app_storage_account_name" {
  description = "Name of the app storage account"
  value       = azurerm_storage_account.app_storage.name
}