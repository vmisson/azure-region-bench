resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_static_web_app" "this" {
  name                = var.static_web_app_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_size

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "table_reader" {
  scope                = data.azurerm_storage_account.this.id
  role_definition_name = "Storage Table Data Reader"
  principal_id         = azurerm_static_web_app.this.identity[0].principal_id
}

resource "azurerm_static_web_app_function_app_registration" "this" {
  static_web_app_id = azurerm_static_web_app.this.id
  function_app_id   = null # Managed Functions
}
