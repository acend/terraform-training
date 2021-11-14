---
title: "5.3. Various"
weight: 53
sectionnumber: 5.3
onlyWhen: azure
---


## Preparation

Create a new directory for this exercise:
```bash
mkdir $LAB_ROOT/advanced/various
cd $LAB_ROOT/advanced/various
```


## Step {{% param sectionnumber %}}.1: Variable structure

Terraform variables support nested complex types like nested maps and sets. The `type` keyword of the `variable`
block allows the definition of type constraints to enforce the correctness of the input (or default) value.
See https://www.terraform.io/docs/language/expressions/type-constraints.html for the specification.

Create a new file named `variables.tf` and add the following content:

```terraform
variable "clouds" {
  default = {
    aws = {
      company = "Amazon"
      founder = "Jeff Bezos"
      cloud_rank = 1
    }
    azure = {
      company = "Microsoft"
      founder = "Bill Gates"
      cloud_rank = 2
    }
    gcp = {
      company = "Google"
      founder = "Larry Page and Sergey Brin"
      cloud_rank = 3
    }
  }
  type = map(object({
    company = string
    founder = string
    cloud_rank = number
  }))
}
```

The code snippet above defines a map for the top three cloud platforms with three attributes:
- company
- founder
- cloud_rank


## Step {{% param sectionnumber %}}.2: Dynamic blocks

Some Terraform resources (and data sources) have repetitive blocks, for example `archive_file`. See documentation
at https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/archive_file

Example: 

{{< highlight terraform "hl_lines=5-13" >}}
data "archive_file" "dotfiles" {
  type        = "zip"
  output_path = "dotfiles.zip"

  source {
    content  = "# nothing"
    filename = ".vimrc"
  }

  source {
    content  = "# comment"
    filename = ".ssh/config"
  }
}
{{< / highlight >}}

To add such blocks repetitively, we can use the `dyanmic` keyword as documented here: 
https://www.terraform.io/docs/language/expressions/dynamic-blocks.html

Create a new file named `main.tf` and add the following content:

```terraform
data "archive_file" "clouds" {
  type        = "zip"
  output_path = "clouds.zip"

  dynamic "source" {
    for_each = var.clouds
    content {
      filename = "${source.key}.txt"
      content = jsonencode(source.value)
    }
  }
}
```

This will create a zip file containing a text file for each entry in the `clouds` map variable defined previously.

Now run:

```bash
terraform init
terraform apply
unzip clouds.zip
cat *txt
```
