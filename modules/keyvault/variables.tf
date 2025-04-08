variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "suffix" {
  description = "Resource name suffix"
  type        = string
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "integration_subnet_id" {
  description = "ID of the subnet allowed to access Key Vault"
  type        = string
}

variable "app_principal_id" {
  description = "Principal ID of the App Service's managed identity"
  type        = string
}