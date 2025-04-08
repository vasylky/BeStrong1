resource "azurerm_storage_account" "tfstate" {
  name                     = lower(substr("${var.environment}tfstate${var.suffix}", 0, 24))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "app_storage" {
  name                     = lower(substr("${var.environment}appsa${var.suffix}", 0, 24))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = [var.integration_subnet_id]
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_storage_share" "app_share" {
  name                 = "appfiles"
  storage_account_name = azurerm_storage_account.app_storage.name
  quota                = 5
}