---
title: "4.3. Backend State"
weight: 43
sectionnumber: 4.3
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir backend_state
cd backend_state
```


## Step {{% param sectionnumber %}}.1: Define a backend

Create a new file named `main.tf` and add the following content:

```terraform
terraform {
  backend "local" {
    path = "foobar.tfstate"
  }
}

resource "random_password" "super_secret" {
  length = 16
}
```

Run the commands

```bash
terraform init
terraform apply
```

After the apply run:

```bash
ls -al
```

Now you should see a local file named `foobar.tfstate` containing the Terraform state.


## Step {{% param sectionnumber %}}.2: List all managed resources

Terraform has builtin commands to interact with the state.

Run the following command to list all managed resources:

```bash
terraform state list
```

Run the following command to show a specific resource in the state:

```bash
terraform state show random_password.super_secret
```

**Advanced:** Run the following command to fetch the raw JSON terraform state:

```bash
terraform state pull
```

{{% alert title="Note" color="primary" %}}
The password in the JSON field `"result"` is stored in clear test! Thats why the
Terraform state file should be considered sensitive and protected accordingly!
{{% /alert %}}
