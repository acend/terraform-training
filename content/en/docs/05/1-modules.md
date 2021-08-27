---
title: "5.1. Modules"
weight: 51
sectionnumber: 5.1
---


## Preparation

Create a new directory for this exercise:
```bash
mkdir modules
cd modules
```


## Step 1: Define the module

A local module resides in its own directory, lets create one be running:
```bash
mkdir random_file
```

Create a new file named `random_file/variables.tf` and add the following content:
```terraform
variable "extension" {}
variable "size" {}
```

Create a new file named `random_file/main.tf` and add the following content:
```terraform
resource "random_pet" "filename" { }

resource "random_password" "content" {
  length = var.size
}

resource "local_file" "this" {
  filename = "${random_pet.filename.id}.${var.extension}"
  content = random_password.content.result
}
```

Create a new file named `random_file/outputs.tf` and add the following content:
```terraform
output "filename" {
  value = local_file.this.filename
}
```


### Explanation

It is common practice implementing a module with these three files:

* `main.tf`
* `variables.tf`
* `outputs.tf`

For modules with many resouces (10+), it is advised to split `main.tf` into groups of resources.


## Step 2: Create two instances of the module

Create a new file named `main.tf` and add the following content:
```terraform
module "first" {
  source    = "./random_file"
  extension = "txt"
  size      = 1337
}

module "second" {
  source    = "./random_file"
  extension = "txt"
  size      = 42
}

output "filenames" {
  value = [
    module.first.filename,
    module.second.filename
  ]
}
```

Now run
```bash
terraform init
terraform apply
```


### Explanation

We instantiate the `random_file` module two times and specify different parameters. The output `filenames` prints
the randomly generated filenames.