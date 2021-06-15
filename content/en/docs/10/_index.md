---
title: "10. Terraform Modules"
weight: 10
sectionnumber: 10
---

You can also build a kind of Terraform libraries, so named "modules". These modules can be reused if they are build well.


## Container Registry

We will create a new folder called `module` and create some base files in there:

main.tf
```bash
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}
```

acr.tf
```bash
resource "random_integer" "acr" {
  max = 1000
  min = 9999
}

resource "azurerm_container_registry" "acr" {
  name                = "cr${var.acr_name}${random_integer.acr.result}"
  location            = var.location
  resource_group_name = var.rg_name
  admin_enabled       = true
  sku                 = "standard"
}
```

variables.tf
```bash
variable "acr_name" {
  type        = string
  description = "base name for acr"
}

variable "rg_name" {
  type        = string
  description = "ressource group for acr"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "default location to westeurope"
}
```

outputs.tf
```bash
output "login_server" {
    description = "the acr login server"
    value       = azurerm_container_registry.acr.login_server
}

output "username" {
    description = "acr username"
    value       = azurerm_container_registry.acr.login_server
    sensitive   = true
}

output "password" {
    description = "acr password"
    value       = azurerm_container_registry.acr.admin_password
    sensitive   = true
}
```


## Input/Outputs

The important thing in modules is, you can abstract a lot of things which you normally would have to configure.

The usage of the created module would look like:
```bash
```


## Change our base

Now change our existing acr config to use the module instead of the direct usage.


## Final thougths

Remember the huge AKS file we wrote? Imagine you would put that in module for your developers. They could easyly create an AKS cluster an maintain only those parts they really need, like vm size etc. ...

