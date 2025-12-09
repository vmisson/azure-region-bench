module "resource_group" {
  source      = "azurerm/resources/azure//modules/resource_group"
  location    = var.location
  custom_name = var.resource_group_name
}

module "virtual_network" {
  source              = "azurerm/resources/azure//modules/virtual_network"
  location            = var.location
  custom_name         = var.virtual_network_name
  resource_group_name = module.resource_group.name
  address_space       = ["10.200.0.0/24"]
}

# resource "azurerm_private_endpoint" "this" {
#   name                = "${data.azurerm_storage_account.this.name}-${module.locations.short_name}-pe"
#   location            = var.location
#   resource_group_name = module.resource_group.name
#   subnet_id           = module.subnet.id

#   private_service_connection {
#     name                           = "${data.azurerm_storage_account.this.name}-${module.locations.short_name}-psc"
#     private_connection_resource_id = data.azurerm_storage_account.this.id
#     subresource_names              = ["table"]
#     is_manual_connection           = false
#   }

#   private_dns_zone_group {
#     name                 = "terraform-dns-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
#   }
# }

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = module.resource_group.name
}

resource "time_sleep" "wait_for_dns_zones" {
  depends_on      = [azurerm_private_dns_zone.table, azurerm_private_dns_zone.region]
  create_duration = "20s"
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table-${var.location}-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = module.virtual_network.id

  depends_on = [time_sleep.wait_for_dns_zones]
}

resource "azurerm_private_dns_zone" "region" {
  name                = var.private_dns_zone_name
  resource_group_name = module.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "region" {
  name                  = "region-${var.location}-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.region.name
  virtual_network_id    = module.virtual_network.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.table]
}
