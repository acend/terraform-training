output "mariadb_uri" {
  sensitive = true
  value = format("mysql://%s:%s@%s/%s",
    azurerm_mariadb_server.example.administrator_login,
    azurerm_mariadb_server.example.administrator_login_password,
    azurerm_mariadb_server.example.fqdn,
    azurerm_mariadb_database.demo_app.name
  )
}