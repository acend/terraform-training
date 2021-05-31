---
title: "Local states"
weight: 11
sectionnumber: 1.1
---

In this Chapter we will leran the real bascis of terraform. You will understand how you can plan and apply your config. After all the work is done you will also learn how to destroy your content.


## Initialisation

Lets create an initial local setup by running:

```bash
terraform init
```


## Creation

We will start with a simple example by creating a ressource ...
So start your editor of choice and insert the following lines:

```bash
resource "random_string" "random" {
  length  = 8
  special = false
}
```

Name the file `main.tf`


## Planing

The planing will help Terraform to understand your configuration and verfiy the content ruffly.

```bash
terraform plan
```

You may see some output like:

```bash
blah blah blah
```


## Applying

After planing our content we will let Terraform create it by appliyng the configuration:

```bash
terraform apply
```

You will get asked, after a short repeating of the planing, if you really want to apply this. So type `yes`

Now you can use your created content.


## Destruction

There are different ways to get rid of your content.

* by deleting the `main.tf` file
* by running `terraform destroy`


```bash
terraform destroy
```

You will again be asked, if you want destroy the content. After your decision the content has your desired state.
