# terraform {
#  backend "azurerm" {}
# }

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id            = var.subscription_id
  
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_resource_group" "name" {
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_client_config" "current" {}

# Network module
module "network" {
  source                = "./modules/network"
  environment           = var.environment
  resource_group_name   = var.resource_group_name
  location              = var.location
  suffix                = random_id.suffix.hex
  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  pe_subnet_prefix      = var.pe_subnet_prefix
}

# App Service module 
module "appservice" {
  source                = "./modules/appservice"
  environment           = var.environment
  resource_group_name   = var.resource_group_name
  location              = var.location
  suffix                = random_id.suffix.hex
  app_service_sku       = var.app_service_sku
  dotnet_version        = var.dotnet_version
  integration_subnet_id = module.network.integration_subnet_id
  storage_account_name  = module.storage.storage_account_name
  storage_account_key   = module.storage.storage_primary_access_key
  storage_share_name    = module.storage.storage_file_share_name

  depends_on = [module.network]
}

# Key Vault module 
module "keyvault" {
  source                = "./modules/keyvault"
  environment           = var.environment
  resource_group_name   = var.resource_group_name
  location              = var.location
  suffix                = random_id.suffix.hex
  key_vault_sku         = var.key_vault_sku
  tenant_id             = data.azurerm_client_config.current.tenant_id
  integration_subnet_id = module.network.integration_subnet_id
  app_principal_id      = module.appservice.app_principal_id
  depends_on            = [module.appservice]
}

resource "null_resource" "update_app_keyvault" {
  provisioner "local-exec" {
    command = "echo 'Key Vault URL: ${module.keyvault.key_vault_url} should be set for App Service: ${module.appservice.app_name}'"
  }

  depends_on = [module.appservice, module.keyvault]
}

# SQL module
module "sql" {
  source              = "./modules/sql"
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  suffix              = random_id.suffix.hex
  sql_admin_username  = var.sql_admin_username
  sql_admin_password  = var.sql_admin_password
  sql_db_sku          = var.sql_db_sku
  pe_subnet_id        = module.network.pe_subnet_id
  vnet_id             = module.network.vnet_id
  depends_on          = [module.network]
}

# Storage module
module "storage" {
  source                      = "./modules/storage"
  environment                 = var.environment
  resource_group_name         = var.resource_group_name
  location                    = var.location
  suffix                      = random_id.suffix.hex
  storage_account_tier        = var.storage_account_tier
  storage_account_replication = var.storage_account_replication
  container_name              = var.container_name
  integration_subnet_id       = module.network.integration_subnet_id
  pe_subnet_id                = module.network.pe_subnet_id
  vnet_id                     = module.network.vnet_id
  depends_on                  = [module.network]
}

# Container Registry module
module "container_registry" {
  source              = "./modules/container_registry"
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  suffix              = random_id.suffix.hex
  acr_sku             = var.acr_sku
  app_principal_id    = module.appservice.app_principal_id
  depends_on          = [module.appservice]
}