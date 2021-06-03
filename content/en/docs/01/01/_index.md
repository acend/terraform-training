---
title: "Local states"
weight: 11
sectionnumber: 1.1
---

In this Chapter we will leran the real bascis of terraform. You will understand how you can plan and apply your config. After all the work is done you will also learn how to destroy your content.


## Creation

We will start with a simple example by creating a ressource ...
So start your editor of choice and insert the following lines:

```bash
resource "random_integer" "acr" {
  min = 1000
  max = 9999
}
```

Name the file `acr.tf`


## Initialisation

Lets create an initial local setup by running:

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

## Planing

The planing will help Terraform to understand your configuration and verfiy the content ruffly.

```bash
terraform plan
```

You may see some output like:

```
Terraform will perform the following actions:

  # random_integer.acr will be created
  + resource "random_integer" "acr" {
      + id     = (known after apply)
      + min    = 1000
      + max    = 9999
      + result = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```


## Applying

After planing our content we will let Terraform create it by appliyng the configuration:

```bash
terraform apply
```

You will get asked, after a short repeating of the planing, if you really want to apply this. So type `yes`

Now you can use your created content.

```
random_integer.acr: Creating...
random_integer.acr: Creation complete after 0s [id=9437]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```


## Destruction

There are different ways to get rid of your content.

* by deleting the `main.tf` file
* by running `terraform destroy`


```bash
terraform destroy
```

You will again be asked, if you want destroy the content. After your decision the content has your desired state.
