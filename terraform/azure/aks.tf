resource "azurerm_resource_group" "aks" {
  location = var.location
  name     = "rg-${local.infix}-aks"
}

resource "azurerm_public_ip" "aks_lb_ingress" {
  name                = "pip-${local.infix}-aks-lb-ingress"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

// optional: only needed to control AKS egress IP(s)
resource "azurerm_public_ip" "aks_lb_egress" {
  name                = "pip-${local.infix}-aks-lb-egress"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.infix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  node_resource_group = "${azurerm_resource_group.aks.name}-nodes"
  dns_prefix          = local.infix
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

    // optional: only needed to control AKS egress IP(s)
    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.aks_lb_egress.id]
    }
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
    kube_dashboard {
      enabled = false
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
    }
  }
}

resource "azurerm_role_assignment" "aks_identity_monitoring" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.aks.addon_profile.0.oms_agent.0.oms_agent_identity.0.object_id
}

resource "azurerm_role_assignment" "aks_identity_networking" {
  scope                = azurerm_resource_group.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}