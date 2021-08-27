---
title: "3.4. Data Sources"
weight: 34
sectionnumber: 3.4
---

## Preparation

Create a new directory for this exercise:
```bash
mkdir data_sources
cd data_sources 
```

## Step 1: Create main.tf

Create a new file named `main.tf` in your working directory and paste the following:
```terraform
resource "random_integer" "number" {
  min = 1000
  max = 9999
}

resource "local_file" "random" {
    content  = random_integer.number.result
    filename = "random.txt"
}
```

## Step 2: Apply the configuration

Run the commands
```bash
terraform init
terraform apply
```

You will see on the console that the resource `random_integer.number` is created **before**
the `local_file.random` because the `result` attribute of the random integer is passed as content.

This shows the dependecy tracking of Terraform in action.

## Step 3: Taint a resource

Sometimes you want to recreate a specific resource. Terraform offers the `taint` command to
mark a resource for recreation and `untaint` to remove the mark.

**Important:** The next apply will destroy and create the resource which might lead to a recreation of
other depending resources!
```bash
terraform taint random_string.number
```

Since Terraform 0.15.2 you also can do this with the option `-replace <terraform object name>` e.g:
```bash
terraform apply -replace="random_string.number"
```

The random number should now be recreated.

## Step 4: Reference an existing resource

Create a new file in your current working directory:
```bash
echo terraform4ever > propaganda.txt
```

Now add the following code to `main.tf`:
```terraform
data "local_file" "propaganda" {
  filename = "propaganda.txt"
}
```

Create a new file `outputs.tf` and add the following code:
```terraform
output "propaganda" {
  value = data.local_file.propaganda.content_base64
}
```

Run the following command:
```bash
terraform apply
```

And you should see the base64 encoded version of our referenced file `propaganda.txt`

### Explanation

The `data` keyword references objects not managed by this terraform stack (code base).
This is common and very useful in cloud engineering to reference already existing infrastrucutre
components like manually added DNS zones or resources managed by another Terraform stack!

## Try it out!

You can run the following command to base64 decode the output:
```bash
terraform output -raw propaganda | base64 -d
```