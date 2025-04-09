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


output "storage_file_share_name" {
  value = azurerm_storage_share.app_share.name
}

output "storage_primary_access_key" {
  value     = azurerm_storage_account.app_storage.primary_access_key
  sensitive = true
}

output "private_endpoint_ip" {
  value = azurerm_private_endpoint.storage_file_pe.private_service_connection[0].private_ip_address
}