# module "netperf" {
#   source                         = "./modules/netperf"
#   index                          = var.index
#   #for_each                       = var.benchmark
#   # location                       = each.key
#   # size                           = each.value
#   # storage_account_resource_group = var.storage_account_resource_group
#   # storage_account_name           = var.storage_account_name
# }

module "infra" {
  source                         = "./modules/infra"
  count                          = var.deploy_infra ? 1 : 0
  location                       = var.location
  storage_account_name           = var.storage_account_name
  storage_account_resource_group = var.storage_account_resource_group
}

module "server" {
  source     = "./modules/server"
  count      = var.deploy_server ? 1 : 0
  index      = 1
  location   = var.location
  size       = var.size
  depends_on = [module.infra]
}

module "client" {
  source     = "./modules/client"
  count      = var.deploy_client ? 1 : 0
  location   = var.location
  size       = var.size
  depends_on = [module.server]
}