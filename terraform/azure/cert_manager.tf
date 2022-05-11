resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name         = "cert-manager"
  repository   = "https://charts.jetstack.io"
  chart        = "cert-manager"
  version      = "v1.8.0"
  namespace    = kubernetes_namespace.cert_manager.id
  atomic       = true
  reset_values = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = kubernetes_namespace.cert_manager.id
  }
}

resource "helm_release" "cluster_issuer" {
  name         = "cluster-issuer"
  chart        = "${path.root}/helm/cert_manager_issuer"
  version      = "1.0.0"
  namespace    = kubernetes_namespace.cert_manager.metadata.0.name
  atomic       = true
  reset_values = true

  depends_on = [helm_release.cert_manager]
}
