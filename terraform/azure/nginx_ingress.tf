resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

resource "helm_release" "nginx_ingress" {
  name         = "nginx-ingress"
  namespace    = kubernetes_namespace.nginx_ingress.id
  repository   = "https://kubernetes.github.io/ingress-nginx"
  chart        = "ingress-nginx"
  version      = "3.35.0"
  atomic       = true
  reset_values = true
  timeout      = 900

  values = [
    yamlencode({
      fullnameOverride = "nginx-ingress"
      controller = {
        replicaCount = 1
        service = {
          loadBalancerIP = azurerm_public_ip.aks_lb.ip_address
          annotations = {
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "false"
          }
        }
      }
    })
  ]
}