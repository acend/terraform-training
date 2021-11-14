output "mariadb_uri" {
  sensitive = true
  value = format("mysql://%s:%s@%s/%s",
    azurerm_mariadb_server.demo.administrator_login,
    azurerm_mariadb_server.demo.administrator_login_password,
    azurerm_mariadb_server.demo.fqdn,
    azurerm_mariadb_database.demo_app.name
  )
}