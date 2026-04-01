---
title: "7. Terraform with Pipeline"
weight: 7
sectionnumber: 7
---

We will learn how to integrate Terraform into GitLab CI/CD pipelines to automate
infrastructure provisioning and enforce code quality in a team workflow.


## Why Terraform in CI/CD?

Running Terraform manually from a local machine works fine for learning but is not suitable for
teams or production environments:

* **Consistency** – different engineers may have different Terraform or provider versions installed
* **Auditability** – there is no record of who ran which command and when
* **Security** – cloud credentials should not be stored on developer laptops
* **Enforcement** – there is no guarantee that code was validated or formatted before it was applied


## What you will learn

* The key building blocks of a GitLab CI/CD pipeline (`.gitlab-ci.yml`, stages, jobs, variables)
* How to run `terraform validate`, `terraform plan`, and `terraform apply` inside a pipeline
* How to provision a self-hosted GitLab Runner on Azure using Terraform
* How to build a custom Docker image with linting tools and run checks automatically in CI


## Prerequisites

* A GitLab account on [gitlab.com](https://gitlab.com) or a self-hosted instance
* The Azure Workshop from Chapter 6 completed (remote state storage account + AKS cluster)
* Docker installed locally for building the CI image
