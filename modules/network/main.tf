resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-bestrong-vnet-${var.suffix}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "integration_subnet" {
  name                 = "${var.environment}-bestrong-plan-${var.suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints_subnet" {
  name                              = "${var.environment}-bestrong-pe-subnet-${var.suffix}"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.pe_subnet_prefix
  private_endpoint_network_policies_enabled = false
}