variable "subscription_id" {
  description = "The ID of the Azure subscription where the resources will be created."
  type        = string
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

variable "index" {
  description = "Index to identify the deployment instance."
  type        = number
  default     = 0
}

variable "deploy_infra" {
  description = "Flag to deploy infrastructure resources."
  type        = bool
  default     = false
}

variable "deploy_server" {
  description = "Flag to deploy server resources."
  type        = bool
  default     = false
}

variable "deploy_servers" {
  description = "Flag to deploy servers resources."
  type        = bool
  default     = false
}

variable "deploy_client" {
  description = "Flag to deploy client resources."
  type        = bool
  default     = false
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "francecentral"
}

variable "size" {
  description = "The size of the virtual machines."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "The name of the resource group where resources will be created."
  type        = string
  default     = "rg-netperf-region-001"
}