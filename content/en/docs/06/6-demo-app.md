---
title: "6.6. Demo App"
weight: 66
sectionnumber: 6.6
---


## Coming soon

Create a Kubernetes secret containing the MariaDB URI to be exposed as the POD environment variable `MYSQL_URI`:
```bash
kubectl create secret generic mariadb-uri --namespace workload --from-literal=mariadb_uri=$(terraform output -raw mariadb_uri)
```

Create a new file named `tests/workload.yaml` and add the following content:
```terraform
# kubectl apply -f workload.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: workload

---

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
    - workload.lab.labz.ch
    secretName: tls-workload
  rules:
  - host: workload.lab.labz.ch
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

Deploy the Kubernetes resources by running:
```bash
kubectl apply -f tests/workload.yaml
```