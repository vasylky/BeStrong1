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

variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
}

variable "dotnet_version" {
  description = ".NET version for the web app"
  type        = string
}

variable "integration_subnet_id" {
  description = "ID of the subnet for VNet integration"
  type        = string
}


variable "storage_account_name" {
  description = "Назва Storage Account для монтування"
  type        = string
  default     = ""
}

variable "storage_account_key" {
  description = "Ключ доступу до Storage Account"
  type        = string
  default     = ""
  sensitive   = true
}

variable "storage_share_name" {
  description = "Назва File Share для монтування"
  type        = string
  default     = "appfiles"
}