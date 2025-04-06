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
  service_endpoints    = ["Microsoft.KeyVault","Microsoft.Storage"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
resource "azurerm_subnet" "private_endpoints_subnet" {
  name                 = "${var.environment}-bestrong-pe-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.pe_subnet_prefix
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_key_vault" "keyvc114414100320251923458" {
  name                      = "${var.environment}-keyvault4544"
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
    "KEY_VAULT_URL"                              = azurerm_key_vault.keyvc114414100320251923458.vault_uri
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

resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.environment}-bestrong-sqlserver"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  public_network_access_enabled = false
}

# SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name                = "${var.environment}-bestrong-db"
  server_id           = azurerm_mssql_server.sql_server.id
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  sku_name            = var.sql_db_sku
  storage_account_type = "Geo"
}

resource "azurerm_private_endpoint" "sql_pe" {
  name                = "${var.environment}-bestrong-sql-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "${var.environment}-bestrong-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns.id]
  }
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "${var.environment}-bestrong-sql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_storage_account" "app_storage" {
  name                     = "${var.environment}bestrongappsa"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = [azurerm_subnet.integration_subnet.id]
    bypass                     = ["AzureServices"]
  }
}

# File Share for App Service
resource "azurerm_storage_share" "app_share" {
  name                 = "appfiles"
  storage_account_name = azurerm_storage_account.app_storage.name
  quota                = 5
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_pe" {
  name                = "${var.environment}-bestrong-storage-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "${var.environment}-bestrong-storage-psc"
    private_connection_resource_id = azurerm_storage_account.app_storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_dns.id]
  }
}

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "storage_dns" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_dns_link" {
  name                  = "${var.environment}-bestrong-storage-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}




output "managed_identity_principal_id" {
  value       = azurerm_windows_web_app.app.identity[0].principal_id
  description = "The Principal ID of the System Assigned Managed Identity"
}

output "app_url" {
  value       = "https://${azurerm_windows_web_app.app.default_hostname}"
  description = "The URL of the deployed App Service"
}
