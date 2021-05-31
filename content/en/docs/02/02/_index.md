---
title: "Provisioning Foundation"
weight: 22
sectionnumber: 2.2
---

Let's start with the things we need before we can create our cluster.


## Terraform Azure config

Start with a new folder named `azure` and create a basic `provider.tf` like from the chapter before. This time we will add the `azurerm` to configure our endpoints:

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
  features {}
}
```

Terraform needs the provider information to load all possible objects of this provider in the `terraform init`.


## Resource group

In Azure everything is separated by resourcegroups (RG). A RG can have several objects which are grouped and combined. They can have single authorisation or an own cost budget.

Save the following to a file called `main.tf`.

```bash
resource "azurerm_resource_group" "<student>-aks" {
  name     = "<student>-aks-rg"
  location = "West Europe"
}
```


## Network

We also need a network for our cluster. This could be done by the AKS ressource as well, but here you can configure your network range which is maybe needed by your company as every application has its own network range.

Save this to a file called `aks.tf` as it belongs directly to the aks and nothing else.

```bash
resource "azurerm_virtual_network" "aks" {
  name                = "aks-vnet"
  location            = azurerm_resource_group.<student>-aks.location
  resource_group_name = azurerm_resource_group.<student>-aks.name
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "aksnodes" {
  name                      = "aksnodes"
  resource_group_name       = azurerm_resource_group.<student>-aks.name
  virtual_network_name      = azurerm_virtual_network.aks.name
  address_prefixes          = ["10.240.0.0/16"]
}
```


## Azure container registry

For the use of container we will use the container registry from Azure itself. So let's create one `acr.tf`:

```bash
resource "azurerm_container_registry" "acr" {
  name                     = "aks-acr"
  resource_group_name      = azurerm_resource_group.<student>-aks.location
  location                 = azurerm_resource_group.<student>-aks.name
  sku                      = "Basic"
}
```


## Advanced topics

As you may noticed we are using the `<student>-aks` often. If you don't wan't to repeat that, we could also created so called "Local Values". They are helpful to avoid repeating the same values multiplie times. They are look like:

```bash
locals {
  rg_name  = azurerm_resource_group.<student>-aks.location
  loc_name = azurerm_resource_group.<student>-aks.name
}

resource "azurerm_container_registry" "acr" {
  name                     = "aks-acr"
  resource_group_name      = local.rg_name
  location                 = local.loc_name
  sku                      = "Basic"
}
```

Try it out!
