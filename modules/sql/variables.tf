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

variable "sql_admin_username" {
  description = "SQL administrator username"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL administrator password"
  type        = string
  sensitive   = true
}

variable "sql_db_sku" {
  description = "SKU for the SQL Database"
  type        = string
}

variable "pe_subnet_id" {
  description = "ID of the subnet for private endpoints"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}