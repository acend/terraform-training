---
title: "Variables"
weight: 4
sectionnumber: 4
---

Now it is time to add more configuration and some variables.


## Configuration

Typically Terraform needs some basic config to work well. Here is an example:

```bash
terraform {
  required_version = ">= 0.15"

  required_providers {
    random  = ">= 3.1.0"
  }
}
```

Put this content into the head of the file `main.tf`.

You can choose versions of different provides as well as Terraform itself. This is important for the usage in a production environment to be comprehensible.

{{% alert title="Warning" color="secondary" %}}
The usage of an operator like `>=` can be dangerous as it can be use as a man in the middle attack. For more information ask your teacher about this topic.
{{% /alert %}}


## Variables

Variables are used to have an input into the Terraform configuration. They are mandantory for the applying of the configuration. But you can also use pre-defined values to avoid an input interrupt.

Create a new file called `variables.tf`.
This file will be used to seperate all needed input variables from the main configruation.

```bash
variable "random_min_value" {
  type        = number
  default     = 1000
  description = "define the min value of the random number"
}
```

Let's change our random_string in the `main.tf` to the following to use the variable:

```bash
resource "random_integer" "acr" {
  min = var.random_min_value
  max = 9999
}
```

Now use Terraform to apply all the new files from this chapter:

* `main.tf`
* `variables.tf`

```bash
terraform plan
terraform apply
```

If you see any errors in the Terraform output, check your files!

Final Question: What is the value of your random number?

