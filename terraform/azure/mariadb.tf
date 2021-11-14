resource "azurerm_resource_group" "db" {
  name     = "rg-${local.infix}-db"
  location = var.location
}

resource "random_password" "mariadb" {
  length  = 16
  special = false
}

resource "azurerm_mariadb_server" "demo" {
  name                = "mdb-${local.infix}"
  location            = azurerm_resource_group.db.location
  resource_group_name = azurerm_resource_group.db.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  administrator_login          = "demo"
  administrator_login_password = random_password.mariadb.result
  version                      = "10.2"
  ssl_enforcement_enabled      = false
}

resource "azurerm_mariadb_database" "demo_app" {
  name                = "demo_app"
  resource_group_name = azurerm_resource_group.db.name
  server_name         = azurerm_mariadb_server.demo.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

resource "azurerm_mariadb_firewall_rule" "lab" {
  name                = "lab-db-rule"
  resource_group_name = azurerm_resource_group.db.name
  server_name         = azurerm_mariadb_server.demo.name
  start_ip_address    = azurerm_public_ip.aks_lb_egress.ip_address
  end_ip_address      = azurerm_public_ip.aks_lb_egress.ip_address
}