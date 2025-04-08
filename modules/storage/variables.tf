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

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
}

variable "integration_subnet_id" {
  description = "ID of the subnet for integration"
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