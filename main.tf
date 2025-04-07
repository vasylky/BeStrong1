terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id            = var.subscription_id
}

resource "random_id" "suffix" {
  byte_length = 4
}


data "azurerm_client_config" "current" {}

# Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-bestrong-vnet-${random_id.suffix.hex}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "integration_subnet" {
  name                 = "${var.environment}-bestrong-plan-${random_id.suffix.hex}"
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
  name                              = "${var.environment}-bestrong-pe-subnet-${random_id.suffix.hex}"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.pe_subnet_prefix
  private_endpoint_network_policies = "Disabled"
}

# Key Vault
resource "azurerm_key_vault" "keyvault11" {
  name = "${var.environment}-kv-${random_id.suffix.hex}"
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

resource "azurerm_role_assignment" "app_service_key_vault_access" {
  principal_id         = azurerm_windows_web_app.app.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.keyvault11.id
}

# App Service
resource "azurerm_service_plan" "service_plan" {
  name                = "${var.environment}-bestrong-plan-${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.app_service_sku
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.environment}-bestrong-app-${random_id.suffix.hex}"
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
    "KEY_VAULT_URL" = azurerm_key_vault.keyvault11.vault_uri
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_windows_web_app.app.id
  subnet_id      = azurerm_subnet.integration_subnet.id
}

# Сontainer Registry
resource "azurerm_container_registry" "acr" {
  name = lower(replace("${var.environment}acr${random_id.suffix.hex}", "-", ""))
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_windows_web_app.app.identity[0].principal_id
}

# Storage
resource "azurerm_storage_account" "tfstate" {
  name = lower(substr("${var.environment}tfstate${random_id.suffix.hex}", 0, 24))
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

resource "azurerm_storage_account" "app_storage" {
  name = lower(substr("${var.environment}appsa${random_id.suffix.hex}", 0, 24)) 
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

resource "azurerm_storage_share" "app_share" {
  name                 = "appfiles"
  storage_account_name = azurerm_storage_account.app_storage.name
  quota                = 5
}

# SQL
resource "azurerm_mssql_server" "sql_server" {
  name                          = "${var.environment}-bestrong-sqlserver-new${random_id.suffix.hex}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "sql_db" {
  name      = "${var.environment}-bestrong-db${random_id.suffix.hex}"
  server_id = azurerm_mssql_server.sql_server.id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  sku_name  = var.sql_db_sku
}

resource "azurerm_private_endpoint" "sql_pe" {
  name                = "${var.environment}-bestrong-sql-pe${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "${var.environment}-bestrong-sql-psc${random_id.suffix.hex}"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns.id]
  }
}

resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "${var.environment}-bestrong-sql-dns-link${random_id.suffix.hex}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}