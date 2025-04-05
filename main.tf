terraform {
  backend "azurerm" {}
}



provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id            = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-bestrong-vnet"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "integration_subnet" {
  name                 = "${var.environment}bestrong_plan"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
  service_endpoints    = ["Microsoft.KeyVault"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_key_vault" "keyvvv444" {
  name                      = "${var.environment}-keyvvv4544"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  sku_name                  = var.key_vault_sku
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = false

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.integration_subnet.id]
  }
}

resource "azurerm_service_plan" "service_plan" {
  name                = "${var.environment}-bestrong-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.app_service_sku
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.environment}-bestrong-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  retention_in_days   = var.app_insights_retention
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.environment}-bestrong-app"
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

  app_settings = {
    "KEY_VAULT_URL"                              = azurerm_key_vault.keyvvv444.vault_uri
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = azurerm_application_insights.insights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~2"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_windows_web_app.app.id
  subnet_id      = azurerm_subnet.integration_subnet.id
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.environment}bestrongacr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication

  min_tls_version = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}



output "managed_identity_principal_id" {
  value       = azurerm_windows_web_app.app.identity[0].principal_id
  description = "The Principal ID of the System Assigned Managed Identity"
}

output "app_url" {
  value       = "https://${azurerm_windows_web_app.app.default_hostname}"
  description = "The URL of the deployed App Service"
}
