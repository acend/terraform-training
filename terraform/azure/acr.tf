resource "random_integer" "acr" {
  min = 1000
  max = 9999
}

resource "azurerm_container_registry" "aks" {
  name                = "cr${replace(local.infix, "-", "")}${random_integer.acr.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  admin_enabled       = true
  sku                 = "Standard"
}