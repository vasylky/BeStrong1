resource "azurerm_key_vault" "keyvault" {
  name                      = "${var.environment}-kv-${var.suffix}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  sku_name                  = var.key_vault_sku
  tenant_id                 = var.tenant_id
  enable_rbac_authorization = false

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [var.integration_subnet_id]
  }
}

resource "azurerm_role_assignment" "app_service_key_vault_access" {
  principal_id         = var.app_principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.keyvault.id
}