---
title: "Application Setup"
weight: 7
sectionnumber: 7
---

Now we have a running Kubernetes cluster let's deploy something!


## Connection

Check if we are able to connect and get some informations:

```bash
kubectl get nodes -o wide
```

Got an error? As expected. We need to get the credentials to your local system. You can do this by running:

```bash
az aks get-credentials --name xxx --resource-group xxx --subscription xxx
```

Now repeat the lines above. You will be asked to enter the login page with an digit code to verify your user. The output should be like:

```
NAME                              STATUS   ROLES   AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-default-33164174-vmss00000a   Ready    agent   1h    v1.20.7   10.240.0.4     <none>        Ubuntu 18.04.5 LTS   5.4.0-1048-azure   containerd://1.4.4+azure
aks-default-33164174-vmss00000b   Ready    agent   1h    v1.20.7   10.240.0.105   <none>        Ubuntu 18.04.5 LTS   5.4.0-1048-azure   containerd://1.4.4+azure
```


## Deployments

To deploy our awesome application your need to run the following:

```bash
kubectl create deployment example-web-python --image=quay.io/acend/example-web-python
kubectl expose deployment example-web-python --type="LoadBalancer" --name="example-web-python" --port=5000 --target-port=5000
```

We won't go into details over here. Because you should learn Terrafrom instead.


## Access the Application

After the deplyoment has been placed we can now try to access it over the IP adress. We can get this information by get some details about the service:

```bash
kubectl get service example-web-python -o wide
```

```
NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)		AGE
example-web-python   LoadBalancer   10.243.223.12    20.50.241.69   5000:31662/TCP	14m
```

In the field `EXTERNAL-IP` you have your public IP to access the application. If the IP is missing, you may have to wait some more seconds. Repeat the command to see if it is there.

Now open the browser, enter the IP and the correct port, and see the awesome application.

