output "acr_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.acr.login_server
}