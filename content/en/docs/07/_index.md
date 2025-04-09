---
title: "7. Self-guided Challenges"
weight: 7
sectionnumber: 7
---

## Self-guided Challenges

After completing all the labs, try tackling the following challenges from scratch, without relying on existing
Terraform code. Each challenge is independent—pick the one that interests you most!


### Challenge #1: GitLab Runner Deployment (Intermediate)

In many CI/CD workflows, it's standard practice to use dedicated GitLab Runners. This challenge guides you through provisioning a configurable number of runners using Terraform.


#### Objectives

Using Terraform, implement the following:

* Initialize a new Terraform stack at `$LAB_ROOT/gitlab_runner`
* Generate a GitLab Runner token from your GitLab instance (either [gitlab.com](https://gitlab.com) or a self-hosted GitLab)
  * Runners can be registered at the **group** or **project** level—even for private projects
* Provision a Linux VM configured via **cloud-init**:
  * Register the `gitlab-runner` using the GitLab Runner token
  * Ensure the runner service starts on boot
* Confirm successful registration of the runner in your GitLab group or project settings


#### Bonus

1. Store the GitLab Runner token securely in **Azure Key Vault** as a secret  
2. Create a GitLab CI pipeline in a demo project to verify that the self-hosted Azure runner can execute jobs

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
