---
title: "7.1. Challenge #1"
weight: 71
sectionnumber: 7.1
---


## Check Releases

[azurerm](https://github.com/hashicorp/terraform-provider-azurerm/releases)

```terraform
terraform {
  required_version = "> 1.12.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.46.0"   # < -- UPDATE!
    }
  }
}
```