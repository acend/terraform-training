---
title: "6.3. Load Balancer"
weight: 63
sectionnumber: 6.3
onlyWhen: azure
---


## Step {{% param sectionnumber %}}.1: Create a kubernetes namespace

```mermaid
flowchart LR
    classDef red fill:#f96;
    aad(AD Group) --> |permission|aAks
    aNode --> |use|dSub
    subgraph rg: aks
    aAks(aks) --> |logs|aLaw(law)
    aAks --> aNode(nodes)
    aAcr(acr) --> |images|aNode
    end
    subgraph rg: net
    dNet(vnet) --> dSub(subnet)
    end
    aAks --> aks
    subgraph aks
    cIngress(ns: nginx-ingress):::red
    end
```

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


## Step {{% param sectionnumber %}}.2: Add a public static IP

```mermaid
flowchart LR
    classDef red fill:#f96;
    aad(AD Group) --> |permission|aAks
    aNode --> |use|dSub
    subgraph rg: aks
    aAks(aks) --> |logs|aLaw(law)
    aAks --> aNode(nodes)
    aAcr(acr) --> |images|aNode
    aIp(public ip):::red
    end
    subgraph rg: net
    dNet(vnet) --> dSub(subnet)
    end
    aAks --> aks
    subgraph aks
    cIngress(nginx-ingress)
    end
```

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


## Step {{% param sectionnumber %}}.3: Install NGINX ingress controller

```mermaid
flowchart LR
    classDef red fill:#f96;
    aad(AD Group) --> |permission|aAks
    aNode --> |use|dSub
    subgraph rg: aks
    aAks(aks) --> |logs|aLaw(law)
    aAks --> aNode(nodes)
    aAcr(acr) --> |images|aNode
    aIp(public ip)
    end
    subgraph rg: net
    dNet(vnet) --> dSub(subnet)
    end
    aAks --> aks
    subgraph aks
        aIp --> sNg
        subgraph ns: nginx-ingress
        sNg(service):::red --> pNg(pod):::red
        end
    end
```

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
  version      = "4.7.0"
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
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
            "service.beta.kubernetes.io/azure-load-balancer-resource-group"            = azurerm_public_ip.aks_lb_ingress.resource_group_name
            "service.beta.kubernetes.io/azure-load-balancer-internal"                  = "false"
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

{{% alert title="Bonus" color="primary" %}}
Check the latest version of the helm release here: https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx and update your terraform file.
{{% /alert %}}


### Explanation

There is some magic here; Azure AKS will automatically provision a load balancer if the Azure specific service
annotations are present. See https://docs.microsoft.com/en-us/azure/aks/ingress-internal-ip for more information.

We set the load balancer IP to the allocated public static IP and deploy a single ingress controller pod; sufficient
for this lab.


## Step {{% param sectionnumber %}}.4: Configure DNS

```mermaid
flowchart LR
    classDef red fill:#f96;
    aad(AD Group) --> |permission|aAks
    subgraph rg: aks
    aAks --> aNode(nodes)
    aAcr(acr) --> |images|aNode
    aIp(public ip)
    end
    dDns --> aIp
    subgraph rg: dns
    dDns(dns):::red
    end
    aAks --> aks
    subgraph aks
        aIp --> sNg
        subgraph ns: nginx-ingress
        sNg(service) --> pNg(pod)
        end
    end
```

Create a new file named `dns.tf` and add the following content:
```terraform
data "azurerm_dns_zone" "parent" {
  name                = "mobi.terraform-lab.cloud"
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
host foobar.YOUR_USERNAME.mobi.terraform-lab.cloud
```

Which should return something like:
```
foobar.YOUR_USERNAME.mobi.terraform-lab.cloud has address 20.50.15.16
```

Now traffic is ready to be routed to your new Kubernetes cluster!


### Explanation

We create a subdomain (child DNS zone in Azure terminology) in the top-level domain `mobi.terraform-lab.cloud`
for each workshop participant. The wildcard A record points to the layer 4 load balancer, so all traffic is sent to
the load balancer and forwarded to the NGINX ingress controller.


## Step {{% param sectionnumber %}}.4: Test HTTP ingress

```mermaid
flowchart LR
    classDef red fill:#f96;
    aad(AD Group) --> |permission|aAks
    subgraph rg: aks
    aAks --> aNode(nodes)
    aAcr(acr) --> |images|aNode
    aIp(public ip)
    end
    dDns --> aIp
    subgraph rg: dns
    dDns(dns):::red
    end
    aAks --> aks
    subgraph aks
        aIp --> sNg
        subgraph ns: nginx-ingress
        sNg(service) --> pNg(pod)
        end
        subgraph ns: tests
        sTst(service):::red --> pTst(pod):::red
        pNg --> iTst(ingress):::red --> sTst
        end
    end
```

Before we can deploy workload on Kubernetes, we need to fetch the cluster credentials by running the following command:
```bash
az aks get-credentials --name aks-YOUR_USERNAME-dev --resource-group rg-YOUR_USERNAME-dev-aks -a
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
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: insecure.YOUR_USERNAME.mobi.terraform-lab.cloud
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
kubectl apply -f tests/http.yaml
```

Verify the pod is running:
```bash
kubectl get pod,ing -n tests
```

This should show the following output:
```
NAME       READY   STATUS    RESTARTS   AGE
hello      1/1     Running   0          97s
```

Now use `curl` to access your service:
```bash
curl insecure.YOUR_USERNAME.mobi.terraform-lab.cloud
```

This should show the following output:
```
Server address: 10.244.0.9:80
Server name: hello
Date: 26/Aug/2021:13:49:10 +0000
URI: /
Request ID: 62c2b4fea5112b355ffe470c3c358817
```

Congratulations! You can now successfully route traffic to your cluster.
