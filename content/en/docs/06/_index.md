---
title: "6. Types"
weight: 6
sectionnumber: 6
---

As Terraform has a lot of types we will use some to get an idea how we can use them.


## Task {{% param sectionnumber %}}.1: Strings

Strings has always to be in straight double-quotes ("). You can interpolate any type into a string by using the "${}" directive:

```bash
output "random_result_string" {
    description = "random created by terraform"
    value       = "Value: ${random_integer.acr.result}"
}
```

Or even use functions to manipulate strings like "substr" => https://www.terraform.io/docs/language/functions/substr.html


## Task {{% param sectionnumber %}}.2: Maps

A map contains a typical JSON structure. It names a value and is following by the variable. We can use it e.g. to summarize informations and applying them at once:

```bash
variable "map_example" {
  type = map(string)
  default = {
    "env" = "test"
    "foo" = "bar"
  }
  description = "map example"
}

output "random_result_stage" {
    description = "random created by terraform"
    value       = "${var.map_example["stage"]}: ${random_integer.acr.result}"
}
```


## Task {{% param sectionnumber %}}.2: YAML

Often projects have their config in YAML files. With Terraform you can read YAML/JSON easyliy by reading the file and navigate to your values:

Simple YAML example (`project.yaml`):

```bash
---
version: "0.1"
components:
  - name: "project-name"
    metadata:
      annotations:
        app: "example"
```

```bash
locals {
  yaml_file  = yamldecode(file("project.yaml"))
  app_name  = local.yaml_file.components[0].metadata.annotations.app
}

output "random_result_project" {
    description = "random created by terraform"
    value       = "${locals.app_name}: ${random_integer.acr.result}"
}
```

