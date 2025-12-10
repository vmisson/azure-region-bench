variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-latency-dashboard-001"
}

variable "static_web_app_name" {
  description = "The name of the Static Web App."
  type        = string
  default     = "swa-latency-dashboard-001"
}

variable "sku_tier" {
  description = "The SKU tier of the Static Web App."
  type        = string
  default     = "Standard"
}

variable "sku_size" {
  description = "The SKU size of the Static Web App."
  type        = string
  default     = "Standard"
}

variable "storage_account_name" {
  description = "The name of the storage account containing latency data."
  type        = string
  default     = "sanetprdfrc002"
}

variable "storage_account_resource_group" {
  description = "The resource group where the storage account is located."
  type        = string
  default     = "rg-net-prd-frc-001"
}

variable "table_name" {
  description = "The name of the table containing latency data."
  type        = string
  default     = "region"
}

variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default = {
    purpose = "Azure Region Latency Dashboard"
  }
}
