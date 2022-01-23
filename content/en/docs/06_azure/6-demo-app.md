---
title: "6.6. Demo App"
weight: 66
sectionnumber: 6.6
onlyWhen: azure
---


## Step {{% param sectionnumber %}}.1: Deploy a workload container

```mermaid
flowchart LR
    classDef red fill:#f96
    subgraph rg: aks
    aAks(aks)
    aIp(public ip)
    end
    dDns --> aIp
    subgraph rg: default
    dDns(dns)
    end
    aAks --> aks
    subgraph aks
        aIp --> sNg
        subgraph ns: nginx-ingress
        sNg(service) --> pNg(pod)
        end
        subgraph ns: workload
        iAc --> sAc(service):::red --> pAc(pod):::red
        pNg --> iAc(ingress):::red
        end
    end
    pAc --> mFire
    subgraph rg: db
        mServer(mariadb) --> mDb(database)
        mFire(firewall) --> mDb
    end
```

To test the setup end-to-end, we deploy an example application on Kubernetes. The app exposes a web service on port
5000 and writes sample records to the MariaDB.

Create a Kubernetes secret containing the MariaDB URI to be exposed as the POD environment variable `MYSQL_URI`:

```bash
kubectl create namespace workload
kubectl create secret generic mariadb-uri --namespace workload --from-literal=mariadb_uri=$(terraform output -raw mariadb_uri)
```

Create a new file named `tests/workload.yaml` and add the following content:

```yaml
# kubectl apply -f workload.yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  namespace: workload
  labels:
    app: example
spec:
  containers:
  - image: "quay.io/acend/example-web-python:latest"
    name: example
    ports:
    - containerPort: 5000
      protocol: TCP
    env:
      - name: MYSQL_URI
        valueFrom:
          secretKeyRef:
            name: mariadb-uri
            key: mariadb_uri

---

apiVersion: v1
kind: Service
metadata:
  name: example
  namespace: workload
spec:
  selector:
    app: example
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
  namespace: workload
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - workload.YOUR_USERNAME.labz.ch
    secretName: tls-workload
  rules:
  - host: workload.YOUR_USERNAME.labz.ch
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example
            port:
              number: 5000
```

**Note**: Please replace `YOUR_USERNAME` with the username assigned to you for this workshop.

Deploy the Kubernetes resources by running:

```bash
kubectl apply -f tests/workload.yaml
```

The application is now accessible via web browser at https://workload.YOUR_USERNAME.labz.ch

To verify the application is connected to the MariaDB, run the following command to inspec the log files:
```bash
kubectl logs -n workload example | head
```
