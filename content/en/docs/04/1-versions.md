---
title: "4.1. Versions"
weight: 41
sectionnumber: 4.1
---


## Preparation

Finish the "Data Sources" exercise and copy the directory:
```bash
cp -r ../basics/data_sources versions
cd versions
```


## Step 1: Create versions.tf

Create a new file named `versions.tf` and add the following content:
```terraform
terraform {
  required_version = "= 1.0.5"

  required_providers {
    random  = {
      source  = "hashicorp/random"
      version = "= 3.1.0"
    }
    local   = {
      source  = "hashicorp/local"
      version = "= 2.1.0"
    }
  }
}
```


### Explanation

With multiple engineers working on the same infrastructure code base, it is inevitable to have different versions of
the Terraform CLI installed.

Furthermore, are Terraform providers under heavy development and have new features added daily. This rapid development
can lead to incompatibilities and trigger regressions; neither are desirable in a production environment

It is best practice to lock the Terraform CLI and provider versions to a specific release. This ensures a controlled
version management and planned upgrades.


## Step 2: Init Terraform

Now delete the existing terraform providers and lock files (optional), init the stack and apply it by running:
```bash
rm -r .terraform/ .terraform.lock.hcl
terraform init
terraform apply
```


## Step 3: Terraform code formatting

Terraform offers a command to format all files according to HashiCorp guidelines by running the following command:
```bash
terraform fmt -recursive
```

**Note:** Most IDEs offer HCL formatting but it differs from the HashiCorp guidelines. It is recommended to use the
`terraform fmt` command for compliance.
