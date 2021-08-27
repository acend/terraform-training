---
title: "4.4. Config Files"
weight: 44
sectionnumber: 4.4
---

## Preparation

Create a new directory for this exercise:

```bash
mkdir multi_env
cd multi_env 
```

## Step 1: Define variable and output

Create a new file named `variable.tf` and paste the following content:

```terraform
variable "environment" {}
```

Create a new file named `variable.tf` and paste the following content:

```terraform
output "current_env" {
  value = var.environment
}
```

Create a new file named `main.tf` and paste the following content:

```terraform
terraform {
  backend "local" {}
}
```

### Explanation

The backend of type `local` is declared but missing the `path` argument; this is a partial configuration.
The missing argument will be added via a config file.


## Step 2: Offload configuration to separate files

It is best practice to separate configuration from the HCL code. For this purpose we create a dedicated directory:
```bash
mkdir config
```

Create a new file named `config/dev.tfvars` and paste the following content:
```terraform
environment = "dev"
```


Create a new file named `config/dev_backend.tfvars` and paste the following content:
```terraform
path = "dev.tfstate"
```

## Step 3: Init and apply using config files

Now we init Terraform by specifying a backend configuration with the option `-backend-config`:
```bash
terraform init -backend-config=config/dev_backend.tfvars
```

Then we apply the code by specifying a variable configuration with the option `-var-file`:
```bash
terraform apply -var-file=config/dev.tfvars
```

You should now see the following output:
```
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

current_env = "dev"
```

And a state file called `dev.tfstate` containing the Terraform state.

# Explanation

The backend and variable configuration files abstract the code from different "instances". This pattern can be
used to provision different environments like dev, test, prod.

## Step 4: Create a production configuration

To add another set of configuration for a "production" environment, lets just add two more files:

Create a new file named `config/prod.tfvars` and paste the following content:
```terraform
environment = "prod"
```

Create a new file named `config/prod_backend.tfvars` and paste the following content:
```terraform
path = "prod.tfstate"
```

**Important:** We need to re-initialize Terraform to use the new state by providing the argument `-reconfigure`
(or by deleting the `.terraform` directory) and then run the usual apply.
```bash
terraform init -backend-config=config/prod_backend.tfvars -reconfigure
terraform apply -var-file=config/prod.tfvars
```

You should now see two Terraform state files for each set of configuration:
- `dev.tfstate`
- `prod.tfstate`