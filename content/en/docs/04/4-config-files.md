---
title: "4.4. Config Files"
weight: 44
sectionnumber: 4.4
---

## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/intermediate/multi_env
cd $LAB_ROOT/intermediate/multi_env
```

Optional: Create empty files:

```bash
touch {main,variables,outputs}.tf
```


## Step {{% param sectionnumber %}}.1: Define variable and output

Create a new file named `variables.tf` and add the following content:

```terraform
variable "environment" {}
```

Create a new file named `outputs.tf` and add the following content:

```terraform
output "current_env" {
  value = var.environment
}
```

Create a new file named `main.tf` and add the following content:

```terraform
terraform {
  backend "local" {}
}
```


### Explanation

The backend of type `local` is declared but missing the `path` argument; this is a so-called "partial configuration".
The missing argument will be added via a config file.


## Step {{% param sectionnumber %}}.2: Offload configuration to separate files

It is best practice separating configuration from HCL code. For this purpose we create a dedicated directory:

```bash
mkdir config
```

Create a new file named `config/dev.tfvars` and add the following content:

```terraform
environment = "dev"
```

Create a new file named `config/dev_backend.tfvars` and add the following content:

```terraform
path = "dev.tfstate"
```


## Step {{% param sectionnumber %}}.3: Init and apply using config files

Now we init Terraform by specifying a backend configuration with the option `-backend-config`:

```bash
terraform init -backend-config=config/dev_backend.tfvars
```

Then we apply the code by specifying a variable configuration with the option `-var-file`:

```bash
terraform apply -var-file=config/dev.tfvars
```

You should now see the following output:

```text
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

current_env = "dev"
```

And a state file called `dev.tfstate` containing the Terraform state.


## Explanation

The backend and variable configuration files abstract the code from different "instances". This pattern can be
used to provision different environments like dev, test, prod.


## Step {{% param sectionnumber %}}.4: Create a production configuration

To add another set of configuration for a "production" environment, lets just add two more files:

Create a new file named `config/prod.tfvars` and add the following content:

```terraform
environment = "prod"
```

Create a new file named `config/prod_backend.tfvars` and add the following content:

```terraform
path = "prod.tfstate"
```

{{% alert title="Warning" color="secondary" %}}
We need to re-initialize Terraform to use the new state by providing the argument `-reconfigure`
(or by deleting the `.terraform` directory) and then run the usual apply.
{{% /alert %}}


```bash
terraform init -backend-config=config/prod_backend.tfvars -reconfigure
terraform apply -var-file=config/prod.tfvars
```

You should now see two Terraform state files for each set of configuration:

* `dev.tfstate`
* `prod.tfstate`

{{% alert title="Note" color="primary" %}}
The separation of configuration in the `config/` directory keeps the HCL code DRY.  
It is a common pattern to have many different environments or customer configurations in this directory, which shall
be under source control.
{{% /alert %}}

{{% alert title="Warning" color="secondary" %}}
Do NOT store any sensitive information like credentials or keys in the configuration!  
Use a secrets management system like HashiCorp Vault, AWS SecretsManager, 1Password etc
{{% /alert %}}


## Try it out

It is a common pattern to set credentials via the shell environment. Terraform has built-in support to set
variables via environment by prefixing the Terraform variable name with `TF_VAR_`.

Add the following to `variables.tf`:

```terraform
variable "secret" { }
```

and the following to `outputs.tf`:

```terraform
output "secret" {
  value = var.secret
}
```

Then set the value in the shell:

```bash
export TF_VAR_secret=mysupersecret
```

Now run `terraform apply  -var-file=config/prod.tfvars`
