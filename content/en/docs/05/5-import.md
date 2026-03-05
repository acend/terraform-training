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
touch {main,versions}.tf
```


## Step {{% param sectionnumber %}}.1: Create a resource outside of Terraform

To simulate a resource that already exists in the real world (e.g. provisioned manually or by
another tool), create a local file directly with the shell:

```bash
echo "created outside terraform" > existing.txt
```

This file is not yet tracked by any Terraform state.


## Step {{% param sectionnumber %}}.2: Declare the resource in code

Create a new file named `main.tf` and add the following content:

```terraform
resource "local_file" "existing" {
  filename = "existing.txt"
  content  = "created outside terraform"
}
```

Create a new file named `versions.tf` and add the following content:

```terraform
terraform {
  required_version = "= 1.12.2"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "= 2.5.2"
    }
  }
}
```

Run `terraform init`, then try to apply immediately:

```bash
terraform init
terraform apply
```

Terraform will show a diff and try to overwrite the file because it does not yet manage the
existing resource. Cancel with `no`.


## Step {{% param sectionnumber %}}.3: Import with a CLI command

Before Terraform 1.5, importing an existing resource into state required the `terraform import`
CLI command:

```bash
terraform import local_file.existing existing.txt
```

```text
local_file.existing: Importing from ID "existing.txt"...
local_file.existing: Import prepared!
  Prepared local_file for import
local_file.existing: Refreshing state... [id=...]

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
configuration in `.tf` files must already exist and must match what the provider returns, otherwise
a follow-up `apply` would still show a diff.

The `<provider-specific-id>` is provider-dependent. For `local_file` it is the file path; for an
AWS S3 bucket it would be the bucket name; for an Azure resource group it would be the full
resource ID.


## Step {{% param sectionnumber %}}.4: Import block (Terraform ≥ 1.5)

Terraform 1.5 introduced a declarative `import` block that integrates the import into a normal
plan/apply workflow and eliminates the need for a separate CLI step.

Remove the existing state entry first so we can demonstrate importing afresh:

```bash
terraform state rm local_file.existing
```

Add the following `import` block to `main.tf`:

```terraform
import {
  to = local_file.existing
  id = "existing.txt"
}
```

Now run plan and apply:

```bash
terraform plan
terraform apply
```

Terraform will import the resource during the apply and the `import` block is automatically
consumed—you can remove it from `main.tf` afterwards (or leave it; it becomes a no-op on
subsequent applies once the resource is in state).

### Explanation

The `import` block approach has several advantages over the CLI command:

* It is **reviewable** in a pull request like any other code change.
* It works inside CI/CD pipelines without extra shell scripting.
* Terraform 1.6+ can also **generate** the resource configuration automatically with
  `terraform plan -generate-config-out=generated.tf`, reducing manual effort when importing
  large numbers of resources.

{{% alert title="Note" color="secondary" %}}
The `import` block is idempotent. If the resource is already in state, the block is silently
skipped—it will not cause errors if left in the code.
{{% /alert %}}
