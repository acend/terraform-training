---
title: "6.4 Addon Services"
weight: 64
sectionnumber: 6.4
---

To get a full working Kubernetes cluster we need some last steps to deploy some components:

* ingress (reverse proxy)
* cert-manager (automated certificates)


## Task {{% param sectionnumber %}}.1: Kubernetes Provider

As we will also use Terraform to deploy to Kubernetes we need to setup new providers. Just add them behind the other provider config in the `main.tf`:

```bash
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
    load_config_file       = false
  }
}
```


## Task {{% param sectionnumber %}}.2: Ingress

The ingress allow us to route traffic coming from url's like http://app.labz.ch to a service in Kubernetes. Create the config in the file `ingress.tf`

```bash
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

resource "helm_release" "nginx_ingress" {
  name         = "nginx-ingress"
  namespace    = kubernetes_namespace.nginx_ingress.metadata[0].name
  repository   = "https://kubernetes.github.io/ingress-nginx"
  chart        = "ingress-nginx"
  version      = "3.31.0"
  atomic       = true
  reset_values = true
  timeout      = 900

  values = [
    yamlencode({
      controller = {
        replicaCount = 2
        service = {
          loadBalancerIP = azurerm_public_ip.aks_lb_ingress.ip_address
          annotations = {
            // https://docs.microsoft.com/en-us/azure/aks/ingress-internal-ip
            "service.beta.kubernetes.io/azure-load-balancer-resource-group" = azurerm_public_ip.aks_lb_ingress.resource_group_name
            "service.beta.kubernetes.io/azure-load-balancer-internal"       = "false"
          }
        }
      }
    })
  ]
}
```


## Task {{% param sectionnumber %}}.3: Certificate Manager

This manager is able to interact with "Let's Encrypt" to sign valid certitifcates in a public envirnoment. To `certmanager.tf`:

```bash
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name         = "cert-manager"
  repository   = "https://charts.jetstack.io"
  chart        = "cert-manager"
  version      = "1.3.1"
  namespace    = kubernetes_namespace.cert_manager.metadata.0.name
  atomic       = true
  reset_values = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = kubernetes_namespace.cert_manager.metadata.0.name
  }
}

resource "helm_release" "cluster_issuers" {
  name         = "cluster-issuers"
  chart        = "${path.module}/helm/cert_manager_issuer"
  version      = "1.0.0"
  namespace    = kubernetes_namespace.cert_manager.metadata.0.name
  atomic       = true
  reset_values = true

  // optional
  depends_on = [helm_release.cert_manager]
}
```

Don't forget to apply everthing.

