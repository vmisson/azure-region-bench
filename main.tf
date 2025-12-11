module "infra" {
  source                         = "./modules/infra"
  count                          = var.deploy_infra ? 1 : 0
  location                       = var.location
  resource_group_name            = var.resource_group_name
  storage_account_name           = var.storage_account_name
  storage_account_resource_group = var.storage_account_resource_group
}

module "server" {
  source              = "./modules/server"
  count               = var.deploy_server ? 1 : 0
  index               = var.index
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size
  depends_on          = [module.infra]
}

module "servers" {
  source              = "./modules/server"
  for_each            = var.deploy_servers ? local.locationList : {}
  index               = index(keys(local.locationList), each.key)
  location            = each.key
  resource_group_name = var.resource_group_name
  size                = each.value
  depends_on          = [module.infra]
}

module "client" {
  source              = "./modules/client"
  count               = var.deploy_client ? 1 : 0
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size
  depends_on          = [module.server]
}