---
title: "Provisioning Foundation"
weight: 22
sectionnumber: 2.2
---

Let's start with the things we need before we can create our cluster. After each step you can run `terraform apply` the check the outcome.


## Terraform Azure config

Create a new basic `main.tf` file like from the chapter before in the `azure` folder. This time we will add the `azurerm` to configure our endpoints:

```bash
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
```

Terraform needs the provider information to load all possible objects of this provider in the `terraform init`. So run it:

```bash
terraform init -backend-config=config/lab_backend.tfvars
```


## Resource group

In Azure everything is separated by resourcegroups (RG). A RG can have several objects which are grouped and combined. They can have single authorisation or an own cost budget.

Save the following to the `main.tf`.

```bash
resource "azurerm_resource_group" "default" {
  name     = "rg-${local.prefix}"
  location = var.location
}
```


## Network

We also need a network for our cluster. This could be done by the AKS ressource as well, but here you can configure your network range which is maybe needed by your company as every application has its own network range.

Save this to a file called `network.tf` as it belongs directly to the aks and nothing else.

```bash
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.prefix}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = [var.subnets.vnet]
}

resource "azurerm_network_watcher" "default" {
  name                = "nw-${local.prefix}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet" "private" {
  name                 = "snet-${local.prefix}-private"
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets.private]
}
```

Uff, that looks complicated! Can you figure out the meanings of it?


## Azure container registry

For the use of container we will use the container registry from Azure itself. So let's create one `acr.tf`:

```bash
resource "random_integer" "acr" {
  max = 1000
  min = 9999
}

resource "azurerm_container_registry" "aks" {
  name                = "cr${replace(local.prefix, "-", "")}${random_integer.acr.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
  admin_enabled       = true
  sku                 = "standard"
}
```


## Log Analytics Workspace

Yes, there is another thing AKS need. Here AKS can save all his logs to review anything which happend:

log_analytics.tf

```bash
resource "random_string" "log_analytics_workspace" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "log-${local.prefix}-${random_string.log_analytics_workspace.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
}
```

