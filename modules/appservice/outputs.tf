output "app_id" {
  description = "ID of the App Service"
  value       = azurerm_windows_web_app.app.id
}

output "app_name" {
  description = "Name of the App Service"
  value       = azurerm_windows_web_app.app.name
}

output "app_principal_id" {
  description = "Principal ID of the App Service's managed identity"
  value       = azurerm_windows_web_app.app.identity[0].principal_id
}

output "app_url" {
  description = "Default URL of the App Service"
  value       = "https://${azurerm_windows_web_app.app.default_hostname}"
}