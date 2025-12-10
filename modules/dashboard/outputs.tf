output "static_web_app_id" {
  description = "The ID of the Static Web App."
  value       = azurerm_static_web_app.this.id
}

output "static_web_app_default_hostname" {
  description = "The default hostname of the Static Web App."
  value       = azurerm_static_web_app.this.default_host_name
}

output "resource_group_name" {
  description = "The name of the resource group where the resources are deployed."
  value       = azurerm_resource_group.this.name
}

# Note: The API token must be retrieved via Azure CLI or Portal
# az staticwebapp secrets list --name <swa-name> --query "properties.apiKey" -o tsv
