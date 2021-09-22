---
title: "6.2. Remote State"
weight: 62
sectionnumber: 6.2
onlyWhen: azure
---


## Step {{% param sectionnumber %}}.1: Create a storage

The Azure storage account and storage container to store the Terraform state are not managed by Terraform; it is a
chicken and egg problem we resolve by using the `az` CLI as followed:
```bash
export NAME=YOUR_USERNAME
export ACCOUNT=tfstate$RANDOM
az group create --location westeurope --name rg-terraform-$NAME
az storage account create --name $ACCOUNT --resource-group rg-terraform-$NAME
az storage container create --resource-group rg-terraform-$NAME --account-name $ACCOUNT --name terraform-state --public-access off
echo $ACCOUNT
```

**Note**: Please replace `YOUR_USERNAME` with the username assigned to you for this workshop.

{{% alert title="Important" color="secondary" %}}
`YOUR_USERNAME` for this and all upcoming exercises must be

* all lowercase
* only contain alpha-numeric characters `^[a-z0-9]$`
{{% /alert %}}


## Step {{% param sectionnumber %}}.2: Configure the Terraform backend

Add the following content to the **start** of `main.tf`:
```terraform
terraform {
  backend "azurerm" {}
}
```

Create a new file named `config/dev_backend.tfvars` and add the following content:
```terraform
subscription_id      = "c1b34118-6a8f-4348-88c2-b0b1f7350f04"
resource_group_name  = "rg-terraform-YOUR_USERNAME"
storage_account_name = "YOUR_ACCOUNT"
container_name       = "terraform-state"
key                  = "dev.tfstate"
```

**Note**: Please replace `YOUR_USERNAME` with the username assigned to you for this workshop and `YOUR_ACCOUNT`
with the value of the `$ACCOUNT` variable.

Now run
```bash
terraform init -backend-config=config/dev_backend.tfvars
```

Terraform will detect that a local state already exists and asks if you would like to migrate
the local state to the new remote state; enter `yes`:

```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "azurerm" backend. No existing state was found in the newly
  configured "azurerm" backend. Do you want to copy this state to the new "azurerm"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
...
```


### Explanation

The Azure storage account is another resource which requires a global unique name. We therefore prefix and randomise
the name.


## Step {{% param sectionnumber %}}.3: Lock the Terraform versions

As seen earlier, its good practice to lock the Terraform CLI and provider versions
to avoid uncontrolled version upgrades.
```terraform
terraform {
required_version = "= 1.0.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.77.0"
    }
  }
}
```

**Note:** As of this writing, the current version is `2.77.0`. Set the version to the latest fetched in the previous
run of `terraform init ...`

Now run Terraform init again:
```bash
terraform init -backend-config=config/dev_backend.tfvars
```
