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

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
}

variable "app_principal_id" {
  description = "Principal ID of the App Service's managed identity"
  type        = string
}