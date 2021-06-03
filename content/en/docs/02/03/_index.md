---
title: "Azure Kubernetes Service"
weight: 23
sectionnumber: 2.3
---

Now we have all sub ressources to create our AKS


## Credentials

To get access to the AKS cluster we need to read the ad group. This group will be permitted to access AKS in a admin context:

Save it to `iam.tf`:

```bash
data "azuread_group" "aks_admins" {
  display_name = var.aks_admins_ad_group
}
```


## AKS

To separate all types of ressources we will first create a ressource group again in the file `aks.tf`:

```bash
resource "azurerm_resource_group" "aks" {
  location = var.location
  name     = "rg-${local.prefix}-aks"
}
```

Then an "easy" example for an AKS cluster. Append it to the file `aks.tf` and let it apply:

```bash
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  node_resource_group = "${azurerm_resource_group.aks.name}-nodes"
  dns_prefix          = local.prefix
  kubernetes_version  = var.aks.kubernetes_version

  default_node_pool {
    name               = "linux"
    type               = "VirtualMachineScaleSets"
    vnet_subnet_id     = azurerm_subnet.private.id
    vm_size            = var.aks.node_pool.vm_size
    node_count         = var.aks.node_pool.node_count
    availability_zones = var.aks.availability_zones
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "Standard"
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed                = true
      tenant_id              = data.azurerm_subscription.current.tenant_id
      admin_group_object_ids = [data.azuread_group.aks_admins.object_id]
      azure_rbac_enabled     = true
    }
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
    }
    kube_dashboard {
      enabled = false
    }
  }
}
```

Wow, that's a tough one!

If you check the blocks you can see, that every block contains the informations about objects we've created before. Apply it, and take a coffee.


## Permissions

AKS needs an container registry. And AKS needs access to the other objects as well! Now we have to connect our AKS to the other objects by giving role permissions to it:

```bash
resource "azurerm_role_assignment" "aks_identity_monitoring" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.aks.addon_profile[0].oms_agent[0].oms_agent_identity[0].object_id
}

resource "azurerm_role_assignment" "aks_identity_networking" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_identity_acr" {
  scope                = azurerm_container_registry.aks.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

Now AKS is allowed to:

* "pull" images from our container registry.
* write logs into the log workspace
* is able to add nodes into the node-network
