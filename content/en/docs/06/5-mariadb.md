---
title: "6.5. MariaDB"
weight: 65
sectionnumber: 6.5
---

## Step 1: Configure AKS egress IP

By default, AKS routes traffic to the internet via a (randomly assigned) Azure public IP. For some scenarios like
our MariaDB instance, we want to whitelist the source IP to restrict access to the services.

Add the following content below the resource `azurerm_public_ip.aks_lb_ingress` in `aks.tf`:
```terraform
// optional: only needed to control AKS egress IP(s)
resource "azurerm_public_ip" "aks_lb_egress" {
  name                = "pip-${local.infix}-aks-lb-egress"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
```

To configure AKS to use a static egress IP, modify the `azurerm_kubernetes_cluster.aks` resource in `aks.tf`
and replace the `network_profile` block with the following content:

```terraform
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "Standard"

    // optional: only needed to control AKS egress IP(s)
    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.aks_lb_egress.id]
    }
  }
```

Now run
```bash
terraform apply -var-file=config/dev.tfvars
```

To verify the egress IP is correct, run the following command:
```bash
kubectl exec -n tests hello -- curl -s ifconfig.me
```

This lists the egress IP of the AKS cluster as reported by the website https://ifconfig.me

Now verify this IP is equal to the AKS load balancer ip by running:
```bash
terraform state show azurerm_public_ip.aks_lb_egress
```


## Step 2: Add a MariaDB instance

Create a new file named `mariadb.tf` and add the following content:
```terraform
resource "azurerm_resource_group" "db" {
  name     = "rg-${local.infix}-db"
  location = var.location
}

resource "random_password" "mariadb" {
  length  = 16
  special = false
}

resource "azurerm_mariadb_server" "mariadb" {
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
  server_name         = azurerm_mariadb_server.mariadb.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

resource "azurerm_mariadb_firewall_rule" "lab" {
  name                = "lab-db-rule"
  resource_group_name = azurerm_resource_group.db.name
  server_name         = azurerm_mariadb_server.mariadb.name
  start_ip_address    = azurerm_public_ip.aks_lb_egress.ip_address
  end_ip_address      = azurerm_public_ip.aks_lb_egress.ip_address
}
```

Create a new file named `outputs.tf` and add the following content:
```terraform
output "mariadb_uri" {
  sensitive = true
  value     = format("mysql://%s:%s@%s/%s",
    azurerm_mariadb_server.mariadb.administrator_login,
    azurerm_mariadb_server.mariadb.administrator_login_password,
    azurerm_mariadb_server.mariadb.fqdn,
    azurerm_mariadb_database.demo_app.name
  )
}
```

Now run
```bash
terraform apply -var-file=config/dev.tfvars
```

The MariaDB URI can be displayed by running:
```bash
terraform output mariadb_uri
```


### Explanation

The MariaDB instance is a managed service by Azure and has a public IP. By default, no IPs are allowed to access
the instance. The resource `azurerm_mariadb_firewall_rule.lab` adds a firewall rule to whitelist the egress IP
of the Kubernetes AKS cluster, which allows apps deployed on the cluster to access MariaDB.

To configure our demo app, we need to generate a MariaDB URI. The Terraform function `format` has familiar syntax to
the GLIBC function `snprintf()` and allows better readable code.
