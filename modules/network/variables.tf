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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "Address prefix for the integration subnet"
  type        = list(string)
}

variable "pe_subnet_prefix" {
  description = "Address prefix for the private endpoints subnet"
  type        = list(string)
}