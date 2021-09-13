---
title: "1. Introduction"
weight: 1
sectionnumber: 1
onlyWhen: azure
---

Welcome to the Terraform training lab!


## What is Terraform?

Terraform is an open-source infrastructure-as-code software tool created by HashiCorp, that provides a consistent CLI
workflow to manage hundreds of cloud services. Terraform codifies cloud APIs into declarative configuration files.


## Useful Links

* [Terraform Docs](https://www.terraform.io/docs/index.html)
* [Terraform Registry & Modules](https://registry.terraform.io/)
* [Terraform Tutorials](https://learn.hashicorp.com/terraform)


## Terraform Infrastructure-as-Code (IaC)

Terraform code is written in HCL (HashiCorp Configuration Language) which is technically not source "code" but
configuration. The definition of all resources for your infrastructure is defined in `.tf` files in the same
directory. Sub-directories are used to store parameters or Terraform modules, but we'll come to that later.

The filename does not serve special purpose; Terraform internally merges all files ending with `.tf`. Choose
filenames which are expressive and meaningful for other engineers to navigate your code.

A typical project structure looks as followed:

* `main.tf`
* `variables.tf`
* `outputs.tf`
* `versions.tf`  
* `[component].tf`

In the next lab chapters you will create these files and understand what to place in these files.
