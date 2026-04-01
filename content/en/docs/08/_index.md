---
title: "8. Challenges"
weight: 8
sectionnumber: 8
---

## Challenges

After completing all the labs, try tackling the following challenges from scratch, without relying on existing
Terraform code. Each challenge is independent—pick the one that interests you most!

---


### Challenge #1: Upgrade Provider Version (Entry Level)

In the Azure Workshop, an outdated versions has been used.
In this challenge, you'll modernize the code whole base.


#### Objectives

Using Terraform, complete the following tasks:

* Upgrade the Terraform code to use the latest version of the `azurerm` provider
* Identify any deprecated or removed resources and either **migrate** them to supported alternatives or
  **re-provision** the components
* Update Kubernetes specific versions for used software as well

---


### Challenge #2: Azure Key Vault + External Secrets Operator (Advanced)

Kubernetes applications often require access to sensitive credentials. Rather than passing them during deployment, this challenge uses **[External Secrets Operator](https://external-secrets.io/)** to securely replicate secrets from **Azure Key Vault** into Kubernetes.


#### Objectives

Using Terraform, implement the following:

* Use the existing "Azure Workshop" Terraform stack at `$LAB_ROOT/azure`
* Create an **Azure Key Vault** instance
* Add a new secret to Key Vault  
  * Manually modify the secret later via the Azure Portal
* Configure **AKS OIDC (OpenID Connect)** to enable Federated Identity for workload authentication
* Deploy the **External Secrets Operator** to the AKS cluster  
  * Grant permissions to the operator via an **Azure User-Assigned Managed Identity**
* Manually create an `ExternalSecret` custom resource to sync the Key Vault secret into a target Kubernetes namespace


---
