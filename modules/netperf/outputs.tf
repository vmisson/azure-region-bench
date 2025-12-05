# output "resource_group_name" {
#   description = "The name of the resource group where the resources are deployed."
#   value       = module.resource_group.name
# }

output "locationMappings" {
  description = "The location mappings used in the deployment."
  value       = local.locationSize
}