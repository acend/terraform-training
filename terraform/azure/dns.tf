data "azurerm_dns_zone" "parent" {
  name = "labz.ch"
}

resource "azurerm_dns_zone" "child" {
  name                = "${var.purpose}.${data.azurerm_dns_zone.parent.name}"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_dns_ns_record" "child" {
  name                = var.purpose
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = data.azurerm_dns_zone.parent.resource_group_name
  ttl                 = 300
  records             = azurerm_dns_zone.child.name_servers
}

resource "azurerm_dns_a_record" "ingress" {
  name                = "*"
  resource_group_name = azurerm_resource_group.default.name
  ttl                 = 300
  zone_name           = azurerm_dns_zone.child.name
  records             = [azurerm_public_ip.aks_lb_ingress.ip_address]
}
