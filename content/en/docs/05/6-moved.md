---
title: "5.6. Moved Block"
weight: 56
sectionnumber: 5.6
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/advanced/moved
cd $LAB_ROOT/advanced/moved
```

Optional: Create empty files:

```bash
touch {main,versions}.tf
```


## Step {{% param sectionnumber %}}.1: Initial setup

Create a new file named `main.tf` with an intentionally short resource name that we will later
want to rename:

```terraform
resource "local_file" "tmp" {
  filename = "output.txt"
  content  = "hello from terraform"
}
```

Create a new file named `versions.tf` and add the following content:

```terraform
terraform {
  required_version = ">= 1.12.2"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "= 2.5.2"
    }
  }
}
```

Apply to create the resource in state:

```bash
terraform init
terraform apply
```


## Step {{% param sectionnumber %}}.2: Rename the resource – the wrong way

Rename `local_file.tmp` to `local_file.greeting` in `main.tf` **without** a `moved` block:

```terraform
resource "local_file" "greeting" {
  filename = "output.txt"
  content  = "hello from terraform"
}
```

Run `terraform plan`:

```bash
terraform plan
```

```text
Plan: 1 to add, 0 to change, 1 to destroy.
```

Terraform treats this as a **delete + create** because the old address no longer exists. In a real
environment this would delete and re-provision a running resource—potentially causing downtime.
Do **not** apply. Restore the original name before continuing.


## Step {{% param sectionnumber %}}.3: Rename safely with a `moved` block

Update `main.tf` to the new name **and** add a `moved` block that tells Terraform the old and new
addresses:

```terraform
resource "local_file" "greeting" {
  filename = "output.txt"
  content  = "hello from terraform"
}

moved {
  from = local_file.tmp
  to   = local_file.greeting
}
```

Run `terraform plan`:

```bash
terraform plan
```

```text
Terraform will perform the following actions:

  # local_file.tmp has moved to local_file.greeting
    resource "local_file" "greeting" {
        ...
    }

Plan: 0 to add, 0 to change, 0 to destroy.
```

No destroy/create cycle—Terraform simply updates the state record. Apply to confirm:

```bash
terraform apply
```

After the apply succeeds you can remove the `moved` block (or keep it as documentation of the
rename history).

### Explanation

The `moved` block (introduced in Terraform 1.1) records a renaming or refactoring operation
directly in the code. Its key properties:

* **Zero-downtime renames** – no destroy/create occurs; only the state entry is relocated.
* **Module moves** – can relocate resources across module boundaries:
  ```terraform
  moved {
    from = local_file.greeting
    to   = module.files.local_file.greeting
  }
  ```
* **Idempotent** – if the `from` address is not in state (e.g. already moved), the block is a
  no-op.
* **Reviewable** – the rename is explicit in code, visible in pull requests.

{{% alert title="Note" color="secondary" %}}
The `moved` block only relocates **state records**. It does not change the physical infrastructure.
Always run `terraform plan` after adding a `moved` block to confirm the plan shows zero
destroy/create operations before applying.
{{% /alert %}}


## Step {{% param sectionnumber %}}.4: Rename within a `for_each` resource

The `moved` block also supports renaming keys within a `for_each` resource. For example, to rename
the key `"dev"` to `"development"` without re-creating the resource:

```terraform
moved {
  from = local_file.configs["dev"]
  to   = local_file.configs["development"]
}
```

This pattern is useful when cleaning up naming conventions in an existing `for_each` map.
