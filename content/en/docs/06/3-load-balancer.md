---
title: "6.3. Load Balancer"
weight: 63
sectionnumber: 6.3
---


## Step 1: Create a kubernetes namespace

Add the following content below the existing `provider` block of `main.tf`:
```terraform
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
}
```

Create a new file named `nginx_ingress.tf` and add the following content:
```terraform
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}
```

Since we added a new provider, Terraform needs to be initialized again:
```bash
terraform init -backend-config=config/dev_backend.tfvars
terraform apply -var-file=config/dev.tfvars
```


### Explanation

We use the Kubernetes provider to create a namespace named `nginx-ingress`. The provider is configured using attributes
of the AKS cluster; this a good example demonstrating the power of Terraform to use multiple providers.


## Step 2: Add a public static IP

Add the following content below the `azurerm_resource_group` block in `aks.tf`:
```terraform
resource "azurerm_public_ip" "aks_lb_ingress" {
  name                = "pip-${local.infix}-aks-lb-ingress"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
```

Now run
```bash
terraform apply -var-file=config/dev.tfvars
```


## Step 3: Install NGINX ingress controller

Add the following content below the existing Kubernetes `provider` block of `main.tf`:
```terraform
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
  }
}
```


Add the following content to the end of `nginx_ingress.tf`:
```terraform
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
          loadBalancerIP = azurerm_public_ip.aks_lb_ingress.ip_address
          annotations = {
            "service.beta.kubernetes.io/azure-load-balancer-resource-group" = azurerm_public_ip.aks_lb_ingress.resource_group_name
            "service.beta.kubernetes.io/azure-load-balancer-internal"       = "false"
          }
        }
      }
    })
  ]
}
```

Since we added a new provider, Terraform needs to be initialized again:
```bash
terraform init -backend-config=config/dev_backend.tfvars
terraform apply -var-file=config/dev.tfvars
```


### Explanation

There is some magic here; Azure AKS will automatically provision a load balancer if the Azure specific service
annotations are present. See https://docs.microsoft.com/en-us/azure/aks/ingress-internal-ip for more information.

We set the load balancer IP to the allocated public static IP and deploy a single ingress controller pod; sufficient
for this lab.


## Step 4: Configure DNS

Create a new file named `dns.tf` and add the following content:
```terraform
data "azurerm_dns_zone" "parent" {
  name                = "labz.ch"
}

resource "azurerm_dns_zone" "child" {
  name = "${var.purpose}.${data.azurerm_dns_zone.parent.name}"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_dns_ns_record" "child" {
  name                = var.purpose
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = data.azurerm_dns_zone.parent.resource_group_name
  ttl                 = 300
  records             = azurerm_dns_zone.child.name_servers
}

resource "azurerm_dns_a_record" "ingress" {
  name                = "*"
  resource_group_name = azurerm_resource_group.default.name
  ttl                 = 300
  zone_name           = azurerm_dns_zone.child.name
  records             = [azurerm_public_ip.aks_lb_ingress.ip_address]
}
```

Now run
```bash
terraform apply -var-file=config/dev.tfvars
```

Perform a DNS lookup for your subdomain by running:
```bash
host foobar.YOUR_USERNAME.labz.ch
```

Which should return something like:
```
foobar.YOUR_USERNAME.labz.ch has address 20.50.15.16
```

Now traffic is ready to be routed to your new Kubernetes cluster!


### Explanation

We create a subdomain (child DNS zone in Azure terminology) in the top-level domain `labz.ch`
for each workshop participant. The wildcard A record points to the layer 4 load balancer, so all traffic is sent to
the load balancer and forwarded to the NGINX ingress controller.


## Step 4: Test HTTP ingress

Before we can deploy workload on Kubernetes, we need to fetch the cluster credentials by running the following command:
```bash
az aks get-credentials --name aks-YOUR_USERNAME-dev --resource-group rg-lab-dev-aks -a
```

**Note**: Please replace `YOUR_USERNAME` with the username assigned to you for this workshop.

Now check if everything works as expected:
```bash
kubectl get ns
```

This should show you the following output:
```
NAME              STATUS   AGE
default           Active   3h42m
kube-node-lease   Active   3h42m
kube-public       Active   3h42m
kube-system       Active   3h42m
nginx-ingress     Active   60m
```

Create a new directory for your tests:
```bash
mkdir tests
```

Create a new file named `tests/http.yaml` and add the following content:
```yaml
# kubectl apply -f http.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tests

---

apiVersion: v1
kind: Pod
metadata:
  name: hello
  namespace: tests
  labels:
    app: hello
spec:
  containers:
  - image: "nginxdemos/hello:plain-text"
    name: hello
    ports:
    - containerPort: 80
      protocol: TCP

---

apiVersion: v1
kind: Service
metadata:
  name: hello
  namespace: tests
spec:
  selector:
    app: hello
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: insecure
  namespace: tests
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: insecure.lab.labz.ch
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello
            port:
              number: 80
```

**Note**: Please replace `YOUR_USERNAME` with the username assigned to you for this workshop.

Now apply the config by running:
```bash
kubectl -f tests/http.yaml
```

Verify the pod is running:
```bash
kubectl get pod -n test-http
```

This should show the following output:
```
NAME       READY   STATUS    RESTARTS   AGE
insecure   1/1     Running   0          97s
```

Now use `curl` to access your service:
```bash
curl insecure.YOUR_USERNAME.labz.ch
```

This should show the following output:
```
Server address: 10.244.0.9:80
Server name: insecure
Date: 26/Aug/2021:13:49:10 +0000
URI: /
Request ID: 62c2b4fea5112b355ffe470c3c358817
```

Congratulations! You can now successfully route traffic to your cluster.
