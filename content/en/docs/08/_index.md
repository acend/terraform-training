---
title: "Database Setup"
weight: 8
sectionnumber: 8
---

What would an application without a database in the cloud?

In this chapter we are going to create a mariadb in azure and connect our application to it.


## Create a MariaDB server

Azure comes with a build service for a MariaDB. With the help of Terraform we can easy create a server and a database. Save the content to `mariadb.tf` and apply it:

```bash
locals {
  mariadb_name = "acendexampledb"
  mariadb_user = "acend-user"
  mariadb_pass = "mysqlpassword"
}

resource "azurerm_mariadb_server" "mariadb" {
  name                = "mdb-${local.prefix}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  administrator_login          = local.mariadb_user
  administrator_login_password = local.mariadb_pass
  version                      = "10.2"
  ssl_enforcement_enabled      = false
}

resource "azurerm_mariadb_database" "awesomeapp" {
  name                = local.mariadb_name
  resource_group_name = azurerm_resource_group.default.name
  server_name         = azurerm_mariadb_server.mariadb.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

resource "azurerm_mariadb_firewall_rule" "aks-mariadb" {
  name                = "acend-db-rule"
  resource_group_name = azurerm_resource_group.default.name
  server_name         = azurerm_mariadb_server.mariadb.name
  start_ip_address    = azurerm_public_ip.aks_lb_ingress.ip_address
  end_ip_address      = azurerm_public_ip.aks_lb_ingress.ip_address
}

output "mariadb_name" { value = local.mariadb_name }
output "mariadb_user" { value = local.mariadb_user }
output "mariadb_pass" { value = local.mariadb_pass }
output "mariadb_uri" {
    value = "mysql://${local.mariadb_user}:${local.mariadb_pass}@${azurerm_mariadb_server.mariadb.fqdn}/${local.mariadb_name}
}
```


## Attach the database to the application

By default, our `example-web-python` application uses an SQLite memory database. However, this can be changed by defining the following environment variable(`MYSQL_URI`) to use the newly created MariaDB database:

```
#MYSQL_URI=mysql://<user>:<password>@<host>/<database>
MYSQL_URI=mysql://acend-user:mysqlpassword@fqdn/acendexampledb
```

The connection string our `example-web-python` application uses to connect to our new MariaDB, is a concatenated string from the values of the `mariadb` Secret.

The following commands set the environment variables for the deployment configuration of the `example-web-python` application

```bash
kubectl create secret generic mariadb --from-literal=database-name=$(terraform output -raw mariadb_name) --from-literal=database-password=$(terraform output -raw mariadb_pass) --from-literal=database-user=$(terraform output -raw mariadb_user)
kubectl set env --from=secret/mariadb --prefix=MYSQL_ deploy/example-web-python
kubectl set env deploy/example-web-python MYSQL_URI=$(terraform output -raw mariadb_uri)
```

The first command inserts the values from the Secret, the second finally uses these values to put them in the environment variable `MYSQL_URI` which the application considers.

{{% alert title="Info" color="secondary" %}}
If we would have deployed our awesome app by Terraform we wouldn't need all the output parameters. Do you know why?
{{% /alert %}}

