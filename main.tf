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
  name                = "bestrong-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "integration_subnet" {
  name                 = "integration-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_key_vault" "kv123" {
  name                      = "bestrong-keyvault121"
  location                  = "eastus"
  resource_group_name       = var.resource_group_name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = false

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.integration_subnet.id]
  }
}

resource "azurerm_service_plan" "service_plan" {
  name                = "bestrong-plan"
  location            = "eastus"
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_application_insights" "insights" {
  name                = "bestrong-insights"
  location            = "eastus"
  resource_group_name = var.resource_group_name
  application_type    = "web"
  retention_in_days   = 90
}

resource "azurerm_windows_web_app" "app" {
  name                = "bestrong-app"
  location            = "eastus"
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.service_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }

  app_settings = {
    "KEY_VAULT_URL"                              = azurerm_key_vault.kv123.vault_uri
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
  name                = "bestrongacr"
  resource_group_name = var.resource_group_name
  location            = "eastus"
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_management_lock" "tfstate_lock" {
  name       = "lock-tfstate-storage"
  scope      = azurerm_storage_account.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Lock for Terraform state storage account"
}

output "managed_identity_principal_id" {
  value       = azurerm_windows_web_app.app.identity[0].principal_id
  description = "The Principal ID of the System Assigned Managed Identity"
}

output "app_url" {
  value       = "https://${azurerm_windows_web_app.app.default_hostname}"
  description = "The URL of the deployed App Service"
}
