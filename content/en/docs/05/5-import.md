---
title: "5.5. Import"
weight: 55
sectionnumber: 5.5
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/advanced/import
cd $LAB_ROOT/advanced/import
```

Optional: Create empty files:

```bash
touch {main,outputs,versions}.tf
```


## Step {{% param sectionnumber %}}.1: Define the configuration

A common real-world scenario for `terraform import` is when a resource was created by a previous
Terraform run but the state file was accidentally deleted or corrupted — for example after a botched
workspace migration. Without the state entry Terraform treats the resource as non-existent and would
try to create a new one, producing a completely different value and breaking any infrastructure that
depended on the original.

In this lab you will use a `random_string` resource that generates a unique suffix — a very common
pattern for globally unique resource names. You will apply it, simulate state loss, and then import
the resource back into state.

Create a new file named `main.tf` with the following content:

```terraform
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

Create a new file named `outputs.tf` with the following content:

```terraform
output "suffix" {
  value = random_string.suffix.result
}
```

Create a new file named `versions.tf` with the following content:

```terraform
terraform {
  required_version = ">= 1.12.2"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "= 3.7.1"
    }
  }
}
```

Run `terraform init` and `terraform apply` to create the resource:

```bash
terraform init
terraform apply
```

Terraform creates the random string and stores it in state. Save the generated value to a shell
variable — you will need it in the import steps:

```bash
SUFFIX=$(terraform output -raw suffix)
echo "Generated suffix: $SUFFIX"
```

```text
Generated suffix: k7m2px4n
```


## Step {{% param sectionnumber %}}.2: Simulate state loss

Remove the resource from the Terraform state to simulate a lost or corrupted state file:

```bash
terraform state rm random_string.suffix
```

```text
Removed random_string.suffix
Successfully removed 1 resource instance(s).
```

Run `terraform plan` to see what Terraform would do without the state entry:

```bash
terraform plan
```

```text
Terraform will perform the following actions:

  # random_string.suffix will be created
  + resource "random_string" "suffix" {
      + id      = (known after apply)
      + length  = 8
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Terraform would generate a brand-new random string — a completely different value — which would
break any existing resource names that rely on the original suffix. This is the problem that
`terraform import` solves.


## Step {{% param sectionnumber %}}.3: Import with a CLI command

Before Terraform 1.5, importing an existing resource into state required the `terraform import`
CLI command. Use the `$SUFFIX` variable you captured earlier as the import ID:

```bash
terraform import random_string.suffix "$SUFFIX"
```

```text
random_string.suffix: Importing from ID "k7m2px4n"...
random_string.suffix: Import prepared!
  Prepared random_string for import
random_string.suffix: Refreshing state... [id=k7m2px4n]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

Now run `terraform plan` to verify no changes are detected:

```bash
terraform plan
```

```text
No changes. Your infrastructure matches the configuration.
```

### Explanation

`terraform import <resource_address> <provider-specific-id>` reads the current state of the
existing resource from the provider and writes it into the Terraform state file. The resource
configuration in `.tf` files must already exist before importing — the command does **not**
generate configuration for you.

The `<provider-specific-id>` is provider-dependent. For `random_string` it is the string value
itself; for an AWS S3 bucket it would be the bucket name; for an Azure resource group it would be
the full resource ID.


## Step {{% param sectionnumber %}}.4: Import block (Terraform ≥ 1.5)

Terraform 1.5 introduced a declarative `import` block that integrates the import into a normal
plan/apply workflow and eliminates the need for a separate CLI step.

Remove the existing state entry first so we can demonstrate importing afresh:

```bash
terraform state rm random_string.suffix
```

Add the following `import` block to `main.tf`, replacing `<your-suffix>` with the value you
saved earlier (e.g. `k7m2px4n`):

```terraform
import {
  to = random_string.suffix
  id = "<your-suffix>"
}
```

Now run plan and apply:

```bash
terraform plan
terraform apply
```

Terraform imports the resource during the apply. Once the import is complete you can remove the
`import` block from `main.tf` — or leave it in place, as it becomes a no-op on subsequent applies
once the resource is in state.

### Explanation

The `import` block approach has several advantages over the CLI command:

* It is **reviewable** in a pull request like any other code change.
* It works inside CI/CD pipelines without extra shell scripting.
* Terraform 1.6+ can also **generate** the resource configuration automatically with
  `terraform plan -generate-config-out=generated.tf`, reducing manual effort when importing
  large numbers of resources.

{{% alert title="Note" color="secondary" %}}
The `import` block is idempotent. If the resource is already in state, the block is silently
skipped — it will not cause errors if left in the code.
{{% /alert %}}
