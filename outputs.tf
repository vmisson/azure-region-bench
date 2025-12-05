output "resource_group_name" {
  description = "The name of the resource group where the resources are deployed."
  value       = var.deploy_infra ? module.infra[0].resource_group_name : null
}
