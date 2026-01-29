---
title: "7. Challenges"
weight: 7
sectionnumber: 7
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


### Challenge #2: GitLab Runner Deployment (Intermediate)

In many CI/CD workflows, it's standard practice to use dedicated GitLab Runners.
This challenge guides you through provisioning a configurable number of runners using Terraform.


#### Objectives

Using Terraform, implement the following:

* Use your GitLab account (either [gitlab.com](https://gitlab.com) or a self-hosted GitLab)
* Initialize a new Repository at gitlab_runner and check it out
* Generate a GitLab Runner token from your GitLab instance
  * Runners can be registered at the **group** or **project** level—even for private projects
* Provision a Linux VM:
  * Register the `gitlab-runner` using the GitLab Runner token
  * Ensure the runner service starts on boot
* Confirm successful registration of the runner in your GitLab group or project settings


#### Bonus

1. Create a GitLab CI pipeline in a demo repo to verify that the self-hosted Azure runner can execute jobs


---


### Challenge #3: Azure Key Vault + External Secrets Operator (Advanced)

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


### Challenge #4: Terraform Linting (Enterprise)

Your Infrastructure Code should be ready to be maintained from other people as yourself. Therefore it is important to follow specific guidelines to a default.


#### Objectives

Using terraform and tflint, and check your codebase:

* Use the existing projects to run `terraform fmt --check` and `tflint` and check/correct the output
* Create a new docker image with terraform and tflint and upload it into your registry
* Build a linting stage in your pipeline to create a linting check of your code which should be added to the repo
