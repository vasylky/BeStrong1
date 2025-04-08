output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.keyvault.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.keyvault.name
}

output "key_vault_url" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.keyvault.vault_uri
}