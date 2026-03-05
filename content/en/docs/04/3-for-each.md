---
title: "4.3. For Each"
weight: 43
sectionnumber: 4.3
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/intermediate/for_each
cd $LAB_ROOT/intermediate/for_each
```

Optional: Create empty files:

```bash
touch {main,variables,outputs}.tf
```


## Step {{% param sectionnumber %}}.1: Iterate over a map with `for_each`

While `count` creates indexed copies of a resource, `for_each` creates named instances keyed by a
map or set value. This makes references more readable and avoids accidental re-creation when the
list order changes.

Create a new file named `main.tf` and add the following content:

```terraform
resource "local_file" "configs" {
  for_each = var.environments

  filename = "${each.key}.txt"
  content  = "environment: ${each.key}\nowner: ${each.value.owner}"
}
```

Create a new file named `variables.tf` and add the following content:

```terraform
variable "environments" {
  description = "Map of environment names to their configuration."
  type = map(object({
    owner = string
  }))
  default = {
    dev = {
      owner = "team-platform"
    }
    staging = {
      owner = "team-qa"
    }
    prod = {
      owner = "team-ops"
    }
  }
}
```

Run the commands:

```bash
terraform init
terraform apply
```

You will see Terraform create three separate `local_file` resources, each identified by the map key
(`dev`, `staging`, `prod`) rather than a numeric index.


### Explanation

`for_each` accepts either a **map** or a **set of strings**. Inside the resource block, two special
values are available:

| Symbol | Description |
|--------|-------------|
| `each.key` | The current map key (or set element) |
| `each.value` | The current map value (only for maps) |

Because each instance is identified by a **stable key**, adding or removing one entry only affects
that specific resource—unlike `count`, where removing an element from the middle of a list causes
all subsequent resources to be re-created.


## Step {{% param sectionnumber %}}.2: Reference a `for_each` resource

Create a new file named `outputs.tf` and add the following content:

```terraform
output "file_paths" {
  description = "Paths of all generated config files."
  value       = { for k, v in local_file.configs : k => v.filename }
}
```

Apply and observe the structured output:

```bash
terraform apply
```

```text
Outputs:

file_paths = {
  "dev"     = "dev.txt"
  "prod"    = "prod.txt"
  "staging" = "staging.txt"
}
```

### Explanation

The `for` expression in the output iterates over all instances of the `local_file.configs` resource
(which is now a map of objects). The resulting output mirrors the input map structure, making it
easy to pass individual values to downstream resources.


## Step {{% param sectionnumber %}}.3: `for_each` vs `count` – When to use which

| Scenario | Recommended |
|----------|-------------|
| Fixed number of identical resources | `count` |
| Conditional resource creation | `count = 0 / 1` |
| Named, distinct resources from a map or set | `for_each` |
| Resource set that may shrink in the middle | `for_each` |

{{% alert title="Best Practice" color="secondary" %}}
Prefer `for_each` over `count` whenever resources have meaningful names or can be individually
referenced. Using `count` with lists is fragile: removing an element at index 0 causes all
subsequent resources to be destroyed and re-created.
{{% /alert %}}
