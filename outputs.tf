output "app_url" {
  value       = module.appservice.app_url
  description = "The URL of the deployed App Service"
}

output "key_vault_url" {
  value       = module.keyvault.key_vault_url
  description = "The URL of the Key Vault"
}

output "sql_server_fqdn" {
  value       = module.sql.sql_server_fqdn
  description = "The fully qualified domain name of the SQL server"
}

output "storage_account_name" {
  value       = module.storage.storage_account_name
  description = "Name of the main storage account"
}

output "acr_login_server" {
  value       = module.container_registry.acr_login_server
  description = "The login server URL for the container registry"
}