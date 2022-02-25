---
title: "3.1. Resources"
weight: 31
sectionnumber: 3.1
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/basics/resources
cd $LAB_ROOT/basics/resources
```


## Step {{% param sectionnumber %}}.1: Create `main.tf`

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

For more information about Terraform resources, please see
https://www.terraform.io/docs/language/resources/syntax.html


## Step {{% param sectionnumber %}}.2: Init Terraform

Download all required Terraform providers and initialize the local state:

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


## Step {{% param sectionnumber %}}.3: Plan execution

The planing will help Terraform to understand your configuration and verify the syntax.
To create a provisioning plan, run:

```bash
terraform plan
```

This will show output similar to:

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


## Step {{% param sectionnumber %}}.4: Apply configuration

After planing the infrastructure provisioning, we instruct Terraform to apply the configuration:

```bash
terraform apply
```

Terraform will print the execution plan again and ask for confirmation.
Type `yes` to continue.

```
random_integer.number: Creating...
random_integer.number: Creation complete after 0s [id=9437]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```


## Step {{% param sectionnumber %}}.5: Inspect the local state

After creating the resources you might wonder, where Terraform stores the generated number?
As we are not in the cloud yet, where is the state stored?

Run the following command:

```bash
ls -l
```

There is a file called `terraform.tfstate` which contains all information of your resources provisioned by Terraform.
Your random number is stored in this file. Terraform requires a `.tfstate` file to store all your configurations.
It is used to compare your desired state (in code) against the real world (fetched by APIs) and last execution
(stored in the state) plus objects not available by API resource like random passwords, SSL certs
(also stored in the state).

In a later chapter we will learn how store this file in the cloud and why it is best practice.


## Step {{% param sectionnumber %}}.6: Destruction

To remove or de-provision all resources, run the following command:

```bash
terraform destroy
```

Terraform will again ask for confirmation if you want destroy the content.
Type `yes` to destroy all resources managed by this Terraform code base (aka. stack).
