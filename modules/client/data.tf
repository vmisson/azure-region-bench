data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.this.name
}

data "azurerm_private_dns_zone" "region" {
  name                = var.private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.this.name
}

data "azurerm_private_dns_zone" "pe" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = data.azurerm_resource_group.this.name
}

data "azurerm_storage_account" "this" {
  name                = var.storage_account_name
  resource_group_name = var.storage_account_resource_group
}