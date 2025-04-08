resource "azurerm_service_plan" "service_plan" {
  name                = "${var.environment}-bestrong-plan-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.app_service_sku
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.environment}-bestrong-app-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.service_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = var.dotnet_version
    }
  }

  # No key vault reference here to avoid circular dependency
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_windows_web_app.app.id
  subnet_id      = var.integration_subnet_id
}