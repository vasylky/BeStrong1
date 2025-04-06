variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group Name"
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage Account Name"
  type        = string
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage account replication strategy"
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "Azure Blob Container name"
  type        = string

}

variable "location" {
  description = "location"
  type        = string
}

variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "S1"
}

variable "dotnet_version" {
  description = ".NET version for the web app"
  type        = string
  default     = "v6.0"
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "app_insights_retention" {
  description = "Retention in days for Application Insights data"
  type        = number
  default     = 90
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the integration subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}
variable "pe_subnet_prefix" {
  description = "Address prefix for the private endpoints subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "sql_admin_username"{
  description = "sql_admin"
  type        = string 
  sensitive = true
}

variable "sql_admin_password"{
  description = "sql_password"
  type        = string 
  sensitive = true
}

variable "sql_db_sku" {
  description = "SKU for the SQL Database"
  type        = string
  default     = "S1"
}