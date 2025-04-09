---
title: "5.3. Various"
weight: 53
sectionnumber: 5.3
---


## Preparation

Create a new directory for this exercise:
```bash
mkdir $LAB_ROOT/advanced/various
cd $LAB_ROOT/advanced/various
```

Optional: Create empty files:

```bash
touch {main,variables,outputs}.tf
```


## Step {{% param sectionnumber %}}.1: Variable structure

Terraform variables support nested complex types like nested maps and sets. The `type` keyword of the `variable`
block allows the definition of type constraints to enforce the correctness of the input (or default) value.
See https://developer.hashicorp.com/terraform/language/expressions/type-constraints for the specification.

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

* company
* founder
* cloud_rank

### Try it out

Create a list of the `founder` attributes of all `clouds` using a **SINGLE** output using the following snippet:   

```terraform
output "founders" {
  value = ["todo"]
}
```

## Step {{% param sectionnumber %}}.2: Variable optional and default fields

Defining variables as objects with attributes is very useful, but sometimes we don't want to specify all
attributes but use some defaults. This can be achieved by the `optional` keyword.

Add the following snippet to `outputs.tf`:

```terraform
variable "kubernetes" {
  type = object({
    version     = optional(string)
    node_count  = optional(number, 3)
    vm_type     = optional(string, "t3.small")
  })
  default = {
    version = "1.25.5"
  }
}

output "kubernetes" {
  value = var.kubernetes
}
```

When you run `terraform apply` you should see a fully defined `kubernetes` variable:

```terraform
kubernetes = {
  "node_count" = 3
  "version" = "1.25.5"
  "vm_type" = "t3.small"
}
```

{{% alert tip %}}
Partial initialization of variables is very useful in combination with `config/*.tfvars` files, to only specify the
explicit and override values - keeping the config small and tidy!
{{% /alert %}}

## Step {{% param sectionnumber %}}.3: Variable validation

Sometimes you want to validate if a variable meets certain conditions. For this purpose, the `validation` block can
be added to a variable.

Modify `outputs.tf` as followed:

```terraform
variable "kubernetes" {
  type = object({
    version    = optional(string)
    node_count = optional(number, 0)
    vm_type    = optional(string, "t3.small")
  })
  default = {
    version = "1.25.5"
  }
  validation {
    condition     = var.kubernetes.node_count > 0
    error_message = "Minimum Kubernetes nodes is 1"
  }
}
```

**Note:** Set the `node_count` default to 0 to trigger a validation error!

Now run `terraform apply` and verify the validation error is printed.


## Step {{% param sectionnumber %}}.4: Dynamic blocks

Some Terraform resources (and data sources) have repetitive blocks, for example `archive_file`. See documentation
at https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file

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
{{< /highlight >}}

To add such blocks repetitively, we can use the `dynamic` keyword as documented here:
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
