---
title: "3.1. Resources"
weight: 31
sectionnumber: 3.1
---

## Preparation

Create a new directory for this exercise:
```bash
mkdir resources
cd resources 
```

## Step 1: Create main.tf

We will start with a simple example by creating a resource of type `random_integer`. This resources generates
a random number in the configured range.

Create a new file named `main.tf` in your working directory and paste the following:
```terraform
resource "random_integer" "number" {
  min = 1000
  max = 9999
}
```

### Explanation

The `resource` block defines one (or multiple) infrastructure objects which are managed by Terraform.

For more information about Terraform resources, please see<br>
https://www.terraform.io/docs/language/resources/syntax.html

## Step 2: Init Terraform 

Download all required Terraform providers and initialize a local state:
```bash
terraform init
```

Output:

```
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/random...
- Installing hashicorp/random v3.1.0...
- Installed hashicorp/random v3.1.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```


## Step 3: Plan execution

The planing will help Terraform to understand your configuration and verfiy the syntax of your configuration.
```bash
terraform plan
```

You may see output like:

```
Terraform will perform the following actions:

  # random_integer.acr will be created
  + resource "random_integer" "number" {
      + id     = (known after apply)
      + min    = 1000
      + max    = 9999
      + result = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```


## Step 4: Apply configuration

After planing our content we will let Terraform create it by applying the configuration:
```bash
terraform apply
```

Terraform will print the execution plan and ask for confirmation.<br>
Type `yes` to continue.

```
random_integer.number: Creating...
random_integer.number: Creation complete after 0s [id=9437]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```


## Step 5: Inspect the local state

After creating the resources you might wonder, where Terraform stores the generated number?
As we are not in Cloud yet, where does your state live?

Run the following command:
```bash
ls -l
```

There is a file called `terraform.tfstate` which contains all information of your resources provisioned by Terraform.
Your random number is stored here. Terraform requires such a `.tfstate` file to store all your configurations.
It is used to compare your desired state against the real world and store objects, which are not backed by a cloud
resource like random passwords, SSL certs etc.

In a later chapter we will learn how save this file in the cloud and why this is the recommended approach.


## Step 6: Destruction

The proper way to remove or deprovision all resources, is running the following command:
```bash
terraform destroy
```

You will again be asked, if you want destroy the content. After your decision the content has your desired state.
