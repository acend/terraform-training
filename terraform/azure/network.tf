resource "azurerm_virtual_network" "default" {
  name                = "vnet-${local.infix}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = [var.network_cidrs.vnet]
}

//resource "azurerm_network_watcher" "default" {
//  name                = "nw-${local.infix}"
//  location            = azurerm_resource_group.default.location
//  resource_group_name = azurerm_resource_group.default.name
//}

resource "azurerm_subnet" "private" {
  name                 = "snet-${local.infix}-private"
  resource_group_name  = azurerm_virtual_network.default.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.network_cidrs.subnet]
}