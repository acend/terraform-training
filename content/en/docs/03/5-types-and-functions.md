---
title: "3.5. Types / Functions"
weight: 35
sectionnumber: 3.5
---


## Preparation

Create a new directory for this exercise:
```bash
mkdir types
cd types
```

Documentation for the built-in functions can be found at:
https://www.terraform.io/docs/language/functions/index.html


## Step 1: String interpolation

Create a new file named `strings.tf` and add the following content:
```terraform
locals {
  counter = 5
}

output "counter" {
  value = "Counter is ${local.counter}"
}
```

Run init and apply:
```bash
terraform init
terraform apply
```


## Step 2: Working with lists

Create a new file named `lists.tf` and add the following content:
```terraform
locals {
  fibonacci = [0,1,1,2,3,5,8,13]
}

output "element_5" {
  value = local.fibonacci.5 // or local.fibonacci[5]
}

output "fibonacci" {
  value = join("/", local.fibonacci)
}
```

Run apply:
```bash
terraform apply
```


## Step 3: Working with maps

Create a new file named `maps.tf` and add the following content:
```terraform
locals {
  tags = {
    env = "prod"
    app = "nginx"
  }
  extra_tags = {
    plattform = "azure"
  }
}

output "tag_list" {
  value = keys(local.tags)
}

output "full_tags" {
  value = merge(local.tags, local.extra_tags)
}
```

Run apply:
```bash
terraform apply
```


## Step 4: Working with external YAML/JSON files

Terraform provides built-in functions to access external YAML and JSON files.

Create a new file named `project.yaml` and add the following content:
```yaml
components:
  - name: "project-name"
    metadata:
      annotations:
        app: "example"
```

Create a new file named `yaml.tf` and add the following content:
```terraform
locals {
  yaml_file  = yamldecode(file("project.yaml"))
}

output "app" {
  value = local.yaml_file.components.0.metadata.annotations.app
}
```

**Note:** The example above could also be shortened using output chaining to the following snippet
but readability suffers:
```terraform
output "app2" {
  value = yamldecode(file("project.yaml")).components.0.metadata.annotations.app
}
```
