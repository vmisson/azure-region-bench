module "virtual_network" {
  source              = "azurerm/resources/azure//modules/virtual_network"
  location            = var.location
  environment         = var.location
  workload            = "netperf"
  instance            = "001"
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = ["10.100.${var.index}.0/24"]
}

module "subnet" {
  source               = "azurerm/resources/azure//modules/subnet"
  location             = var.location
  environment          = "srv"
  workload             = "netperf"
  instance             = "001"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = module.virtual_network.name
  address_prefixes     = ["10.100.${var.index}.0/25"]
}

module "linux_virtual_machine_server" {
  source              = "azurerm/resources/azure//modules/linux_virtual_machine"
  location            = var.location
  environment         = var.location
  workload            = "srv"
  instance            = "001"
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = module.subnet.id
  size                = var.size
  #zone                          = lookup(local.locationMappings[var.location], "az${count.index + 1}")
  custom_data = base64encode(file("${path.module}/cloud-init-server.txt"))
  tags = {
  }
}

module "vnet_peerings" {
  source                                = "azurerm/resources/azure//modules/virtual_network_peerings"
  virtual_network_1_resource_group_name = data.azurerm_resource_group.this.name
  virtual_network_1_id                  = data.azurerm_virtual_network.this.id
  virtual_network_2_resource_group_name = data.azurerm_resource_group.this.name
  virtual_network_2_id                  = module.virtual_network.id
}

resource "azurerm_private_dns_a_record" "this" {
  name                = var.location
  zone_name           = data.azurerm_private_dns_zone.region.name
  resource_group_name = data.azurerm_resource_group.this.name
  ttl                 = 30
  records             = [module.linux_virtual_machine_server.private_ip_address]
}