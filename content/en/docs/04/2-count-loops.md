---
title: "4.2. Count / Loops"
weight: 42
sectionnumber: 4.2
---


## Preparation

Create a new directory for this exercise:
```bash
mkdir count_loops
cd count_loops
```


## Step 1: Conditional resource

By adding the identifier `count` to a resource, you can either make the resource conditional or
create multiple instances.

Create a new file named `elvis.tf` in your working directory and paste the following:
```terraform
locals {
  create_password = false
}

resource "random_password" "optional_password" {
  count  = local.create_password ? 1 : 0
  length = 16
}

output "optional_password" {
  sensitive = true
  value     = local.create_password ? random_password.optional_password.0.result : null
}
```


### Explanation

The `count` identifier is (ab)used to create 0 instances of `random_password`. In case multiple instances exist, the
resource turns into an array and has to be referenced using the `.0` index.


## Step 2: Multiple resources using count

Multiple resources can be instantiated by increasing the `count` value.

Create a new file named `multiple.tf` in your working directory and paste the following:
```terraform
resource "random_uuid" "ids" {
  count  = 8
}

output "ids" {
  value = random_uuid.ids.*.result
}
```

The `terraform apply` output will look similar to this:
```
...
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

ids = [
  "87745fa2-2515-507c-7bde-624d67f31c72",
  "a0cd9772-ab30-3752-b313-ea5b3e82cd49",
  "c6e51356-dd04-3fc2-9d7c-4b222325e92a",
  "4a828a5c-b6fc-d4de-1f07-d2e6511507f3",
  "a75e48ee-9397-d13a-dd94-e26118589156",
  "94efcb57-7981-0ec6-387a-3b01bbab429f",
  "a34be5b3-43f2-e673-7f9d-c7fa6f6e0ef9",
  "9cb5c592-a917-4f21-834d-3eed10a3fba8",
]
```


### Explanation

Having `count = 8` creates 8 UUID instances. The wildcard selector `*` can be used to access the `result` attribute
of all instances and create a list; see the generated output.


## Step 2: Multiple resources using for_each

Multiple resources can also be instantiated by using a `set` or a `map`. The identifier `for_each` is loops over
the entries of the collection and exposes the entry of the iteration.

Create a new file named `multiple.tf` in your working directory and paste the following:
```terraform
locals {
  files = {
    "aws.txt"   = "Jeff Bezos"
    "azure.txt" = "Bill Gates"
    "gcp.txt"   = "Larry Page and Sergey Brin"
  }
}

resource "local_file" "cloud_godfathers" {
  for_each = local.files

  filename = each.key
  content  = each.value
}
```


### Explanation

The `for_each` loop sets the `key` and `value` attributes of the iterator `each` according to the map items.
This construct allows the dynamic creation of resources based on a variable.
