module "subnet" {
  source               = "azurerm/resources/azure//modules/subnet"
  location             = var.location
  environment          = "cli"
  workload             = "netperf"
  instance             = "001"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = data.azurerm_virtual_network.this.name
  address_prefixes     = [data.azurerm_virtual_network.this.address_space[0]]
}

module "linux_virtual_machine_client" {
  source              = "azurerm/resources/azure//modules/linux_virtual_machine"
  location            = var.location
  environment         = var.location
  workload            = "cli"
  instance            = "001"
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = module.subnet.id
  size                = var.size
  #zone                          = lookup(var.locationMappings[var.location], "az${count.index + 1}")
  custom_data                   = base64encode(file("${path.module}/cloud-init-client.txt"))
  enable_accelerated_networking = true
  identity_type                 = "UserAssigned"
  identity_ids = [
    azurerm_user_assigned_identity.this.id
  ]
  tags = {
  }
  depends_on = [ azurerm_private_endpoint.this ]
}

resource "azurerm_user_assigned_identity" "this" {
  location            = var.location
  name                = "mi-net-tst-001"
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "this" {
  scope                = data.azurerm_storage_account.this.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_private_endpoint" "this" {
  name                = "${data.azurerm_storage_account.this.name}-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = module.subnet.id

  private_service_connection {
    name                           = "${data.azurerm_storage_account.this.name}-psc"
    private_connection_resource_id = data.azurerm_storage_account.this.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "terraform-dns-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.pe.id]
  }
}