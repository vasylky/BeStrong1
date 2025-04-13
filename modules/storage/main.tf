
resource "azurerm_private_endpoint" "storage_file_pe" {
  name                = "${var.environment}-storage-file-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "${var.environment}-storage-file-connection-${var.suffix}"
    private_connection_resource_id = azurerm_storage_account.app_storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "storage-file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.file_zone.id]
  }
}

resource "azurerm_private_dns_zone" "file_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_zone_link" {
  name                  = "${var.environment}-file-zone-vnet-link-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.file_zone.name
  virtual_network_id    = var.vnet_id
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
    bypass                    = ["AzureServices"]
  }
}

resource "azurerm_storage_share" "app_share" {
  name                 = "appfiles"
  storage_account_name = azurerm_storage_account.app_storage.name
  quota                = 5
}
