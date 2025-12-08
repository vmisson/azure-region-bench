variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "francecentral"
}

variable "size" {
  description = "The size of the virtual machines."
  type        = string
  default     = "Standard_D8as_v5"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-netperf-region-001"
}

variable "virtual_network_name" {
  description = "The name of the virtual network."
  type        = string
  default     = "vnet-netperf-client-001"
}

variable "private_dns_zone_name" {
  description = "The name of the private DNS zone for server records."
  type        = string
  default     = "region.azure"
}

variable "storage_account_name" {
  description = "The name of the storage account to be used for boot diagnostics."
  type        = string
  default     = "sanetprdfrc002"
}

variable "storage_account_resource_group" {
  description = "The resource group where the storage account is located."
  type        = string
  default     = "rg-net-prd-frc-001"
}
