---
title: "Azure Kubernetes Service"
weight: 23
sectionnumber: 2.3
---

Now we have all sub ressources to create our AKS


## AKS

This is one of the simplest examples for an AKS cluster. Append it to the file `aks.tf` and let it apply:

```bash
resource "azurerm_kubernetes_cluster" "akscluster" {
  name                = "<student>-aks"
  location            = azurerm_resource_group.<student>-aks.location
  resource_group_name = azurerm_resource_group.<student>-aks.name
  dns_prefix          = "<student>-aks"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "basic_a2"
    vnet_subnet_id = azurerm_subnet.aksnodes.id
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed = true
    }
  }
}
```


## Permissions

AKS needs an container registry. Now we have to connect our AKS to the ACR by giving role permissions to it:

In which file you would insert this snippet? `aks.tf` or `acr.tf`??? It is your choice. But be ready to explain yourself.

```bash
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.<student>-aks.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.akscluster.kubelet_identity[0].object_id
}
```

Now AKS is allowed to "pull" images from our container registry.
