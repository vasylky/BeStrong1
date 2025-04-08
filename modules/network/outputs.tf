output "vnet_id" {
  description = "ID of the created virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "integration_subnet_id" {
  description = "ID of the integration subnet"
  value       = azurerm_subnet.integration_subnet.id
}

output "pe_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints_subnet.id
}